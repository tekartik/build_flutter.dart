import '../app_build_menu.dart';

var tkFlutterDeviceIdVar = 'TK_FLUTTER_DEVICE_ID'.kvFromVar();
void menuFdmContent() {
  item('select devices', () async {
    var devices = await getFlutterDevices();
    await showMenu(() {
      for (var device in devices) {
        item('${device.name.v} (${device.id.v})', () async {
          await tkFlutterDeviceIdVar.set(device.id.v);
          print('Selected device: ${device.name} (${device.id})');
          await popMenu();
        });
      }
    });
  });
  item('Current selected device', () async {
    var deviceId = tkFlutterDeviceIdVar.value;
    if (deviceId != null) {
      print('Selected device id: $deviceId');
    } else {
      print('No device selected');
    }
  });
  item('clear selected device', () async {
    await tkFlutterDeviceIdVar.delete();
    print('Selected device cleared');
  });
}
