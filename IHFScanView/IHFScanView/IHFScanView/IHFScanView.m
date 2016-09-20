//
//  IHFScanView.m
//  IHFScanView
//
//  Created by chenjiasong on 16/8/25.
//  Copyright © 2016年 Cjson. All rights reserved.
//

#import "IHFScanView.h"

static CGFloat _kScanInterestValue = 220;

@interface IHFScanView () 

@property (strong, nonatomic) AVCaptureDeviceInput * input;
@property (strong, nonatomic) AVCaptureMetadataOutput * output;
@property (strong, nonatomic) AVCaptureSession * session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * previewLayer;

// line
@property (nonatomic, strong) UIImageView * lineImageView;
@property (nonatomic, strong) CAKeyframeAnimation *animation;

// Focus
@property (nonatomic, strong) UITapGestureRecognizer *focusGesture;
@property (nonatomic, strong) UIView *focusView;

// Interest
@property (nonatomic, weak) UIView *interestView;

@property (nonatomic, weak) UIImageView * leftTopImageView;
@property (nonatomic, weak) UIImageView * leftBottomImageView;
@property (nonatomic, weak) UIImageView * rightTopImageView;
@property (nonatomic, weak) UIImageView * rightBottomImageView;

// background view out of interest view
@property (nonatomic, weak) UIImageView * topImageView;
@property (nonatomic, weak) UIImageView * leftImageView;
@property (nonatomic, weak) UIImageView * rightImageView;
@property (nonatomic, weak) UIImageView * bottomImageView;

@end

@implementation IHFScanView

#pragma mark - default set
- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if(self) {
        
        // Not allow view width and height less than scan interest
        if (frame.size.height < self.sizeOfInterest.height) {
            frame.size.height = self.sizeOfInterest.height;
        }
        
        if (frame.size.width < self.sizeOfInterest.width) {
            frame.size.width = self.sizeOfInterest.width;
        }
        
        self.frame = frame;
        
        [self configureView];
        [self configureAVCapture];
    }
    return self;
}

- (void)setScanInterestType:(IHFScanInterestType)scanInterestType {
    
    _scanInterestType = scanInterestType;
    
    CGSize sizeOfInterest;
    if (_scanInterestType == IHFScanInterestTypeNormal) {
        sizeOfInterest = CGSizeMake(_kScanInterestValue, _kScanInterestValue);
    }else if (_scanInterestType == IHFScanInterestTypeFullFrame) {
        sizeOfInterest = CGSizeMake(self.frame.size.width, self.frame.size.height);
    }
    _sizeOfInterest = sizeOfInterest;
    
    // reset rect of interest
    [self setRectOfInterest];
    
    [self layoutIfNeeded];
}
#pragma mark - configure avcapture

- (void)configureAVCapture {
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    if (_device.hasTorch && [_device isTorchModeSupported:AVCaptureTorchModeAuto]) {
        if ([_device lockForConfiguration:&error]) {
            [_device setTorchMode:AVCaptureTorchModeAuto];
            
            // Set Near , it will
            [_device setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
            [_device setFocusPointOfInterest:CGPointMake(0.5f, 0.5f)];
            
            [_device unlockForConfiguration];
        }
    }
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    [self setRectOfInterest];
    
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input]) {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output]) {
        [_session addOutput:self.output];
    }
    
    // Have to add another video ouput for auto-torch mode.
    // See http://stackoverflow.com/questions/21053152/ios-7-avcapturetorchmodeauto-doesnt-seem-to-activate-torch-in-low-light/22822953
    AVCaptureOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:videoOutput];
    
    
    // 条码类型
    NSMutableArray *resultTypes = [NSMutableArray array];
    NSArray *supportedTypes = self.output.availableMetadataObjectTypes;
    NSArray *expectedTypes = @[AVMetadataObjectTypeQRCode];
    [expectedTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([supportedTypes containsObject:obj]) {
            [resultTypes addObject:obj];
        }
    }];
    
    if ([resultTypes count] == 0)  {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请到设置->移动护理->打开相机权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//        [alert show];
        

        NSLog(@"%@" ,@"没有打开相机权限");
        return;
    }
    
    self.output.metadataObjectTypes = resultTypes;
    
    // Preview layer
    _previewLayer =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame =self.bounds;
    [self.layer insertSublayer:self.previewLayer atIndex:0];
    
    // Default set YES !
    self.isNeedFocusGesture = YES;
}

- (void)setRectOfInterest {
    
    // View size
    CGFloat viewH = self.frame.size.height;
    CGFloat viewW = self.frame.size.width;
    
    // Interest size
    CGFloat interestW = self.sizeOfInterest.width;
    CGFloat interestH = self.sizeOfInterest.height;
    
    // set the scan range
    [_output setRectOfInterest:CGRectMake( (viewH - interestW ) * 0.5  / viewH ,(viewW - interestW) * 0.5 / viewW , interestH / viewH , interestW / viewW)];
}
#pragma mark - configure view 
- (void)configureView {
    
    _sizeOfInterest = CGSizeMake(_kScanInterestValue, _kScanInterestValue);
    
    UIView *interestView = [[UIView alloc] init];
    interestView.backgroundColor = [UIColor clearColor];
    interestView.layer.borderWidth = 0.5;
    interestView.layer.borderColor = [UIColor whiteColor].CGColor;
    [self addSubview:interestView];
    _interestView = interestView;
    
    [self addBackgoundViewOutOfInterestView];
    
    [self addLine];
    [self addInterestImage];
}

- (void)addBackgoundViewOutOfInterestView {
    
    // top
    UIImageView * scanBGTopImageView = [[UIImageView alloc] init];
    scanBGTopImageView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self addSubview:scanBGTopImageView];
    _topImageView = scanBGTopImageView;
    
    // bottom
    UIImageView * scanBGFootImageView = [[UIImageView alloc] init];
    scanBGFootImageView.backgroundColor = scanBGTopImageView.backgroundColor;
    [self addSubview:scanBGFootImageView];
    _bottomImageView = scanBGFootImageView;
    
    // left
    UIImageView * scanBGLeftImageView = [[UIImageView alloc] init];
    scanBGLeftImageView.backgroundColor = scanBGTopImageView.backgroundColor;
    [self addSubview:scanBGLeftImageView];
    _leftImageView = scanBGLeftImageView;
    
    // right
    UIImageView * scanBGRightImageView = [[UIImageView alloc] init];
    scanBGRightImageView.backgroundColor = scanBGTopImageView.backgroundColor;
    [self addSubview:scanBGRightImageView];
    _rightImageView = scanBGRightImageView;
}

- (void)addLine {
    
    _lineImageView = [[UIImageView alloc] init];
    
    _lineImageView.image = [UIImage imageNamed:@"scan_Line.png"];
    [_interestView addSubview:_lineImageView];
    _lineImageView.layer.anchorPoint = CGPointMake(0, 0);
}

- (void)addInterestImage {

    UIImageView * leftTopImageView = [[UIImageView alloc] init];
    leftTopImageView.image = [UIImage imageNamed:@"scan_LeftTop_image"];
    [_interestView addSubview:leftTopImageView];
    _leftTopImageView = leftTopImageView;
    
    UIImageView * leftBottomImageView = [[UIImageView alloc] init];
    leftBottomImageView.image = [UIImage imageNamed:@"scan_LeftBottom_image"];
    [_interestView addSubview:leftBottomImageView];
    _leftBottomImageView = leftBottomImageView;
    
    UIImageView * rightTopImageView = [[UIImageView alloc] init];
    rightTopImageView.image = [UIImage imageNamed:@"scan_RightTop_image"];
    [_interestView addSubview:rightTopImageView];
    _rightTopImageView = rightTopImageView;
    
    UIImageView * rightBottomImageView = [[UIImageView alloc] init];
    rightBottomImageView.image = [UIImage imageNamed:@"scan_RightBottom_image"];
    [_interestView addSubview:rightBottomImageView];
    _rightBottomImageView = rightBottomImageView;
}

#pragma mark - start and stop scan

- (void)startScaning {
    [self startScaning:nil];
}

- (void)startScaning:(ScanResult)scanResult {
    // Start
    [_session startRunning];
    
    // let line move
    [self beginLineImageViewMoving];
    self.scanResult = scanResult;
}

- (CAKeyframeAnimation *)animation {
    
    if (!_animation) {
        
        // keyframeAnimation for line move
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
        
        anim.keyPath = @"position";
        anim.duration = 2;
        
        // animation repeatCount
        anim.repeatCount = MAXFLOAT;
        
        // keep not back to start point
        anim.removedOnCompletion = NO;
        anim.fillMode = kCAFillModeForwards;
        _animation = anim;
    }
    return _animation;
}

/**
 *  let line begin moveing
 */
-(void)beginLineImageViewMoving {
    
    // scanview X and y
    CGFloat viewY =  0;
    CGFloat viewX = _lineImageView.frame.origin.x ;
    
    NSValue *beginValue = [NSValue valueWithCGPoint:CGPointMake(viewX,viewY)];
    NSValue *moveValue = [NSValue valueWithCGPoint:CGPointMake(viewX,viewY + self.sizeOfInterest.height)];
    NSValue *endValue = [NSValue valueWithCGPoint:CGPointMake(viewX,viewY)];
    
    self.animation.values = @[beginValue, moveValue, endValue];
    
    [self.lineImageView.layer addAnimation:_animation forKey:@"move"];
}

- (void)StopScaning {
    [_session stopRunning];
    
    [self.lineImageView.layer removeAnimationForKey:@"move"];
}

#pragma mark - gesture

- (UITapGestureRecognizer *)focusGesture {
    if (!_focusGesture) {
        _focusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapToFocus:)];
    }
    return _focusGesture;
}

- (void)setIsNeedFocusGesture:(BOOL)isNeedFocusGesture {
    if(isNeedFocusGesture) {
        [self.interestView addGestureRecognizer:self.focusGesture];
    } else {
        [self.interestView removeGestureRecognizer:self.focusGesture];
    }
}

-(void)didTapToFocus:(UITapGestureRecognizer *)gesture {
    UIView *locationView = gesture.view;
    CGPoint point = [gesture locationInView:locationView];
    CGPoint focusPoint = CGPointMake(point.x / locationView.frame.size.width, point.y / locationView.frame.size.height);
    [self focusAtPoint:focusPoint];
    [self focusViewAnimation:point];
}

// focus at the given point
-(void)focusAtPoint:(CGPoint)point {
    if ([_device isFocusPointOfInterestSupported] && [_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            [_device setFocusPointOfInterest:point];
            [_device setFocusMode:AVCaptureFocusModeAutoFocus];
            
            if ([_device isExposurePointOfInterestSupported] && [_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_device setExposurePointOfInterest:point];
                [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [_device unlockForConfiguration];
        }
    }
}

- (UIView *)focusView {
    
    if(!_focusView) {
        _focusView = [[UIView alloc]init];
        _focusView.layer.borderWidth = 2;
        _focusView.layer.borderColor = [UIColor greenColor].CGColor;
        [_interestView.layer addSublayer:_focusView.layer];
    }
    return _focusView;
}

-(void)focusViewAnimation:(CGPoint)point {
    
    self.focusView.frame = CGRectMake(0, 0, 80, 80);
    _focusView.center = point;
    _focusView.alpha = 1;
    __weak typeof(self) weakSelf = self;

    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.focusView.frame = CGRectMake(0, 0, 60, 60);
        weakSelf.focusView.center = point;
    } completion:^(BOOL finished) {
        weakSelf.focusView.alpha = 0;
        [UIView animateWithDuration:0.1 animations:^{
            weakSelf.focusView.alpha = 1;
        } completion:^(BOOL finished)  {
            weakSelf.focusView.alpha = 0;
        }];
    }];
}

#pragma mark - layout

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    CGFloat interestH = self.sizeOfInterest.height;
    CGFloat interestW = self.sizeOfInterest.width;
    
    // scanview X and y
    CGFloat viewY = (self.frame.size.height - interestH) * 0.5;
    CGFloat viewX = (self.frame.size.width  - interestW) * 0.5 ;
    
    _interestView.frame = CGRectMake(viewX, viewY, interestW, interestH);
    
    // Line
    CGFloat lineImageViewW = _kScanInterestValue;
    CGFloat lineImageViewX = (interestW - _kScanInterestValue) * 0.5;
    
    _lineImageView.frame = CGRectMake(lineImageViewX, 0, lineImageViewW, 2);
    
    // Around image
    CGFloat imageWidth = 30.0 * 0.5;
    CGFloat imageHeight = 35 * 0.5;
    CGFloat imageX = 0;
    CGFloat imageY = 0;

    _leftTopImageView.frame = CGRectMake(imageX, imageY, imageWidth, imageHeight);
    _leftBottomImageView.frame = CGRectMake(imageX, imageY + interestH - imageHeight, imageWidth, imageHeight);
    _rightTopImageView.frame = CGRectMake(imageX +interestW - imageWidth, imageY , imageWidth, imageHeight);
    _rightBottomImageView.frame = CGRectMake(imageX + interestW - imageWidth, imageY + interestH - imageHeight, imageWidth, imageHeight);
    
    // background out of interest
    
    // top
    CGFloat scanBGImageViewX = 0;
    CGFloat scanBGImageViewY = 0;
    CGFloat scanBGImageViewWidth = self.frame.size.width;
    CGFloat scanBGImageViewHeight = viewY ;
    _topImageView.frame = CGRectMake(scanBGImageViewX, scanBGImageViewY, scanBGImageViewWidth, scanBGImageViewHeight);

    // bottom
    CGFloat scanBGFootImageViewX = 0;
    CGFloat scanBGFootImageViewY = scanBGImageViewHeight + interestH;
    CGFloat scanBGFootImageViewWidth = scanBGImageViewWidth;
    CGFloat scanBGFootImageViewHeight = scanBGImageViewHeight;
    
    _bottomImageView.frame = CGRectMake(scanBGFootImageViewX, scanBGFootImageViewY, scanBGFootImageViewWidth, scanBGFootImageViewHeight);
    
    // left
    CGFloat scanBGLeftImageViewX = 0;
    CGFloat scanBGLeftImageViewY = scanBGImageViewHeight;
    CGFloat scanBGLeftImageViewWidth = viewX;
    CGFloat scanBGLeftImageViewHeight = interestW;
    
    _leftImageView.frame = CGRectMake(scanBGLeftImageViewX, scanBGLeftImageViewY, scanBGLeftImageViewWidth, scanBGLeftImageViewHeight);
    
    // right
    CGFloat scanBGRightImageViewX = scanBGLeftImageViewWidth + interestW;
    CGFloat scanBGRightImageViewY = scanBGImageViewHeight;
    CGFloat scanBGRightImageViewWidth = scanBGLeftImageViewWidth;
    CGFloat scanBGRightImageViewHeight = interestW;
    
    _rightImageView.frame = CGRectMake(scanBGRightImageViewX, scanBGRightImageViewY, scanBGRightImageViewWidth, scanBGRightImageViewHeight);
}


#pragma mark AVCapture Metadata Output Objects delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *stringValue;
    
    if ([metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    
    [self StopScaning];
    
    if (self.scanResult) {
        self.scanResult(stringValue);
    }
}

@end
