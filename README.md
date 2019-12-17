# Linyard 2D

Linyard is a 2D game engine that aims to be simple, fast and extensible. In Linyard there are no
managers or central classes, almost everything is treated as data.

## Running the examples

You must have the Dart SDK installed. Its bin folder shoudld be in your PATH
variable. Use the [run.dart](tools/run.dart) script to run the examples or Linyard apps of your own. Be sure to first run ```pub get``` on all folders containing a
```pubspec.yaml``` file.

```shell
C:\Linyard2D\tools> dart run.dart [mainScript] [target]
```

1. mainScript must contain a top level main function
2. target should be **onWeb**, **onDesktop**, or **onAndroid**

As an example try runnning the [web_rendering](examples/web_rendering/web_rendering.dart) example:

```shell
C:\Linyard2D\tools> dart run.dart ../examples/web_rendering/web_rendering.dart onWeb
```

Watch the output to get the local url of your app. You can continue editing your source files while your app is running, the [run.dart](tools/run.dart) script will compile it automatically on save. You just need have to refresh your browser after every save.
