# IHFScanView
更容易的集成你的扫描框！

IHFScanview 是一个用来扫描码的框 。
IHFScanview 主要是以下2个用途

####用途1:更容易的集成扫描框####

创建好IHFScanview后，加入到你想要的扫描的页面就可以。
```
CGFloat scanViewY = 125;
// 创建一个与屏幕一样宽，跟上下距离为125的Scanview
IHFScanView *scanView = [[IHFScanView alloc] initWithFrame:CGRectMake(0, scanViewY , self.view.frame.size.width, self.view.frame.size.height - scanViewY * 2)];
// self.view 为要扫描的控制器
[self.view addSubview:scanView];
```

加入后要调用startScaning
```
- (void)startScaning:(ScanResult)scanResult;
```

scanResult 回调扫描结果

使用 StopScaning 关闭 扫描

> 开始和停止扫描是非常关键的，要在合适时间打开和关闭扫描。比如ViewAppear或者是Disappear等。

####用途2:IHFScanInterestType的设置####
IHFScanInterestType 有2个设置 ：
IHFScanInterestTypeNormal ：默认,也就是扫描区域是居中而且范围是{220，220} ， 跟微信扫描类似 。
IHFScanInterestTypeFullFrame ： 这个设置下扫描区域是整个ScanView .
根据你的项目页面来决定要设置哪个模式 。

>  IHFScanInterestTypeNormal 下 {220，220} 会有限制扫描区域，会提升扫描效率 。 当然你的scanviewFrame的Width和Height 不要小于220 ， 否则也会变成220 或者造成一些不可预知的问题。


最后有个属性 isNeedFocusGesture .默认是YES ， 也就是在扫描可以手动聚焦，默认焦点是屏幕中央。如果不要，将其设为NO.

简书地址 http://www.jianshu.com/p/9592c8c034bf
有问题assues： cjsykx@163.com