/// This example demonstrates simple rendering with webgl

import 'dart:html';

import 'package:vector_math/vector_math.dart';
import 'package:linyard/linyard.dart';

Renderer renderer;

void draw(num delta){
  renderer.draw();
  window.animationFrame.then(draw);
}
 
void main() { 

  // Get the view where the image will be shown
  CanvasElement canvas = document.getElementById("view");
  var gl = canvas.getContext3d();
  if(gl == null){
    showError("Unfortunately your browser does not support OpenGL");
    return; 
  }

  renderer = Renderer(
    gl: gl,
    onError: showError,
  );

  renderer.initialise();
  renderer.clearColor = Vector4.random();
  window.animationFrame.then(draw);
}


String errorMessages = "";
void showError(Object error){
  errorMessages += "$error<br />";
  document.getElementById("errorDiv").innerHtml = errorMessages;
}