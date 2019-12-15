
part of linyard;

/// The vertex and fragment shader to be used by a renderable.
/// 
/// The shaders must be given in source form. The shaders must be 
/// suitable for the used [Renderer]. For using specific
/// shaders for a certain graphics library see [ContextShaderProgram]
class ShaderProgram {

  /// The vertex shader
  final String vShader;
  
  /// The fragment shader
  final String fShader;

  ShaderProgram({this.vShader, this.fShader});

  /// Any subclasses of this class can override this to prepare themselves for use by [renderer]
  /// 
  /// The returned [ShaderProgram] is the one to be used
  ShaderProgram prepare(Renderer renderer) => this;
}


/// Selects the right shader to be used based on the graphics library the used [Renderer] uses
class ContextShaderProgram extends ShaderProgram {

  // Mesktop opengl
  final ShaderProgram gl;

  // Mobile and webgl
  final ShaderProgram gles;

  // The vulkan shader program is this object itself

  ContextShaderProgram({ShaderProgram vulkan, this.gl, this.gles}): 
  super(
    vShader: vulkan.vShader,
    fShader: vulkan.fShader,
  );

  /// Returns the appropriate shader based on the [GraphicsLib] used by [renderer]
  ShaderProgram prepare(Renderer renderer) {
    if(renderer.graphicsLib == GraphicsLib.VULKAN)
      return this;
    else if(renderer.graphicsLib == GraphicsLib.GL)
      return gl;
    else
      return gles;
  }
  
}


/// Describes an object that can be drawn on screen from vertices.
/// 
/// This class may be extended to add renderer specific definitions
/// This class is not meant for storage by renderers as it is just
/// a definition.
class Renderable {

  final ShaderProgram shaderProgram;
  final Float32List   vertices;     // vec3
  final Int32List     indices;
  final Float32List   colors;       // vec4
  final Matrix4       transform;
  final Texture       texture;
  final Float32List   texCoords;

  Renderable({this.shaderProgram, this.vertices, this.indices, this.colors, this.transform, this.texture, this.texCoords});
}

/// A texture
class Texture{}

/// Graphics libraries that can be used by instances of [Renderer]
enum GraphicsLib{
  VULKAN,
  GL,
  GLES,
}

/// Types of environments the application can run on
enum Environment {
  WEB,
  MOBILE,
  DESKTOP
}

/// A [Renderer] consumes [Renderables] and draws them to whatever surface it renders to.
abstract class Renderer{

  /// The graphics library used by this renderer
  GraphicsLib get graphicsLib;

  /// Initialise resources and be ready for consuming renderables
  void initialise();

  /// Release all resources and be ready for destruction.
  /// 
  /// It is assumed that after calling this method this renderer is no longer usable.
  void destroy();

  /// Set the background color of the drawing surface to [color]
  set clearColor(Vector4 color);

  /// Add a new [Renderable] to be drawn
  LoadedRenderable add(Renderable def);

  /// Stop drawing [renderable] and remove it. 
  /// 
  /// Returns true if [renderable] was removed
  bool remove(LoadedRenderable renderable);

  /// Pause the rendering of [renderable]
  void hide(LoadedRenderable renderable);

  /// Resume the rendering of [renderable]
  void show(LoadedRenderable renderable);

  /// Draw all the visible renderables
  void draw();

  /// Returns a renderer suitable for the given environment
  /// 
  /// If the environment is [Environment.WEB] then [webGLContext] must be the 3d context
  /// of the canvas where the image will be shown.
  factory Renderer(Environment env, {ErrorCallback onError, dynamic webGLContext}){
    
    if(env == Environment.WEB ){
      return _GlesRenderer(
        gl: _WebGLServer(webGLContext),
        onError: onError,
      );

    } else if(env == Environment.MOBILE){
      // Flutter Gles renderer
      //TODO(Batandwa): Implement
      return null;

    } else{
      // Desktop Gles renderer
      //TODO(Batandwa): Implement
      return null;

    }
  }

}

/// Represents a [Renderable] that has been loaded to a [Renderer]
/// 
/// It is safe to change or modify [transform] in rendering loop
class LoadedRenderable {
  Matrix4 transform;
}


/// An error callback
typedef void ErrorCallback(Object error);





/**
 *    GLES Rendering
 */

/// A Loaded [Renderable] for the GlesRenderer
class _GlesLoadedRenderable extends LoadedRenderable {
  Object vertexVbo, colorVbo, indexVbo;
  int vertexCount;
}

/// A Gles2 renderer that renders on the given [_GlesServer]
class _GlesRenderer implements Renderer {

  final _GlesServer gl;
  final ErrorCallback onError;

  _GlesRenderer({this.gl, this.onError});

  final List<_GlesLoadedRenderable> visible = List();
  final List<_GlesLoadedRenderable> hidden  = List();

  // Vertex attributes and shader uniforms
  int positionAttribute;
  int colorAttribute;
  Object transfromUniform;

  /// The graphics library used by this renderer, which is OpenGLEs
  GraphicsLib get graphicsLib => GraphicsLib.GLES;

  /// The background color of the rendering surface in ARGB format.
  set clearColor(Vector4 color) => gl.clearColor(color);

  /// Call this to let the renderer know the size of the viewport the image will be shown
  void viewport(int width, int height) => gl.viewport(0, 0, width, height);

  /// Initialise a rendering surface. [Renderable] objects should be added after 
  /// this method is called.
  @override
  void initialise() {

    // Compile and link the shaders
    String vShader = """
    attribute vec3 position;
    attribute vec4 color;
    uniform mat4 transform;

    varying vec4 vColor;
    void main(){
      gl_Position = vec4(position, 1.0)*transform;
      vColor = color;
    }
    """;

    String fShader = """
    precision mediump float;
    varying vec4 vColor;

    void main(){
      gl_FragColor = vColor;
    }
    """;

    var vs = gl.createShader(_GlesServer.VERTEX_SHADER);
    gl.shaderSource(vs, vShader);
    gl.compileShader(vs);

    var fs = gl.createShader(_GlesServer.FRAGMENT_SHADER);
    gl.shaderSource(fs, fShader);
    gl.compileShader(fs);

    var program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    gl.useProgram(program);

    // Check if shaders were compiled properly
    
    if (!gl.getShaderParameter(vs, _GlesServer.COMPILE_STATUS)) { 
      onError(gl.getShaderInfoLog(vs));
    }
  
    if (!gl.getShaderParameter(fs, _GlesServer.COMPILE_STATUS)) { 
      onError(gl.getShaderInfoLog(fs));
    }
  
    if (!gl.getProgramParameter(program, _GlesServer.LINK_STATUS)) { 
      onError(gl.getProgramInfoLog(program));
    }

    gl.enable(_GlesServer.DEPTH_TEST);
    positionAttribute = gl.getAttribLocation(program, "position");
    colorAttribute = gl.getAttribLocation(program, "color");
    transfromUniform = gl.getUniformLocation(program, "transform");
  }

  /// Releases all rendering resources.
  /// 
  /// After this method is called the renderer is no longer usable
  @override
  void destroy(){

    //TODO(Batandwa): Implement
  }

  /// Adds [renderable] to the list of renderables.
  /// 
  /// Initially the [Renderable] is visible. To hide it call [hide].
  /// The corresponding vbo objects will be created and filled with
  /// [renderable]'s data. Therefore this method should only be called 
  /// after [initialise].
  /// [def.vertices] and [def.indices] should not be null
  @override
  LoadedRenderable add(Renderable def){
    if(def.vertices == null || (def.vertices.length%3 != 0)){
      onError("GlesRenderer: A renderable's vertex array length should be a multiple of three"
      " since a vertex has three components");
      return null;
    }

    if(def.indices == null){
      onError("GlesRenderer: Indices must be given");
      return null;
    }

    var renderable = _GlesLoadedRenderable()..transform = def.transform == null ? Matrix3.identity(): def.transform;
    renderable.vertexCount = def.indices.length;

    // Load vertices
    renderable.vertexVbo = gl.createBuffer();
    gl.bindBuffer(_GlesServer.ARRAY_BUFFER, renderable.vertexVbo);
    gl.bufferData(_GlesServer.ARRAY_BUFFER, def.vertices, _GlesServer.STATIC_DRAW);

    // Load indices
    renderable.indexVbo = gl.createBuffer();
    gl.bindBuffer(_GlesServer.ELEMENT_ARRAY_BUFFER, renderable.indexVbo);
    gl.bufferData(_GlesServer.ELEMENT_ARRAY_BUFFER, def.indices, _GlesServer.STATIC_DRAW);

    // Load the colors, defaults to white
    var colors = (def.colors != null && def.colors.length >= def.indices.length*4 ) 
      ? def.colors: Float32List.fromList(List.filled(def.vertices.length*4, 0));

    renderable.colorVbo = gl.createBuffer();
    gl.bindBuffer(_GlesServer.ARRAY_BUFFER, renderable.colorVbo);
    gl.bufferData(_GlesServer.ARRAY_BUFFER, colors, _GlesServer.STATIC_DRAW);

    visible.add(renderable);
    return renderable;
  }

  /// Remove [renderable] as an object to be drawn.
  /// 
  /// The corresponding vbos will be destroyed. This [renderable] can be
  /// added back again.
  @override
  bool remove(LoadedRenderable renderable){

    //TODO(Batandwa): implement
    return true;
  }

  /// Pause the rendering of [renderable]
  void hide(LoadedRenderable renderable){
    if(visible.remove(renderable))
      hidden.add(renderable);
  }

  /// Resume the rendering of [renderable]
  void show(LoadedRenderable renderable){
    if(hidden.remove(renderable))
      visible.add(renderable);
  }

  /// Draw all the visible renderables
  void draw(){
    gl.clear(_GlesServer.COLOR_BUFFER_BIT);

    for( var renderable in visible ){

      // Point position to vertices
      gl.bindBuffer(_GlesServer.ARRAY_BUFFER, renderable.vertexVbo);
      gl.vertexAttribPointer(positionAttribute, 3, _GlesServer.FLOAT, false, 0, 0);
      gl.enableVertexAttribArray(positionAttribute);

      // Point color to colors
      gl.bindBuffer(_GlesServer.ARRAY_BUFFER, renderable.colorVbo);
      gl.vertexAttribPointer(colorAttribute, 4, _GlesServer.FLOAT, false, 0, 0);
      gl.enableVertexAttribArray(colorAttribute);

      // Set transform uniform
      gl.uniformMatrix4f(transfromUniform, false, renderable.transform);

      // Bind indices vbo. This is where drawElemnts will read indices from
      gl.bindBuffer(_GlesServer.ELEMENT_ARRAY_BUFFER, renderable.indexVbo);

      // Draw
      gl.drawElements(_GlesServer.TRIANGLES, renderable.vertexCount, _GlesServer.UNSIGNED_SHORT, 0);
    }
  }


}


/// An OpenGLES 2 server
abstract class _GlesServer {

  // Gles enums

  static const int VERTEX_SHADER = 0x8B31;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int COMPILE_STATUS = 0x8B81;

  static const int LINK_STATUS = 0x8B82;

  static const int DEPTH_TEST = 0x0B71;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int TRIANGLES = 0x0004;

  static const int STATIC_DRAW = 0x88E4;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int FLOAT = 0x1406;

  static const int UNSIGNED_SHORT = 0x1403;


  // Gles calls

  Object createShader(int type);
  void   shaderSource(Object shader, String src);
  void   compileShader(Object shader);
  Object createProgram();
  void   attachShader(Object program, Object shader);
  void   linkProgram(Object program);
  void   useProgram(Object program);
  Object getShaderParameter(Object shader, int pname);
  String getShaderInfoLog(Object shader);
  Object getProgramParameter(Object program, int pname);
  String getProgramInfoLog(Object program);
  void   enable(int cap);
  void   clearColor(Vector4 color);
  void   clear(int mask);
  void   viewport(int x, int y, int width, int height);
  int    getAttribLocation(Object program, String name);
  Object getUniformLocation(Object program, String name);
  Object createBuffer();
  void   bindBuffer(int target, Object buffer);
  void   bufferData(int target, dynamic data_OR_size, int usage);
  void   vertexAttribPointer(int index, int size, int type, bool normalised, int stride, int offset);
  void   enableVertexAttribArray(int index);
  void   uniformMatrix4f(Object location, bool transpose, Matrix4 data);
  void   drawElements(int mode, int count, int type, int offset);

  //TODO(Batandwa): Enable trowing and catching gles context on non web servers for async safe rendering
}


/// WebGL [_GlesServer] using dart:web_gl
/// 
/// [_context] should be the 3d context of the canvas the resulting image will
/// be shown.
class _WebGLServer implements _GlesServer {

  final dynamic _context;
  _WebGLServer(this._context);  

  @override
  void createShader(int type) => _context.createShader(type);

  @override
  void shaderSource(Object shader, String src) => _context.shaderSource(shader, src);

  @override
  void compileShader(Object shader) => _context.compileShader(shader);

  @override
  Object createProgram() => _context.createProgram();

  @override
  void attachShader(Object program, Object shader) => _context.attachShader(program, shader);

  @override
  void linkProgram(Object program) => _context.linkProgram(program);

  @override
  void useProgram(Object program) => _context.useProgram(program);

  @override
  Object getShaderParameter(Object shader, int pname) => _context.getShaderParameter(shader, pname);

  @override
  String getShaderInfoLog(Object shader) => _context.getShaderInfoLog(shader);

  @override
  Object getProgramParameter(Object program, int pname) => _context.getProgramParameter(program, pname);

  @override
  String getProgramInfoLog(Object program) => _context.getProgramInfoLog(program);

  @override
  void enable(int cap) => _context.enable(cap);

  @override
  void clearColor(Vector4 color) => _context.clearColor(color.r, color.g, color.b, color.a);

  @override
  void clear(int mask) => _context.clear(mask);

  @override
  void viewport(int x, int y, int width, int height) => _context.viewport(x, y, width, height);

  @override
  int getAttribLocation(Object program, String name) => _context.getAttribLocation(program, name);

  @override
  Object getUniformLocation(Object program, String name) => _context.getUniformLocation(program, name);

  @override
  Object createBuffer() => _context.createBuffer();

  @override
  void bindBuffer(int target, Object buffer) => _context.bindBuffer(target, buffer);

  @override
  void bufferData(int target, data_OR_size, int usage) => _context.bufferData(target, data_OR_size, usage);

  @override
  void vertexAttribPointer(int index, int size, int type, bool normalised, int stride, int offset)
    => _context.vertexAttribPointer(index, size, type, normalised, stride, offset);

  @override
  void enableVertexAttribArray(int index) => _context.enableVertexAttribArray(index);

  @override
  void uniformMatrix4f(Object location, bool transpose, Matrix4 data)
    => _context.uniformMatrix4fv(location, transpose, data.storage);

  @override
  void drawElements(int mode, int count, int type, int offset) => _context.drawElements(mode, count, type, offset);

}