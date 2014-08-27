#VMSegmentControl
================

VMSegmentControl 纵向排列的SegmentControl

##使用效果:

![file-list](https://github.com/khan-lau/VMSegmentControl/blob/master/example/example.jpg)



##使用方法:

```objc
....
    self.seg = [[VMSegmentControl alloc] initWithSectionImages:tabs sectionSelectedImages:select_tabs titlesForSections:titles];
    r = self.view.frame;
    r.origin.x = xoffset;
    r.origin.y = 25;
    r.size.width = 60;
    r.size.height = 200;
    self.seg.frame = r;
    
    self.seg.font = [UIFont systemFontOfSize:12];
    self.seg.textColor = [UIColor lightTextColor];
    self.seg.selectedTextColor = [UIColor whiteColor];
    self.seg.selectionIndicatorWidth = 4.0f;
    self.seg.backgroundColor = [UIColor clearColor];
    self.seg.selectionStyle = VMSegmentedControlSelectionStyleBox;
    self.seg.segmentWidthStyle = VMSegmentedControlSegmentWidthStyleDynamic;
    self.seg.selectionIndicatorLocation = VMSegmentedControlSelectionIndicatorLocationRight;
    
    [self.view addSubview:self.seg];
....


    __weak __typeof(self) weakSelf = self;
    [self.seg setIndexChangeBlock:^(NSInteger index) {
        NSLog(@"%ld", (long) index);
        [weakSelf.scrollView scrollRectToVisible:CGRectMake(0, r.size.height*index, r.size.width, r.size.height) animated:YES];
    }];
    
```
