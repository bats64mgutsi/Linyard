/// This example demonstrates simple rendering with webgl

import 'dart:html';

import 'package:linyard/linyard.dart';

Renderer renderer;

void draw(num delta){
  renderer.draw();
  window.animationFrame.then(draw);
}

void main() {

  // Get the view where the image will be shown
  CanvasElement canvas = Document().getElementById("view");
  var gl = canvas.getContext3d();
  if(gl == null){
    showError("Unfortunately your browser does not support OpenGL");
    return;
  }

  renderer = GlesRenderer(
    gl: gl,
    onError: showError,
  );

  renderer.initialise();
  window.animationFrame.then(draw);
}



String errorMessages = "";
void showError(Object error){
  errorMessages += "$error<br />";
  Document().getElementById("errorDiv").innerHtml = errorMessages;
}