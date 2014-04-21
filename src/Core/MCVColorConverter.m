// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <GLKit/GLKit.h>

#import "MCVColorConverter.h"
#import "TGLDevice.h"
#import "TGLProgram.h"
#import "TGLVertexArrayObject.h"
#import "TGLVertexBufferObject.h"
#import "TGLFrameBufferObject.h"

@interface MCVColorConverter() {
    GLColorConverterType _type;
}

@property (nonatomic) GLint attribute_position;
@property (nonatomic) GLint attribute_inputTextureCoordinate;

@property (nonatomic) GLint uniform_luminanceTexture;
@property (nonatomic) GLint uniform_chrominanceTexture;
@property (nonatomic) GLint uniform_colorConversionMatrix;
@end

@implementation MCVColorConverter

+ (instancetype)createWithType:(GLColorConverterType)type
{
    MCVColorConverter *obj = [[[self class] alloc] initWithType:type];

    return obj;
}

- (id)initWithType:(GLColorConverterType)type
{
    self = [super init];
    if (self) {
        _type = type;
        [TGLDevice runPassiveContextSync:^{
            [self _setupShader];
        }];
    }
    return self;
}

- (void)_setupShader
{
    extern char passthrough_1tex_vs_glsl[];
    extern char yuv_rgb_fs_glsl[];

    [self setupShaderWithVS:NSSTR(passthrough_1tex_vs_glsl) withFS:NSSTR(yuv_rgb_fs_glsl)];

    _vao = [TGLVertexArrayObject create];

    [_vao bind];

    _vbo = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW
                                     withAutoOffset:YES
                                        withCommand:(struct gl_vbo_object_command []){
                                            {
                                                .attribute = _attribute_position,
                                                .counts = 2,
                                                .type = GL_FLOAT,
                                                .elems = 4,
                                                .ptr = (GLfloat [8]) {
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
                                                .ptr = NULL
                                            },
                                            {}
    }];

    [[_vao class] unbind]; // save the state

    /*
     // BT.601, which is the standard for SDTV.
     const GLfloat kColorConversion601[] = {
     1.164,  1.164, 1.164,
     0.0, -0.392, 2.017,
     1.596, -0.813,   0.0,
     };

     // BT.709, which is the standard for HDTV.
     const GLfloat kColorConversion709[] = {
     1.164,  1.164, 1.164,
     0.0, -0.213, 2.112,
     1.793, -0.533,   0.0,
     };
     CFTypeRef colorAttachments = CVBufferGetAttachment(cameraFrame, kCVImageBufferYCbCrMatrixKey, NULL);
     if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
     _preferredConversion = kColorConversion601;
     }
     else {
     _preferredConversion = kColorConversion709;
     }
     */

    const GLfloat kColorConversion601[] = {
        1.164,  1.164, 1.164,
        0.0, -0.392, 2.017,
        1.596, -0.813,   0.0,
    };

    [_program use];
    glUniformMatrix3fv(_uniform_colorConversionMatrix, 1, GL_FALSE, kColorConversion601);
    [TGLProgram unuse];

    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];
}

#define __MAXIMUM_UPRIGHT_SCALE_FACTOR 3.0f

static void __calc_calibrated_texture_coordinate(GLfloat array2x4[8], double roll, double pitch)
{
    GLfloat texture_coordinates[8] = {
        0.0f, 0.0f,
        1.0f, 0.0f,

        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    if (1 ||  ABS(sinf(roll)) < 1 / __MAXIMUM_UPRIGHT_SCALE_FACTOR) {
        //if (ABS(sinf(roll)) < 1 / __MAXIMUM_UPRIGHT_SCALE_FACTOR) {
        for (int i = 0; i < 8; ++i) {
            array2x4[i] = texture_coordinates[i];
        }
        return;
    }


    GLfloat yscale = MAX(ABS(sinf(roll)), 1 / __MAXIMUM_UPRIGHT_SCALE_FACTOR);
    GLfloat xdistortion = roll > 0 ? -pitch : pitch;
    yscale = roll > 0 ? yscale : -yscale;
    GLfloat xscale = roll > 0 ? 1.0f : -1.0f;

    GLKMatrix4 calibration_mat =
    GLKMatrix4Multiply(
                       GLKMatrix4Multiply(
                                          GLKMatrix4Multiply(
                                                             GLKMatrix4MakeTranslation(0.5, 0.5, 0),
                                                             GLKMatrix4MakeZRotation(xdistortion)),
                                          GLKMatrix4MakeScale(xscale, yscale, 1)),
                       GLKMatrix4MakeTranslation(-0.5, -0.5, 0));;

    for (int i = 0; i < 4; ++i) {

        GLKVector4 v = GLKMatrix4MultiplyVector4(calibration_mat, GLKVector4Make(texture_coordinates[2*i], texture_coordinates                              [2*i+1], 0, 1));
        
        array2x4[2*i] = v.x;
        array2x4[2*i + 1] = v.y;
    }
     
}

- (BOOL)process:(MCVBufferFreight<MCVSubPlanerBufferProtocol, MCVAttitudeFreightProtocol> *)src to:(MCVBufferFreight *)dst
{
    BENCHMARK("ccv")
    [TGLDevice runPassiveContextSync:^{
        GLfloat texture_coord[8];

        __calc_calibrated_texture_coordinate(texture_coord, src.roll, -src.pitch);
        
        [_program use];

        [_fbo bind];

        glViewport(0, 0, dst.size.width, dst.size.height);

        [dst.plane attachColorFB];

        [src.plane setUniform:_uniform_luminanceTexture onUnit:2];
        [src.subplane setUniform:_uniform_chrominanceTexture onUnit:3];

        [_vbo subDataOfAttribute:_attribute_inputTextureCoordinate withPointer:texture_coord withElems:4];

        [_vao bind];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);GLASSERT;
        [[_vao class] unbind];

        [[_fbo class] discardColor];

        [[_fbo class] unbind];
    }];

    return YES;
}
@end

