import 'dart:io';

import 'package:xml/xml.dart';

/// Xml plist (apple property list) file helper.
///
/// Only the minimum needed to read/modify a top level dictionary is
/// implemented, which is enough for `.entitlements` and `Info.plist` files.
///
/// The existing formatting (indentation, doctype, other entries) is kept, only
/// the modified/added entries are touched.
class PlistFile {
  /// File path.
  final String path;

  XmlDocument? _document;
  var _modified = false;

  /// Constructor, [read] must be called before accessing the content.
  PlistFile(this.path);

  /// True if the file exists.
  bool get exists => File(path).existsSync();

  /// Xml document, [read] must have been called before.
  XmlDocument get document {
    var document = _document;
    if (document == null) {
      throw StateError('read() must be called first on $path');
    }
    return document;
  }

  /// True if the document was modified since the last [read]/[write].
  bool get modified => _modified;

  /// Read (or re-read) the file content.
  Future<void> read() async {
    _document = XmlDocument.parse(await File(path).readAsString());
    _modified = false;
  }

  /// Write the content back to the file.
  Future<void> write() async {
    await File(path).writeAsString(document.toXmlString());
    _modified = false;
  }

  /// Write the content back to the file only if it was [modified].
  ///
  /// Returns true if the file was written.
  Future<bool> writeIfModified() async {
    if (!_modified) {
      return false;
    }
    await write();
    return true;
  }

  /// Top level dictionary (`plist` > `dict`).
  XmlElement get rootDict {
    var dict = document.rootElement.getElement('dict');
    if (dict == null) {
      throw StateError('No top level <dict> found in $path');
    }
    return dict;
  }

  /// Top level dictionary keys, in order.
  List<String> get keys => rootDict.childElements
      .where((element) => element.localName == 'key')
      .map((element) => element.innerText.trim())
      .toList();

  /// Raw xml text of the value of [key], null if the key is not found.
  ///
  /// For example `<true/>` or `<string>value</string>`.
  String? getValueXml(String key) => _valueElement(key)?.toXmlString();

  /// Boolean value of [key], null if the key is not found or is not a boolean.
  bool? getBoolValue(String key) {
    switch (_valueElement(key)?.localName) {
      case 'true':
        return true;
      case 'false':
        return false;
    }
    return null;
  }

  /// Set the boolean value of [key], the entry is added if missing.
  ///
  /// Returns true if the document was changed.
  bool setBoolValue(String key, bool value) =>
      setValueElement(key, XmlElement.tag(value ? 'true' : 'false'));

  /// Set the raw value element of [key], the entry is added if missing.
  ///
  /// Returns true if the document was changed.
  bool setValueElement(String key, XmlElement valueElement) {
    var keyElement = _keyElement(key);
    if (keyElement == null) {
      _addEntry(key, valueElement);
    } else {
      var existing = _nextElement(keyElement);
      if (existing == null) {
        // Key without any value, add it right after.
        var children = rootDict.children;
        children.insert(children.indexOf(keyElement) + 1, valueElement);
      } else {
        if (existing.toXmlString() == valueElement.toXmlString()) {
          return false;
        }
        existing.replace(valueElement);
      }
    }
    _modified = true;
    return true;
  }

  /// Append a new key/value pair at the end of the top level dictionary,
  /// keeping the existing indentation.
  void _addEntry(String key, XmlElement valueElement) {
    var dict = rootDict;
    var indent = _indent(dict);
    var children = dict.children;
    // Keep the text before `</dict>` (typically a new line) as trailing.
    var trailing = (children.isNotEmpty && children.last is XmlText)
        ? children.removeLast()
        : XmlText('\n');
    children.addAll([
      XmlText('\n$indent'),
      XmlElement.tag('key', children: [XmlText(key)]),
      XmlText('\n$indent'),
      valueElement,
      trailing,
    ]);
  }

  /// Indentation used for the entries of [dict], a tab by default (which is
  /// what flutter/xcode generates).
  String _indent(XmlElement dict) {
    for (var node in dict.children) {
      if (node is XmlText) {
        var value = node.value;
        var index = value.lastIndexOf('\n');
        if (index >= 0 && index < value.length - 1) {
          return value.substring(index + 1);
        }
      }
    }
    return '\t';
  }

  /// `<key>` element of [key] in the top level dictionary.
  XmlElement? _keyElement(String key) => rootDict.childElements
      .where(
        (element) =>
            element.localName == 'key' && element.innerText.trim() == key,
      )
      .firstOrNull;

  /// Value element of [key] (the element following its `<key>` element).
  XmlElement? _valueElement(String key) {
    var keyElement = _keyElement(key);
    return keyElement == null ? null : _nextElement(keyElement);
  }

  /// Element following [element] in the top level dictionary.
  XmlElement? _nextElement(XmlElement element) {
    var found = false;
    for (var child in rootDict.childElements) {
      if (found) {
        return child;
      }
      if (identical(child, element)) {
        found = true;
      }
    }
    return null;
  }

  @override
  String toString() => 'PlistFile($path)';
}
