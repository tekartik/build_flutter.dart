/// Build flutter helper
library;

export 'src/build_flutter.dart'
    show
        buildPlatformCurrent,
        createProjectAndCheckoutFromGit,
        createProject,
        buildProject,
        runBuiltProject,
        platformExeDir,
        deleteDir,
        deleteFile,
        getBuildProjectAppFilename,
        getBuildProjectAppPath,
        getBuildProjectExePath,
        hasPlatformProject,
        buildHostSupportedPlatforms,
        getBuildHostSupportedPlatforms;
export 'src/build_flutter_common.dart';
export 'src/entry_point.dart'
    show
        flutterBuildSubCommandPlatform,
        flutterProjectEntryPoint,
        flutterProjectEntryPointCandidates;
export 'src/flutter_project.dart' show FlutterProject;
