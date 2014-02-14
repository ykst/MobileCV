//
//  MCVTexturePassthrough.h
//  Pods
//
//  Created by Yukishita Yohsuke on 2014/02/14.
//
//

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVTexturePassthrough : TGLShaderWrapper
+ (MCVTexturePassthrough *)create;
- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst;
@end
