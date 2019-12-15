
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

/// Graphics libraries that can be used by any instance of [Renderer]
enum GraphicsLib{
  VULKAN,
  GL,
  GLES,
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

  factory Renderer({RenderingContext gl, ErrorCallback onError}){
    return GlesRenderer(
      gl: gl,
      onError: onError,
    );
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
  Buffer vertexVbo, colorVbo, indexVbo;
  int vertexCount;
}

/// A Gles2 renderer. This renderer should work on web, mobile and desktop
class GlesRenderer implements Renderer {

  final RenderingContext gl;
  final ErrorCallback onError;

  GlesRenderer({this.gl, this.onError});

  final List<_GlesLoadedRenderable> visible = List();
  final List<_GlesLoadedRenderable> hidden  = List();

  // Vertex attributes and shader uniforms
  int positionAttribute;
  int colorAttribute;
  UniformLocation transfromUniform;

  /// The graphics library used by this renderer, which is OpenGLEs
  GraphicsLib get graphicsLib => GraphicsLib.GLES;

  /// The background color of the rendering surface in ARGB format.
  set clearColor(Vector4 color) => gl.clearColor(color.r, color.g, color.b, color.a);

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

    Shader vs = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vs, vShader);
    gl.compileShader(vs);

    Shader fs = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fs, fShader);
    gl.compileShader(fs);

    Program program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    gl.useProgram(program);

    // Check if shaders were compiled properly
    
    if (!gl.getShaderParameter(vs, WebGL.COMPILE_STATUS)) { 
      onError(gl.getShaderInfoLog(vs));
    }
  
    if (!gl.getShaderParameter(fs, WebGL.COMPILE_STATUS)) { 
      onError(gl.getShaderInfoLog(fs));
    }
  
    if (!gl.getProgramParameter(program, WebGL.LINK_STATUS)) { 
      onError(gl.getProgramInfoLog(program));
    }

    gl.enable(WebGL.DEPTH_TEST);
    positionAttribute = gl.getAttribLocation(program, "position");
    colorAttribute = gl.getAttribLocation(program, "color");
    transfromUniform = gl.getUniformLocation(program, "transform");
  }

  /// Releases all rendering resources.
  /// 
  /// After this method is called the renderer is no longer usable
  @override
  void destroy(){

    //TODO: Implement
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
    gl.bindBuffer(WebGL.ARRAY_BUFFER, renderable.vertexVbo);
    gl.bufferData(WebGL.ARRAY_BUFFER, def.vertices, WebGL.STATIC_DRAW);

    // Load indices
    renderable.indexVbo = gl.createBuffer();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, renderable.indexVbo);
    gl.bufferData(WebGL.ELEMENT_ARRAY_BUFFER, def.indices, WebGL.STATIC_DRAW);

    // Load the colors, defaults to white
    var colors = (def.colors != null && def.colors.length >= def.indices.length*4 ) 
      ? def.colors: Float32List.fromList(List.filled(def.vertices.length*4, 0));

    renderable.colorVbo = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, renderable.colorVbo);
    gl.bufferData(WebGL.ARRAY_BUFFER, colors, WebGL.STATIC_DRAW);

    visible.add(renderable);
    return renderable;
  }

  /// Remove [renderable] as an object to be drawn.
  /// 
  /// The corresponding vbos will be destroyed. This [renderable] can be
  /// added back again.
  @override
  bool remove(LoadedRenderable renderable){

    //TODO: implement
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

  /// Draw all the visible renderabless
  void draw(){
    gl.clear(WebGL.COLOR_BUFFER_BIT);

    for( var renderable in visible ){

      // Point position to vertices
      gl.bindBuffer(WebGL.ARRAY_BUFFER, renderable.vertexVbo);
      gl.vertexAttribPointer(positionAttribute, 3, WebGL.FLOAT, false, 0, 0);
      gl.enableVertexAttribArray(positionAttribute);

      // Point color to colors
      gl.bindBuffer(WebGL.ARRAY_BUFFER, renderable.colorVbo);
      gl.vertexAttribPointer(colorAttribute, 4, WebGL.FLOAT, false, 0, 0);
      gl.enableVertexAttribArray(colorAttribute);

      // Set transform uniform
      gl.uniformMatrix4fv(transfromUniform, false, renderable.transform.storage);

      // Bind indices vbo. This is where drawElemnts will read indices from
      gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, renderable.indexVbo);

      // Draw
      gl.drawElements(WebGL.TRIANGLES, renderable.vertexCount, WebGL.UNSIGNED_SHORT, 0);
    }
  }


}