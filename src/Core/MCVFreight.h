// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface MCVFreight : NSObject

@end

@protocol MCVAttitudeFreightProtocol <NSObject>
@property (nonatomic, readonly) double roll;
@property (nonatomic, readonly) double pitch;
@property (nonatomic, readonly) double yaw;
@end

@protocol MCVVec3ArrayFreightProtocol <NSObject>
@property (nonatomic, readwrite) size_t effective_elems;
@property (nonatomic, readonly) size_t total_elems;
@property (nonatomic, readonly) GLKVector3 *buf;
@end

@protocol MCVVec4ArrayFreightProtocol <NSObject>
@property (nonatomic, readwrite) size_t effective_elems;
@property (nonatomic, readonly) size_t total_elems;
@property (nonatomic, readonly) GLKVector4 *buf;
@end

