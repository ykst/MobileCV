// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVTextureRenderer : TGLShaderWrapper {
    @protected
    GLint _attribute_position;
    GLint _attribute_inputTextureCoordinate;
    GLint _uniform_inputTexture;
}

+ (MCVTextureRenderer *)create;
- (BOOL)process:(MCVBufferFreight *)src;
@end

