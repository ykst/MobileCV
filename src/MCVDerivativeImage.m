// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Accelerate/Accelerate.h>
#import "MCVDerivativeImage.h"
#import "TGLProgram.h"
#import "TGLVertexArrayObject.h"
#import "TGLVertexBufferObject.h"
#import "TGLFrameBufferObject.h"

@interface MCVDerivativeImage()
@property (nonatomic) GLint attribute_position;
@property (nonatomic) GLint attribute_inputTextureCoordinate;
@property (nonatomic) GLint uniform_luminanceTexture;
@end

@implementation MCVDerivativeImage


+ (MCVDerivativeImage *)create
{
    MCVDerivativeImage *obj = [[MCVDerivativeImage alloc] init];

    return obj;
}

- (id)init
{
    self = [super init];
    if (self) {
        [TGLDevice runPassiveContextSync:^{
            [self _setupShader];
        }];
    }
    return self;
}

- (void)_setupShader
{
    extern char window3x3_1tex_vs_glsl[];
    extern char derivative_fs_glsl[];

    [self setupShaderWithVS:NSSTR(window3x3_1tex_vs_glsl) withFS:NSSTR(derivative_fs_glsl)];

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

- (BOOL)_checkFormatSrc:(MCVBufferFreight *)src forDst:(MCVBufferFreight *)dst
{
    ASSERT(src.size.width == dst.size.width, return NO);
    ASSERT(src.size.height == dst.size.height, return NO);

    return YES;
}

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst withFeature:(MCVPointFeatureFreight *)feature
{
    //ASSERT([self _checkFormatSrc:src forDst:dst], return NO);

    BENCHMARK("xderivative")
    [TGLDevice runPassiveContextSync:^{
        [_program use];

        [_fbo bind];

        glViewport(0, 0, src.size.width, src.size.height);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, dst.plane.name, 0);
        
        glActiveTexture(GL_TEXTURE2);
        [src.plane bind];
        glUniform1i(_uniform_luminanceTexture, 2);

        [_vao bind];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        [[_vao class] unbind];

        glDiscardFramebufferEXT(GL_FRAMEBUFFER,1,(GLenum []){GL_COLOR_ATTACHMENT0});
        [[_fbo class] unbind];

        [TGLProgram unuse];
    }];


    BENCHMARK("pixel count")
    [dst.plane useReadOnly:^(const void *buf) {
        const uint8_t *buf8 = buf;
        size_t effective_points = 0;
        int width = src.size.width;
        int height = src.size.height;
        int max_points = feature.total_elems;

        // TODO: MUST be vectorized. it takes up 5ms for VGA
        for (int i = 0; i < height ; ++i) {
            for (int j = 0; j < width && effective_points < max_points; ++j) {
                if(buf8[4*(i*width + j)]) {
                    int right = j;
                    int weight_max = 0;
                    do {
                        weight_max = MAX(weight_max, buf8[4*(i*width + right) + 3]);
                        ++right;
                    } while (right < width && buf8[4*(i*width + right)]);

                    int center = (j + (right - 1)) / 2;

                    j = right - 1;

                    GLKVector4 *v = &feature.buf[effective_points];
                    v->x = center / (float)width;
                    v->y = i / (float)height;
                    v->z = 0; // no class is assigned
                    v->w = weight_max / 255.0;

                    if (v->x > 1.0) {
                        ICHECK;
                    }

                    if (v->y > 1.0) {
                        ICHECK;
                    }

                    ++effective_points;
                }
            }
            
        }
        feature.effective_elems = effective_points;
        DUMPD(effective_points);
    }];
    
    
    return YES;
}

@end

