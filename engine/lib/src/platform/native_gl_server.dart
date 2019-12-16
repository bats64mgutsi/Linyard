
import 'dart:ffi';
import 'dart:typed_data';

import 'package:opengl/opengl.dart';
import 'package:opengl/src/c_utils.dart';
import 'package:opengl/src/opengl_init.dart';
import 'package:ffi/ffi.dart';
import 'package:vector_math/vector_math.dart';

import 'gl_server.dart';

/// Implements [GlServer] on top of OpenGL 4.6 for Windows and Linux rendering
class NativeGLServer extends GlServer {

  NativeGLServer(Object context): super(context);

  /// Initialises the server for rendering
  /// 
  /// The OpenGl dynamic libraries will be loaded and binded with [initOpenGL]
  /// which throws an exception if the libs cannot be found. 
  /// Prior to calling this method the given opengl context should be current
  @override
  void initialise(){
    initOpenGL();

    createShader = glCreateShader;
    compileShader = (Object shader) => glCompileShader(shader);
    createProgram = glCreateProgram;
    attachShader = (Object program, Object shader) => glAttachShader(program, shader);
    linkProgram = (Object program) => glLinkProgram(program);
    useProgram = (Object program) => glUseProgram(program);
    enable = glEnable;
    clearColor = (Vector4 color) => glClearColor(color.r, color.g, color.b, color.a);
    clear = glClear;
    viewport = glViewport;
    bindBuffer = (int target, Object buffer) => glBindBuffer(target, buffer);
    vertexAttribPointer = (int index, int size, int type, bool normalized, int stride, int offset)
      => glVertexAttribPointer(index, size, type, normalized ? 1:0, stride, offset);
    enableVertexAttribArray = glEnableVertexAttribArray;
    drawElements = (int mode, int count, int type, int unusedOffset)
      => glDrawElements(mode, count, type, nullptr);

    uniformMatrix4f = (Object location, bool transpose, Matrix4 data) {
      var buffer = allocate<Uint8>(count: data.storage.buffer.lengthInBytes);
      copy(data.storage.buffer, buffer);
      glUniformMatrix4fv(location, 1, transpose ? 1:0, buffer); //Gles incompatible
      free(buffer);
    };

    bufferData = (int target, ByteBuffer data, int usage) {
      var buffer = allocate<Uint8>(count: data.lengthInBytes);
      copy(data, buffer);
      glBufferData(target, data.lengthInBytes, buffer, usage);
      free(buffer);
    };

    createBuffer = () {
      var temp = allocate<Int64>();
      glCreateBuffers(1, temp);
      var bufferName = temp.value;
      free(temp);
      return bufferName;
    };

    shaderSource = (Object shader, String src) {
      var str = CString.fromUtf8(src);
      glShaderSource(shader, 1, str, nullptr);
      free(str);
    };

    getAttribLocation = (Object program, String name) {
      var str = CString.fromUtf8(name);
      var location = glGetAttribLocation(program, str);
      free(str);
      return location;
    };

    getUniformLocation = (Object program, String name) {
      var str = CString.fromUtf8(name);
      var location = glGetUniformLocation(program, str);
      free(str);
      return location;      
    };

    getShaderParameter = (Object shader, int pname) {
      var temp = allocate<Int64>();
      glGetShaderiv(shader, pname, temp);
      var status = temp.value;
      free(temp);
      return status;
    };

    getShaderInfoLog = (Object shader) {
      var infoLogLen = getShaderParameter(shader, GL_INFO_LOG_LENGTH) as int;
      if(infoLogLen > 1){
        var temp = allocate<Uint8>(count: infoLogLen);
        glGetShaderInfoLog(shader, infoLogLen, nullptr, temp);
        var infoLog = CString.fromPointer(temp);
        free(temp);
        return infoLog.toUtf8();
      }
      return "";
    };

    
    getProgramParameter = (Object program, int pname) {
      var temp = allocate<Int64>();
      glGetProgramiv(program, pname, temp);
      var status = temp.value;
      free(temp);
      return status;        
    };

    getProgramInfoLog = (Object program) {
      var infoLogLen = getProgramParameter(program, GL_INFO_LOG_LENGTH) as int;
      if(infoLogLen > 1){
        var temp = allocate<Uint8>(count: infoLogLen);
        glGetProgramInfoLog(program, infoLogLen, nullptr, temp);
        var infoLog = CString.fromPointer(temp);
        free(temp);
        return infoLog.toUtf8();        
      }
      return "";
    };

  }


  /// Releases the OpenGL dynamic library
  @override
  void destroy(){
    // No need to implement as the libraries will be released when the application exits
  }


  /// Copies contents of [src] to native storage [dest]
  void copy(ByteBuffer src, Pointer<Uint8> dest){
    var listData = src.asUint8List();
    for(int index = 0; index <= src.lengthInBytes; index++)
      dest.elementAt(index).value = listData[index]; 
  }
}