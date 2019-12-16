/// This example demonstrates simple rendering with webgl

import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';
import 'package:linyard/linyard.dart';
import 'package:linyard/src/platform/webgl_server.dart';

Renderer renderer;
RenderingContext ctx;

void draw(num delta){
  int width = (window.innerWidth*.9).toInt();
  int height = (window.innerHeight*.9).toInt();
  ctx.canvas.width = width;
  ctx.canvas.height = height;
  renderer.viewport(width, height);
  renderer.draw();
  window.animationFrame.then(draw);
}
 
void main() {

  // Get the view where the image will be shown
  CanvasElement canvas = document.getElementById("view");
  var gl = ctx = canvas.getContext3d();
  if(gl == null){
    showError("Unfortunately your browser does not support WebGL");
    return; 
  }

  // Initialise a web renderer
  renderer = Renderer(WebGlServer(gl)..initialise(), showError);
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
        Colors.turquoise.storage+
        Colors.red.storage+
        Colors.green.storage
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