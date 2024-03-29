//
//  CheckStateView.h
//  PatrolSystem
//
//  Created by 刘艳凯 on 2017/7/5.
//  Copyright © 2017年 YiTu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckStateView : UIView
@property (nonatomic, strong) UILabel *titleLb;
@property (nonatomic, strong) UIButton *checkBtn;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, copy) void (^checkBtnBlock)();
@property (nonatomic, copy) void (^closeBtnBlock)();
@end
