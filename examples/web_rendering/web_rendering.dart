/// This example demonstrates simple rendering with webgl

import 'dart:html';
import 'dart:typed_data';

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

  // Initialise a renderer
  renderer = Renderer(
    gl: gl,
    onError: showError,
  );
  renderer.initialise();
  renderer.clearColor = Vector4.random();

  // Add a triangle to be drawn
  renderer.add(
    Renderable(
      vertices: Float32List.fromList([
        -0.5, 0.5, 0.0,
        -0.5, -0.5, 0.0,
        0.5, -0.5, 0.0,
      ],),

      indices: Int32List.fromList([
        1, 2, 3
      ]),

      colors: Float32List.fromList(
        Colors.turquoise.storage+Colors.red.storage+Colors.green.storage
      ),

      //Add a bit of skewness
      transform: Matrix4.rotationZ(0.13),
    )
  );

  // Start drawing
  window.animationFrame.then(draw);
}


String errorMessages = "";
void showError(Object error){
  errorMessages += "$error<br />";
  document.getElementById("errorDiv").innerHtml = errorMessages;
}