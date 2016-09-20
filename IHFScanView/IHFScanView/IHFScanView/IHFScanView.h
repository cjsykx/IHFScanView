//
//  IHFScanView.h
//  IHFScanView
//
//  Created by chenjiasong on 16/8/25.
//  Copyright © 2016年 Cjson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, IHFScanInterestType){ // Decision sizeOfInterest
    
    IHFScanInterestTypeNormal = 0x00,  // Defalut , sizeOfInterest is {220, 220} .
    IHFScanInterestTypeFullFrame = 0x01, // The sizeOfInterest is the scan view frame size
    
};

/**
 It's a scan view for scan QR code . You only create the scan view , and add to your view which want to execute scan .
 It important to chooce IHFScanInterestType . If you chooce IHFScanInterestTypeNormal , it will be size of interest and scan range is {220,220} , and alignment center in in the scan view . If you chooce IHFScanInterestTypeFullFrame , the scan view full frame is size of interest and scan range. 
 */
@interface IHFScanView : UIView<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, assign, readonly) CGSize sizeOfInterest; /**< Defalut IHFScanInterestType IHFScanInterestTypeNormal, so size is {220, 220} .If IHFScanInterestTypeFullFrame,The sizeOfInterest is the scan view frame size */

@property (nonatomic, assign) IHFScanInterestType scanInterestType; /**< Defalut IHFScanInterestTypeNormal */

@property (strong, nonatomic) AVCaptureDevice * device; /**< Device , User can change device parameters what you want to set */

@property (assign, nonatomic) BOOL isNeedFocusGesture; /**< Defalut Yes , If you not need , you can set it not to close the focus gesture */

typedef void(^ScanResult)(NSString * result);
@property (nonatomic, copy) ScanResult scanResult; /**< call back the scan result */

/**
 The scan view begin scaning
 @warning : If you want to begin scaning , you must call the method . 
 NOT scanResult , you can use scanResult to call block get result also .
 @tips : it'd better call it in view will appear .
 */

- (void)startScaning;

/** 
 The scan view begin scaning
 @warning : If you want to begin scaning , you must call the method .
 @tips : it'd better call it in view will appear .
 @scanResult : Get the scan result , and do you want!
 */

- (void)startScaning:(ScanResult)scanResult;

/**
 The scan view stop scaning
 @warning : If you want to stop scaning , you must call the method .
 @tips : it'd better call it in view will disappear .
 */
- (void)StopScaning;



@end
