import 'dart:async';
import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

/// This tool enables for quick running of Linyard applications on web, PC, and Android.
/// The application will be built and ran on the target platform. A bin folder will be
/// created on the target folder if it does not exist yet. This is where the build will
/// be placed and ran from.
/// usage:
///   run.dart [mainFile] [target]
/// >mainFile should contain the top level main function
/// >target can be onWeb, onDesktop, or onAndroid
/// on Desktop will run the application on the current machine- Windows, Linux, Mac

void main(List<String> args) async {
  if (args.length < 2) error("At least two argumenta are required");

  File mainScript = File(args[0]);
  var target = args[1];

  if (!await mainScript.exists()) error("File ${args[0]} does not exist");

  // The bin folder resides under the folder holding mainScript. The project will be placed
  // under the bin folder. The name of the main script is the name of the project but
  // without the .dart
  var projectName = basename(mainScript.path).replaceAll(".dart", "");
  Directory bin =
      Directory(mainScript.parent.parent.path + "/bin/$projectName");
  if (await bin.exists()) {
    clearFolder(bin);
  } else {
    bin.createSync(recursive: true);
  }

  if (target == "onWeb")
    runWeb(mainScript.parent, mainScript, bin);
  else if (target == "onDesktop")
    runDesktop(mainScript.parent, mainScript, bin);
  else if (target == "onAndroid")
    runAndroid(mainScript.parent, mainScript, bin);
  else
    error("$target is not a target- use onWeb, onDesktop, or onAndroid");
}

/// Exit with the given error mesage
void error(String msg) {
  print("Err: $msg");
  exit(1);
}

/// Clears the contents of the given directory
void clearFolder(Directory directory) {
  for (var file in directory.listSync()) file.delete(recursive: true);
}

/// Builds for web
///
/// The contents under the web folder are all copied to [bin]. The [mainScript] is compiled
/// to main.js into the [bin] folder as well. Once the initial build is done the [source]
/// will be monitored for any file modification changes. Shall changes happen the project
/// will be rebuilt, the user will have to reload the web page.
void runWeb(Directory source, File mainScript, Directory bin) async {
  copyPathSync("../web", bin.path);
  print(
      "...Now compiling ${mainScript.path}, dart2js should be in your PATH variable");
  final manager = new ProcessManager(isWindows: true);

  var build = () async {
    print("Building ${mainScript.path}");
    try {
      Process spawn;
      if (Platform.isWindows) {
        spawn = await manager.spawn("cmd", [
          "/c",
          "dart2js",
          "-o",
          "${bin.path}/main.js",
          "${mainScript.path}"
        ]);
      } else {
        spawn = await manager.spawn(
            "dart2js", ["-o", "${bin.path}/main.js", "${mainScript.path}"]);
      }

      await spawn.exitCode;
    } on Error {
      print("bad state...");
    }
  };

  // Initial build
  await build();

  // Everytime the source dir changes we compile accordingly
  var watcher = Watcher(source.path, pollingDelay: Duration(seconds: 2));
  watcher.events.listen((WatchEvent e) {
    if (e.type == ChangeType.MODIFY) build();
  });

  // Serve the contents of bin
  HttpServer.bind(InternetAddress.anyIPv4, 0).then((server) {
    server.listen((req) {
      // Only GET requests are served
      if (req.method == "GET") {
        String filePath = bin.path + req.uri.path;
        if (filePath.endsWith("/"))
          //index file
          filePath += "main.html";
        print("Http: Object $filePath requested");
        File file = File(filePath);

        if (file.existsSync()) {
          if (filePath.endsWith(".html"))
            req.response.headers
                .add(HttpHeaders.contentTypeHeader, "text/html");
          else if (filePath.endsWith(".js"))
            req.response.headers
                .add(HttpHeaders.contentTypeHeader, "text/javascript");

          file.openRead().pipe(req.response);
        } else
          req.response.statusCode = HttpStatus.notFound;
      } else {
        req.response.statusCode = HttpStatus.notFound;
        req.response.close();
      }
    }, onError: (err) {
      error(err);
    });

    print("Access your app at: http://localhost:${server.port}\n");
  });
}

/// Builds for Desktop
void runDesktop(Directory source, File mainScript, Directory bin) {}

/// Builds for Android
void runAndroid(Directory source, File mainScript, Directory bin) {}
