import 'dart:io';

import 'package:io/io.dart';

/// This tool builds the linyard SDk to the top level build directory. The SDK
/// consists of:
/// 1. LICENCE.txt file
/// 2. AUTHORS.txt file
/// 3. bin folder with linyard executable
/// 4. examples folder
/// 5. README.txt for how to get started
/// 6. VERSION.txt file
/// 7. engine folder containing the linyard library
/// 8. docs folder containing html of the docs folder in the source code
///
/// Layout of sdk folder:
/// |__bin/
/// |____linyard.exe
/// |__LICENCE.txt
/// |__AUTHORS.txt
/// |__README.txt
/// |__VERSION.txt
/// |__examples/
/// |__engine/
/// |__docs/

/// The README file users who have downloaded the SDK should read
///
/// This file is specifically for the SDK and not the whole project
/// Therefore it is different from the README.md file of the project
final README_TXT = """
Thank you for downloading Linyard v$version

Here's a what you'll find in here:

bin/
  linyard        The Linyard executable

engine/          Contains the Linyard Engine library.

examples/        Example Linyard apps. Run them with the linyard executable
                 with: `linyard run` inside the folder containing the example.

docs/            Getting started guides and API documentation.

version          The version of the Linyard SDK(v$version). Linyard uses semantic
                 style versioning.
""";

void main() async {
  // Prepare to build
  print("Preparing to build...");
  var buildDir = Directory("../build/bin");
  if (!buildDir.existsSync()) await buildDir.create(recursive: true);

  // Copy the files

  print("Copying files...\n");
  copyFile("../LICENCE", "../build/LICENCE.txt", true);
  copyFile("../AUTHORS", "../build/AUTHORS.txt", true);
  File("../build/README.txt").writeAsStringSync(README_TXT);
  File("../build/VERSION.txt").writeAsStringSync(version);
  copyPath("../examples", "../build/examples");
  copyPath("../engine", "../build/engine");

  // Build the Linyard executable
  print("\nBuilding ../sdk/linyard.dart to executable ../build/bin/linyard.exe");
  final manager = new ProcessManager();
  try {
    var spawn = await manager.spawn("cmd", [
      "/c",
      "dart2native",
      "../sdk/linyard.dart",
      "-k",
      "exe",
      "-o",
      "../build/bin/linyard.exe"
    ]);

    var exitCode = await spawn.exitCode;
    if (exitCode != 0)
      print(
          "Error: failed to buld ../sdk/linyard.dart with error code $exitCode\n"
          "Ensure that the Dart SDK is in your PATH");
  } catch (e) {
    print("Error: ${e.toString()}");
  }
  sharedStdIn.terminate();

  //TODO: Parse the documentation to html

  print("Linyard SDK has been built to ../build folder");
}

/// Returns the contents of the ../version file
String get version => File("../version").readAsStringSync();

/// Copies file [src] to [dest]
///
/// If [ignorable] is false the application id force to exit if the operation
/// fails
void copyFile(String src, String dest, bool ignorable) {
  var srcFile = new File(src);
  var destFile = new File(dest);
  try {
    if (!destFile.existsSync()) destFile.createSync();
    srcFile.copySync(dest);
  } on Exception {
    print("Error: $src could not be copied to $dest");
    if (!ignorable) exit(-1);
  }
}
