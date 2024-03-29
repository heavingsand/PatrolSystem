//
//  LZBCalendarAppearStyle.m
//  LZBCalendar
//
//  Created by zibin on 16/11/13.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "LZBCalendarAppearStyle.h"

@implementation LZBCalendarAppearStyle
- (instancetype)init
{
  if(self = [super init])
  {
      self.isNeedCustomHeihgt = YES;
      self.today = [NSDate date];
      
      self.headerViewDateHeight = 40;
      self.headerViewLineHeight = 1.0;
      self.headerViewWeekHeight = 40;
      self.weekDateDays = @[@"日",@"一",@"二",@"三",@"四",@"五",@"六"];
      self.headerViewDateFont = [UIFont systemFontOfSize:16.0];
      self.headerViewWeekFont = [UIFont systemFontOfSize:16.0];
      self.headerViewWeekColor = kColorMain;
      self.headerViewDateColor = [UIColor whiteColor];
      
      self.itemHeight = 0;
      self.dateTittleFont = [UIFont systemFontOfSize:16.0];
      self.dateDescFont = [UIFont systemFontOfSize:16.0];
      self.dateTittleSelectColor = [UIColor whiteColor];
      self.dateTittleUnselectColor = [UIColor blackColor];
//      self.dateDescSelectColor = [UIColor blueColor];
//      self.dateDescUnselectColor = [UIColor purpleColor];
      self.dateBackUnselectColor = [UIColor whiteColor];
      self.dateBackSelectColor = kColorMain;
      self.isSupportMoreSelect = NO;
      self.dateTitleDescOffset = UIOffsetMake(0, 10);
      
  }
    return self;
}

- (CGFloat)headerViewHeihgt
{
    return self.headerViewDateHeight + self.headerViewLineHeight + self.headerViewWeekHeight;
}



@end
