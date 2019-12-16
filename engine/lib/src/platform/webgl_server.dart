
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'gl_server.dart';

/// Implements [GlServer] on top of WebGL
/// 
/// Usage:
/// ```dart
/// var wgl = new WebGlServer(canvas.getContext3d());
/// wgl.initialise();
/// 
/// // Use GL
/// //...
/// 
/// // Destroy
/// wgl.destroy();
/// ```
class WebGlServer extends GlServer{

  WebGlServer(RenderingContext context): super(context);

  /// Prepares the the server for rendering.
  @override
  void initialise(){
    var ctx = context as RenderingContext;

    createShader = ctx.createShader;
    shaderSource = (Object shader, String src)=> ctx.shaderSource(shader, src);
    compileShader = (Object shader) => ctx.compileShader(shader);
    createProgram = ctx.createProgram;
    attachShader = (Object program, Object shader)=> ctx.attachShader(program, shader);
    linkProgram = (Object program) => ctx.linkProgram(program);
    useProgram = (Object program) => ctx.useProgram(program);
    getShaderParameter = (Object shader, int pname) => ctx.getShaderParameter(shader, pname);
    getShaderInfoLog = (Object shader) => ctx.getShaderInfoLog(shader);
    getProgramParameter = (Object program, int pname) => ctx.getProgramParameter(program, pname);
    getProgramInfoLog = (Object program) => ctx.getProgramInfoLog(program);
    enable = ctx.enable;
    clearColor = (Vector4 color) => ctx.clearColor(color.r, color.g, color.b, color.a);
    clear = ctx.clear;
    viewport = ctx.viewport;
    getAttribLocation = (Object program, String name) => ctx.getAttribLocation(program, name);
    getUniformLocation = (Object program, String name) => ctx.getUniformLocation(program, name);
    createBuffer = ctx.createBuffer;
    bindBuffer = (int target, Object buffer) => ctx.bindBuffer(target, buffer);
    bufferData = (int target, ByteBuffer data, int usage) => ctx.bufferData(target, data, usage);
    vertexAttribPointer = ctx.vertexAttribPointer;
    enableVertexAttribArray = ctx.enableVertexAttribArray;
    uniformMatrix4f = (Object location, bool transpose, Matrix4 data)
      => ctx.uniformMatrix4fv(location, transpose, data.storage);
    drawElements = ctx.drawElements;
  }

  /// Does nothing
  @override
  void destroy(){}

}