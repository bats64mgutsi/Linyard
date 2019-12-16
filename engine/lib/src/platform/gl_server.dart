
import 'package:vector_math/vector_math.dart';


// OpenGL Constants and Enums

const int GL_VERTEX_SHADER = 0x8B31;

const int GL_FRAGMENT_SHADER = 0x8B30;

const int GL_COMPILE_STATUS = 0x8B81;

const int GL_LINK_STATUS = 0x8B82;

const int GL_DEPTH_TEST = 0x0B71;

const int GL_COLOR_BUFFER_BIT = 0x00004000;

const int GL_TRIANGLES = 0x0004;

const int GL_STATIC_DRAW = 0x88E4;

const int GL_ARRAY_BUFFER = 0x8892;

const int GL_ELEMENT_ARRAY_BUFFER = 0x8893;

const int GL_FLOAT = 0x1406;

const int GL_UNSIGNED_SHORT = 0x1403;



typedef GlCreateShader = Object Function(int type);
typedef GlShaderSource = void Function(Object Shader, String src);
typedef GlCompileShader = void Function(Object shader);
typedef GlCreateProgram = Object Function();
typedef GlAttachShader = void Function(Object program, Object shader);
typedef GlLinkProgram = void Function(Object program);
typedef GlUseProgram = void Function(Object program);
typedef GlGetShaderParameter = Object Function(Object shader, int pname);
typedef GlGetShaderInfoLog = String Function(Object shader);
typedef GlGetProgramParameter = Object Function(Object program, int pname);
typedef GlGetProgramInfoLog = String Function(Object program);
typedef GlEnable = void Function(int cap);
typedef GlClearColor = void Function(Vector4 color);
typedef GlClear = void Function(int mask);
typedef GlViewport(int x, int y, int width, int height);
typedef GlGetAttribLocation = int Function(Object program, String name);
typedef GlGetUniformLocation = Object Function(Object program, String name);
typedef GlCreateBuffer = Object Function();
typedef GlBindBuffer = void Function(int target, Object buffer);
typedef GlBufferData = void Function(int target, dynamic data_OR_size, int usage);
typedef GlVertexAttribPointer = void Function(int index, int size, int type, bool normalised, int stride, int offset);
typedef GlEnableVertexAttribArray = void Function(int index);
typedef GlUniformMatrix4f = void Function(Object location, bool transpose, Matrix4 data);
typedef GlDrawElements(int mode, int count, int type, int offset);


/// Provides a common rendering interface for WebGL, Desktop GL,
/// and OpenGL ES.
/// 
/// All the methods should be initialised as the renderer may expect 
/// them to be not null. These are just the OpenGL functions the Linyard
/// GlRenderer uses
abstract class GlServer {

  final Object _context;
  GlServer(this._context);

  /// The underlying window opengl context as per windowing system
  Object get context => _context;

  /// Initialise the server for rendering
  /// 
  /// This is where dynamic libraries can be loaded and the gl methods
  /// intitialised
  void intialise();

  /// Release any Resources that may be used by the server
  /// 
  /// If dynamic libraries were loaded, they cane released here
  void destroy();
  

  GlCreateShader createShader;
  GlShaderSource shaderSource;
  GlCompileShader compileShader;
  GlCreateProgram createProgram;
  GlAttachShader attachShader;
  GlLinkProgram linkProgram;
  GlUseProgram useProgram;
  GlGetShaderParameter getShaderParameter;
  GlGetShaderInfoLog getShaderInfoLog;
  GlGetProgramParameter getProgramParameter;
  GlGetProgramInfoLog getProgramInfoLog;
  GlEnable enable;
  GlClearColor clearColor;
  GlClear clear;
  GlViewport viewport;
  GlGetAttribLocation getAttribLocation;
  GlGetUniformLocation getUniformLocation;
  GlCreateBuffer createBuffer;
  GlBindBuffer bindBuffer;
  GlBufferData bufferData;
  GlVertexAttribPointer vertexAttribPointer;
  GlEnableVertexAttribArray enableVertexAttribArray;
  GlUniformMatrix4f uniformMatrix4f;
  GlDrawElements drawElements;
}
