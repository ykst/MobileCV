//
//  MCV3x3ConvolutionShaderWrapper.m
//  Pods
//
//  Created by Yukishita Yohsuke on 2014/06/09.
//
//

#import "MCV3x3ConvolutionShaderWrapper.h"


@implementation MCV3x3ConvolutionShaderWrapper

- (void)setupShaderWithFS:(NSString *)fs
{
    extern char window3x3_1tex_vs_glsl[];

    [self setupShaderWithVS:NSSTR(window3x3_1tex_vs_glsl) withFS:fs];

    _vao = [TGLVertexArrayObject create];
    [_vao bind];

    _vbo = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW withAutoOffset:YES withCommand:(struct gl_vbo_object_command []){
        {
            .attribute = _attribute_position,
            .counts = 2,
            .type = GL_FLOAT,
            .elems = 4,
            .ptr = (GLfloat []) {
                -1, -1,
                1, -1,
                -1, 1,
                1, 1
            }
        },
        {
            .attribute = _attribute_inputTextureCoordinate,
            .counts = 2,
            .type = GL_FLOAT,
            .elems = 4,
            .ptr = (GLfloat []){
                0.0f, 0.0f,
                1.0f, 0.0f,
                0.0f, 1.0f,
                1.0f, 1.0f,
            }
        },
        {}
    }];

    [[_vao class] unbind];

    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];
}

@end