//
//  MCV3x3ConvolutionShaderWrapper.h
//  Pods
//
//  Created by Yukishita Yohsuke on 2014/06/09.
//
//

#import "TGLShaderWrapper.h"

@interface MCV3x3ConvolutionShaderWrapper : TGLShaderWrapper

@property (nonatomic, readwrite) GLint attribute_position;
@property (nonatomic, readwrite) GLint attribute_inputTextureCoordinate;

- (void)setupShaderWithFS:(NSString *)fs;

@end
