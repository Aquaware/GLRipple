//
//  GLView.h
//  GLRipple
//
//  Created by ikuo on 2014/09/04.
//  Copyright (c) 2014年 aquaware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include "RippleModel.h"

typedef struct {
    float Position[3];
    float TexCoord[2];
} Vertex;

typedef struct {
    GLuint texture;
    CGSize imageSize;
} Texture;

enum Attributes
{
    POSITION,
    TEX_COORD,
    NUMBER_OF_ATTRIBUTES
};
GLuint attributes[NUMBER_OF_ATTRIBUTES];

enum Uniforms
{
    PROJECTION,
    RESOLUTION,
    SAMPLER_RGB,
    NUMBER_OF_UNIFORMS
};
GLuint uniforms[NUMBER_OF_UNIFORMS];

enum Textures
{
    PICTURE_SPRITE,
    NUMBER_OF_TEXTURES
};
Texture textures[NUMBER_OF_TEXTURES];

enum Models
{
    RIPPLE_MODEL,
    NUMBER_OF_GL_MODELS
};
GLuint positionVBOs[NUMBER_OF_GL_MODELS];
GLuint indexVBOs[NUMBER_OF_GL_MODELS];
GLuint texCoordVBOs[NUMBER_OF_GL_MODELS];

@interface GLView : UIView
{
    CAEAGLLayer* glLayer;
    EAGLContext* context;
    GLuint colorBuffer;
    GLuint depthBuffer;
    
    RippleModel* rippleModel;
}


@end
