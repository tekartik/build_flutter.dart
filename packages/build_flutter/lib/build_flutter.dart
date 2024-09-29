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
        buildHostSupportedPlatforms,
        getBuildHostSupportedPlatforms;
export 'src/build_flutter_common.dart';
