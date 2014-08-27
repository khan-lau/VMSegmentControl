//
//  VMViewController.m
//  VMSegmentControlExample
//
//  Created by Khan on 14-8-27.
//  Copyright (c) 2014年 Khan.lau. All rights reserved.
//

#import "VMViewController.h"
#import "VMSegmentControl.h"

@interface VMViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) VMSegmentControl *seg;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation VMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self initView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) initView{
    self.view.userInteractionEnabled = YES;

    
    
    CGFloat xoffset = 0;
    CGFloat width = 272;
    CGRect r = self.view.frame;
    NSArray * tabs = @[[UIImage imageNamed:@"tab-global"], [UIImage imageNamed:@"tab-private"], [UIImage imageNamed:@"tab-personal"]];
    NSArray * select_tabs = @[[UIImage imageNamed:@"tab-global-p"], [UIImage imageNamed:@"tab-private-p"], [UIImage imageNamed:@"tab-personal-p"]];
    NSArray * titles = @[@"Public", @"Private", @"Moment"];
    //    NSArray * titles = @[@"Moment", @"Moment", @"Moment"];
    //    self.seg = [[VMSegmentControl alloc] initWithSectionTitles:titles];
    //    self.seg = [[VMSegmentControl alloc] initWithSectionImages:tabs sectionSelectedImages:select_tabs];
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
    
    
    
    r = self.view.frame;
    r.origin.x = xoffset + self.seg.frame.origin.x + self.seg.frame.size.width;
    r.origin.y = 25;
    r.size.width = width - r.origin.x;
    r.size.height = r.size.height - r.origin.y - 58;
    self.scrollView = [[UIScrollView alloc] initWithFrame:r];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    
    self.scrollView.contentSize = CGSizeMake(r.size.width, r.size.height*3);
    self.scrollView.delegate = self;
    
    [self.view addSubview:self.scrollView];
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, r.size.width, r.size.height)];
    [self setApperanceForLabel:label1];
    label1.text = @"Headlines1";
    [self.scrollView addSubview:label1];
    
    
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, r.size.height, r.size.width, r.size.height)];
    [self setApperanceForLabel:label2];
    label2.text = @"Headlines2";
    [self.scrollView addSubview:label2];
    
    UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(0, r.size.height*2, r.size.width, r.size.height)];
    [self setApperanceForLabel:label3];
    label3.text = @"Headlines3";
    [self.scrollView addSubview:label3];
    
    __weak __typeof(self) weakSelf = self;
    [self.seg setIndexChangeBlock:^(NSInteger index) {
        NSLog(@"%ld", (long) index);
        [weakSelf.scrollView scrollRectToVisible:CGRectMake(0, r.size.height*index, r.size.width, r.size.height) animated:YES];
    }];
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageHeight = scrollView.frame.size.height;
    NSInteger page = scrollView.contentOffset.y / pageHeight;
    
    [self.seg setSelectedSegmentIndex:page animated:YES];
}

- (void)setApperanceForLabel:(UILabel *)label {
        CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
        UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
        label.backgroundColor = color;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:21.0f];
    label.textAlignment = NSTextAlignmentCenter;
}

@end
