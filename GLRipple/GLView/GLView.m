//
//  GLView.m
//  GLRipple
//
//  Created by ikuo on 2014/09/04.
//  Copyright (c) 2014年 aquaware. All rights reserved.
//

#import "GLView.h"
#import "UIImage+extension.h"

@implementation GLView

bool CheckGLError()
{
    GLenum error = glGetError();
    if(error) {
        NSLog(@"OpenGL error# %d", error);
        return false;
    }
    
    return true;
}

bool CheckGLError2(GLint glid, const char* name)
{
    if(glid < 0) {
        NSLog(@"OpenGL error in %s", name);
        return false;
    }
    
    return true;
}

GLchar* sourceString(NSString* name, NSString* type)
{
    NSString *vertexPath = [[NSBundle mainBundle] pathForResource: name ofType: type];
    GLchar* source = (GLchar*) [[NSString stringWithContentsOfFile: vertexPath
                                                          encoding: NSUTF8StringEncoding
                                                             error: nil]
                                  UTF8String];
    return source;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self){
		[self initGL];
	}
	return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initGL];
    }
    return self;
}

- (void) initGL
{
    [self setupLayer];
    [self setupContext];
    [self createDepthBufferWithSize: self.frame.size];
    [self createColorBuffer];
    [self createFrameBuffer];
    [self compileShaders];
    [self setupDisplayLink];
    
    [self loadTextures];
    [self setupModel];
    [self setupVBOs];
}

- (void) setupLayer
{
    glLayer = (CAEAGLLayer*) self.layer;
    glLayer.opaque = YES;
}

- (void) setupContext
{
    context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSAssert(0, @"Failed to initialize OpenGLES 2.0 context");
    }
    
    if (![EAGLContext setCurrentContext: context]) {
        NSAssert(0, @"Failed to set current OpenGL context");
    }
}

- (void) createColorBuffer
{
    glGenRenderbuffers(1, &colorBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable: glLayer];
}

- (void) createFrameBuffer
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuffer);
}

- (void) createDepthBufferWithSize: (CGSize) size
{
    glGenRenderbuffers(1, &depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, size.width, size.height);
}

- (void) clearScreen
{
    glClearColor( 0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
}

- (GLuint)compileShader:(NSString*) fileName withType: (GLenum) type
{
    const GLchar* shaderString = sourceString(fileName, @"glsl");
    GLuint handle = glCreateShader(type);
    glShaderSource(handle, 1, &shaderString, 0);
    glCompileShader(handle);
    
    GLint compileSuccess;
    glGetShaderiv(handle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(handle, sizeof(messages), 0, &messages[0]);
        NSString* str = [NSString stringWithUTF8String: messages];
        NSAssert(0, @"%@", str);
    }
    
    return handle;
}

- (void) compileShaders
{
    GLuint vertexShader   = [self compileShader: @"vertex"   withType: GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader: @"fragment" withType: GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint linkResult;
    glGetProgramiv(program, GL_LINK_STATUS, &linkResult);
    if (linkResult == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString* str = [NSString stringWithUTF8String: messages];
        NSAssert(0, @"%@", str);
    }
    
    glUseProgram(program);
    attributes[POSITION] = glGetAttribLocation(program, "position");
    attributes[TEX_COORD] = glGetAttribLocation(program, "texCoord");
    glEnableVertexAttribArray(attributes[POSITION]);
    glEnableVertexAttribArray(attributes[TEX_COORD]);

    uniforms[PROJECTION] = glGetUniformLocation(program, "projection");
    uniforms[RESOLUTION] = glGetUniformLocation(program, "resolution");
    uniforms[SAMPLER_RGB] = glGetUniformLocation(program, "samplerRGB");
}

-(void) deleteAllVBOs
{
    for (int i = 0; i < NUMBER_OF_GL_MODELS; i++) {
        glDeleteBuffers(1, &positionVBOs[i]);
        glDeleteBuffers(1, &indexVBOs[i]);
        glDeleteBuffers(1, &texCoordVBOs[i]);
    }
}

-(void) setupVBOs
{
    [self setupIndexVBOs];
    [self setupPositionVBOs];
    [self setupTexCoordVBOs];
}

-(void) setupIndexVBOs
{
    int size = [rippleModel getVertexSize];
    GLushort* indices = [rippleModel getIndices];
    glGenBuffers(1, &indexVBOs[0]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexVBOs[0]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size, indices, GL_STATIC_DRAW);
}

-(void) setupPositionVBOs
{
    int size = [rippleModel getVertexSize];
    GLfloat* v = [rippleModel getVertices];
    glGenBuffers(1, &positionVBOs[0]);
    glBindBuffer(GL_ARRAY_BUFFER, positionVBOs[0]);
    glBufferData(GL_ARRAY_BUFFER, size, v, GL_STATIC_DRAW);
    
    glVertexAttribPointer(attributes[POSITION],     2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
}

- (void) setupTexCoordVBOs
{
    int size = [rippleModel getVertexSize];
    GLfloat* coords = [rippleModel getTexCoords];
    
    glGenBuffers(1, &texCoordVBOs[0]);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordVBOs[0]);
    glBufferData(GL_ARRAY_BUFFER, size, coords, GL_DYNAMIC_DRAW);
    
    glVertexAttribPointer(attributes[TEX_COORD],    2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
}

-(void) setupProjectionScaleX: (float) scaleX ScaleY: (float) scaleY transX: (float) transX transY: (float) transY
{
    GLfloat matrix[] =
    {
        scaleX,    0.0,  0.0, transX,
           0.0, scaleY,  0.0, transY,
           0.0,    0.0,  1.0,    0.0,
           0.0,    0.0,  0.0,    1.0,
    };
    
    glUniformMatrix4fv(uniforms[PROJECTION], 1, 0, matrix);
}

- (void) loadTextures
{
    textures[0] = [self loadTexture: @"monet.jpg"];
}

- (Texture) loadTexture: (NSString*) imageName
{
    Texture tex;
    
    UIImage* image = [UIImage imageNamed: imageName];
    CGImageRef imageRef = [image rotateWithAngle: 90.0f];
    if (!imageRef) {
        NSAssert(0, @"Failed to load image %@", imageName);
    }
    
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);

    GLubyte* imageData = (GLubyte*) calloc( (int) width * (int) height * 4, sizeof(GLubyte));
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = (CGBitmapInfo) kCGImageAlphaPremultipliedLast;
    CGContextRef imageContext = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, bitmapInfo);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), imageRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(imageContext);

    GLuint textureName;
    glGenTextures(1, &textureName);
    glBindTexture(GL_TEXTURE_2D, textureName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    free(imageData);
    
    tex.imageSize  = CGSizeMake(width, height);
    tex.texture = textureName;
    
    return tex;
}

- (void) setupModel
{
    unsigned int meshFactor;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        meshFactor = 8;
    }
    else{
        meshFactor = 4;
    }
    
    rippleModel = [[RippleModel alloc] initWithScreenWidth: self.frame.size.width
                                              screenHeight: self.frame.size.height
                                                meshFactor: meshFactor
                                               touchRadius: 5.0
                                              textureWidth: textures[0].imageSize.width
                                             textureHeight: textures[0].imageSize.height];
}

- (void) setupDisplayLink
{
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget: self selector:@selector(render:)];
    [displayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
}

-  (void) render: (CADisplayLink*) displayLink
{
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    [self clearScreen];
    
    // Calculate Matrix
    [self render];
    [context presentRenderbuffer: GL_RENDERBUFFER];
}

- (void) render
{
    float displayAspect = (float) self.frame.size.width / (float) self.frame.size.height;
    double scaleX = 1.0;
    double scaleY = 1.0;
    if(displayAspect > 1.0) {
        scaleX = displayAspect;
        scaleY = 1.0;
    }
    else {
        scaleX = 1.0;
        scaleY = displayAspect;
    }
    
    [self setupProjectionScaleX: scaleX ScaleY: scaleY transX: 0.0 transY: 0.0];
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //glUniform1i(uniforms[TEXTURE], 0);
    //glUniform2f(uniforms[RESOLUTION], (GLfloat) self.frame.size.width, (GLfloat) self.frame.size.height );
    [self bindTextures];
    
    if (rippleModel)
    {
        [rippleModel runSimulation];
        
        int size = [rippleModel getVertexSize];
        GLfloat * coords = [rippleModel getTexCoords];
        glBufferData(GL_ARRAY_BUFFER, size, coords, GL_DYNAMIC_DRAW);
        
        glDrawElements(GL_TRIANGLE_STRIP, [rippleModel getIndexCount], GL_UNSIGNED_SHORT, 0);
    }
}

- (void) bindTextures
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textures[PICTURE_SPRITE].texture);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = (UITouch*)[touches anyObject];
    CGPoint point = [touch locationInView: self];
    
    if( rippleModel ) {
        [rippleModel initiateRippleAtLocation: point];
    }
}

@end
