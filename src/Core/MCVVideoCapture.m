// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVVideoCapture.h"
#import "TGLDevice.h"
#import "MCVCameraBufferFreight.h"

@interface MCVVideoCapture()

@property (nonatomic, readwrite) MTNode *conduit;

@end

@implementation MCVVideoCapture

+ (NSArray *)countSupportedPositions
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in devices) {
        [result addObject:@([device position])];
    }

    return result;
}

static int __torch_support = -1;
static BOOL __torch_on = NO;

+ (BOOL)hasTorch
{
    if (__torch_support < 0) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device respondsToSelector:@selector(hasTorch)] &&
            [device respondsToSelector:@selector(hasFlash)] &&
            [device hasTorch] && [device hasFlash]) {

            __torch_support = 1;
        } else {
            __torch_support = 0;
        }
    }

    return __torch_support == 1;
}

+ (BOOL)torchIsOn
{
    return __torch_on;
}

+ (void)turnTorchOn:(BOOL)on
{
    // check if flashlight available
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil && [[self class] hasTorch]) {

        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:nil];

        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
            __torch_on = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
            __torch_on = NO;
        }
        [device unlockForConfiguration];
    }
}

+ (instancetype)createWithConduit:(MTNode *)conduit withInputPreset:(NSString *)preset withPosition:(AVCaptureDevicePosition)position
{
    MCVVideoCapture *obj = [[[self class] alloc] init];

    obj.conduit = conduit;

    [obj _setupWithPreset:preset withPosition:position];

    return obj;
}

+ (instancetype)createWithConduit:(MTNode *)conduit withInputPreset:(NSString *)preset
{
    return [[self class] createWithConduit:conduit withInputPreset:preset withPosition:AVCaptureDevicePositionBack];
}

// backward compat version
+ (instancetype)createWithConduit:(MTNode *)conduit
{
    return [[self class] createWithConduit:conduit withInputPreset:AVCaptureSessionPreset640x480];
}

- (void)_setupWithPreset:(NSString *)preset withPosition:(AVCaptureDevicePosition)position
{
    // TODO: select another device?
    [self _setupDeviceOfPosition:position];
    [self _setupInput];
    [self _setupOutput];
    [self _setupFramerate];
    [self _setupSession:preset];
    [self _setupGLContext];
}

- (void)_setupDeviceOfPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            _device = device;
            _position = position;
            _focus_supported =
                [_device respondsToSelector:@selector(isFocusPointOfInterestSupported)] &&
                [_device respondsToSelector:@selector(focusMode)] &&
                [_device respondsToSelector:@selector(setFocusPointOfInterest:)] &&
                [_device isFocusPointOfInterestSupported];
            break;
        }
    }
}

- (void)_setupInput
{
    NSError *error = nil;

    AVCaptureDeviceInput *input  = [[AVCaptureDeviceInput alloc] initWithDevice:_device error:&error];

    _input = input;
}

- (void)_setupOutput
{
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];


    [output setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];

    [output setAlwaysDiscardsLateVideoFrames:YES];

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
         if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)]) {
             connection.videoMinFrameDuration = CMTimeMake(1, 30);
         }

         if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)]) {
             connection.videoMaxFrameDuration = CMTimeMake(1, 30);
         }
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

- (void)_setupSession:(NSString *)preset
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
        [session setSessionPreset:preset];
        if ([session respondsToSelector:@selector(setUsesApplicationAudioSession:)]) {
            [session setUsesApplicationAudioSession:NO]; // iOS7+ audio interruption work around
        }
    }
    [session commitConfiguration];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_inputSettingChanged) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];

    _session = session;
}

- (void)_inputSettingChanged
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    AVCaptureInput *input = _session.inputs[0];
    AVCaptureInputPort *port = input.ports[0];
    CMFormatDescriptionRef formatDescription = port.formatDescription;
    CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(formatDescription);

    _capture_size.width = dimension.width;
    _capture_size.height = dimension.height;

    _capture_size_available = YES;
}

- (void)_setupGLContext
{
    _context = [TGLDevice createContext];
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

- (BOOL)focusPointSupported
{
    return _focus_supported;
}

- (void)setFocusPoint:(CGPoint)focus_point
{
    if (_focus_supported) {
        [_device lockForConfiguration:nil];
        _device.focusMode = AVCaptureFocusModeAutoFocus;
        [_device setFocusPointOfInterest:focus_point];
        [_device unlockForConfiguration];
    }
}

- (void)setAutoFocus
{
    if (_focus_supported) {
        [_device lockForConfiguration:nil];
        _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        [_device unlockForConfiguration];
    }
}

- (void)appendMetaInfo:(MCVBufferFreight *)freight
{
    // override this
    /*
    if (_core_motion) {
        CMAttitude *attitude  = _core_motion.deviceMotion.attitude;
        CMAcceleration user_accel  = _core_motion.deviceMotion.userAcceleration;
        [freight modifyAttitude:attitude.roll :attitude.pitch :attitude.yaw];

        freight.user_accel = GLKVector3Make(user_accel.x, user_accel.y, user_accel.z);
    } else {
        [freight modifyAttitude:0 :0 :0];
    }
     */
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

    [TGLDevice setContext:nil];

    [self appendMetaInfo:freight];

    [conduit outPut:freight];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //ICHECK;
}

- (void)dealloc
{
    //ICHECK;
}

@end

