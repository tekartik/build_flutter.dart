/// Build flutter helper
library tekartik_build_flutter;

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
        getBuildProjectAppFilename;
export 'src/build_flutter_common.dart';
