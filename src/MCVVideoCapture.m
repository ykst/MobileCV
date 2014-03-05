// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <CoreMotion/CoreMotion.h>
#import "MCVVideoCapture.h"
#import "TGLDevice.h"
#import "MCVCameraBufferFreight.h"
@interface MCVVideoCapture() {
    @protected
    AVCaptureDevice *_device;
    AVCaptureSession *_session;
    AVCaptureDeviceInput *_input;
    AVCaptureVideoDataOutput *_output;
    dispatch_queue_t _queue;
    CMMotionManager *_core_motion;
    EAGLContext *_context;
}

@property (nonatomic, readwrite) MTNode *conduit;

@end

@implementation MCVVideoCapture


+ (MCVVideoCapture *)createWithConduit:(MTNode *)conduit
{
    MCVVideoCapture *obj = [[MCVVideoCapture alloc] init];

    obj.conduit = conduit;

    return obj;
}

- (void)_setupDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            _device = device;
            break;
        }
    }
}

- (void)_setupInput
{
    NSError *error = nil;
    AVCaptureDeviceInput *input  = [[AVCaptureDeviceInput alloc] initWithDevice:_device error:&error];

    //DUMPS([error localizedDescription]);

    _input = input;
}

- (void)_setupOutput
{
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];


    [output setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];

    //[output setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];

    // TODO: select?
    /*
     [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];

     [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
     */

    [output setAlwaysDiscardsLateVideoFrames:YES]; // TODO: is this necessary?

    _queue = dispatch_queue_create("com.monadworks.mcv.video", NULL);
    // TODO: concurrent queue occasionaly cause crash on resource handling. figures
    // dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0);

    [output setSampleBufferDelegate:self queue:_queue];

    _output = output;
}

- (void)_setupFramerate
{
     for (AVCaptureConnection *connection in _output.connections) {
     #pragma clang diagnostic push
     #pragma clang diagnostic ignored "-Wdeprecated-declarations"
     if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)])
     connection.videoMinFrameDuration = CMTimeMake(1, 30);

     if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)])
     connection.videoMaxFrameDuration = CMTimeMake(1, 30);
     #pragma clang diagnostic pop
     }

    /*
        AVCaptureConnection *conn = [_output connectionWithMediaType:AVMediaTypeVideo];

        if (conn.supportsVideoMinFrameDuration)
            conn.videoMinFrameDuration = CMTimeMake(1,60);
        if (conn.supportsVideoMaxFrameDuration)
            conn.videoMaxFrameDuration = CMTimeMake(1,60);
     */
}

- (void)_setupSession
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];

    if ([session canAddInput:_input]) {
        [session addInput:_input];
    }

    if ([session canAddOutput:_output]) {
        [session addOutput:_output];
    }

    [session beginConfiguration];
    {
        NSString *preset = AVCaptureSessionPreset640x480; // TODO: modifieable

        [session setSessionPreset:preset];

    }
    [session commitConfiguration];

    _session = session;
}

- (void) _setupCoreMotion
{
    CMMotionManager *manager = [[CMMotionManager alloc] init];

    if (manager.deviceMotionAvailable) {

        [manager startDeviceMotionUpdates];

        _core_motion = manager;
    }
}

- (void)_setupGLContext
{
    _context = [TGLDevice createContext];
}

- (id)init
{
    self = [super init];
    if (self) {
        // TODO: select another device?
        [self _setupDevice];
        [self _setupInput];
        [self _setupOutput];
        [self _setupFramerate];
        [self _setupSession];
        [self _setupCoreMotion];
        [self _setupGLContext];
    }
    return self;
}

- (void)startCapture
{
    [_session startRunning];
}

- (void)stopCapture
{
    [_session stopRunning];
}

- (BOOL)isCapturing
{
    return [_session isRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    MTNode *conduit = self.conduit;
    if (!_session.isRunning || [conduit isPaused]) {
        return;
    }

    MCVCameraBufferFreight *freight;

    BENCHMARK("wait buffer") {
        // FIXME:
        // blocking this dispatch queue seems to cause GL-context inconsistency
        // this is something related to deallocation but not explained fully.
        if (conduit.num_out_get == 0) {
            return;
        } else {
            freight = (id)[conduit outGet];
        }
    }

    if (freight == nil) return;

    [TGLDevice setContext:_context];

    BENCHMARK("refill")
    [freight refill:sampleBuffer];

    if (_core_motion) {
        CMAttitude *attitude  = _core_motion.deviceMotion.attitude;
        CMAcceleration user_accel  = _core_motion.deviceMotion.userAcceleration;
        [freight modifyAttitude:attitude.roll :attitude.pitch :attitude.yaw];

        freight.user_accel = GLKVector3Make(user_accel.x, user_accel.y, user_accel.z);
    } else {
        [freight modifyAttitude:0 :0 :0];
    }

    [conduit outPut:freight];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //ICHECK;
}

- (void)dealloc
{
    ICHECK;
}

@end

