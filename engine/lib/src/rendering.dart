
part of linyard;

/// The vertex and fragment shader to be used by a renderable. The shaders must be given
/// in source form. The shaders must be suitable for the used [Renderer]. For using specific
/// shaders for a certain graphics library see [ContextShaders]
class ShaderProgram {

  /// The vertex shader
  final String vShader;
  
  /// The fragment shader
  final String fShader;

  ShaderProgram({this.vShader, this.fShader});

  /// Any subclasses of this class can override this to prepare themselves for use by [renderer]
  ShaderProgram prepare(Renderer renderer) => this;
}


/// Selects the right shader to used from the given ones based on the graphics library used by
/// the used [Renderer]
class ContextShaderProgram extends ShaderProgram {

  final ShaderProgram gl;    // desktop opengl
  final ShaderProgram gles;  // mobile and webgl

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


/// Represents an object that can be drwan on screen from vertices. A renderer may extend this class
/// to describe the renderables it prefers
class Renderable {

  final ShaderProgram shaderProgram;
  final Float32List   vertices;
  final Int32List     indices;
  final Float32List   colors;
  final Matrix3       transform;
  final Texture       texture;
  final Int32List     texCoords;

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


/// A [Renderer] consumes [Renderables] and draws them to whatever surface it renders it.
abstract class Renderer{

  /// The graphics library used by this renderer
  GraphicsLib get graphicsLib;

  /// Initialise resources and be ready for consuming renderables
  void initialise();

  /// Pause rendering
  void pause();

  /// Resume rendering
  void resume();

  /// Release all resources and be ready for destruction. It is assumed that after calling this method
  /// this renderer is no longer usable.
  void destroy();

  /// Set the background color of the drawing surface to [color]
  void setClearColor(Vector4 color);

  /// Add a new [Renderable] to be drawn
  void add(Renderable renderable);

  /// Stop drawing [renderable] and remove. Returns the removed renderable on success, null on error
  Renderable remove(Renderable renderable);

  /// Pause the rendering of [renderable]
  void hide(Renderable renderable);

  /// Resume the rendering of [renderable]
  void show(Renderable renderable);

  /// Draw all the visible renderables
  void draw();
}