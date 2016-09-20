//
//  ViewController.m
//  IHFScanView
//
//  Created by chenjiasong on 16/8/25.
//  Copyright © 2016年 Cjson. All rights reserved.
//

#import "ViewController.h"
#import "IHFScanView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    UIButton *start = [[UIButton alloc] init];
    
    
    CGFloat scanViewY = 125;
    
    IHFScanView *scanView = [[IHFScanView alloc] initWithFrame:CGRectMake(0, scanViewY , self.view.frame.size.width, self.view.frame.size.height - scanViewY * 2)];
    [self.view addSubview:scanView];
    
//    scanView.scanInterestType = IHFScanInterestTypeFullFrame;
    [self beginScan:scanView];
}

- (void)beginScan:(IHFScanView *)scanView {
    
    [scanView startScaning:^(NSString *result) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描成功" message:result preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self beginScan:scanView];
        }];
        
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
