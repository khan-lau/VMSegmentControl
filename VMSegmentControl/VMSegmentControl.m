//
//  VMSegmentControl.m
//  CIM4Iphone
//
//  Created by Khan.Lau on 14-6-19.
//  Copyright (c) 2014年 Khan.Lau. All rights reserved.
//

#import "VMSegmentControl.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define segmentImageTextPadding 5

@interface VMScrollView : UIScrollView
@end


@interface VMSegmentControl ()

@property (nonatomic, strong) CALayer *selectionIndicatorStripLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorBoxLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorArrowLayer;
@property (nonatomic, readwrite) CGFloat segmentHeight;
@property (nonatomic, readwrite) NSArray *segmentHeightsArray;
@property (nonatomic, strong) VMScrollView *scrollView;

@end

@implementation VMScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!self.dragging) {
        [self.nextResponder touchesMoved:touches withEvent:event];
    } else{
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesEnded:touches withEvent:event];
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

@end

@implementation VMSegmentControl

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithSectionTitles:(NSArray *)sectiontitles {
    self = [self initWithFrame:CGRectZero];
    
    if (self) {
        [self commonInit];
        self.sectionTitles = sectiontitles;
        self.type = VMSegmentedControlTypeText;
    }
    
    return self;
}

- (id)initWithSectionImages:(NSArray*)sectionImages sectionSelectedImages:(NSArray*)sectionSelectedImages {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self commonInit];
        self.sectionImages = sectionImages;
        self.sectionSelectedImages = sectionSelectedImages;
        self.type = VMSegmentedControlTypeImages;
    }
    
    return self;
}

- (instancetype)initWithSectionImages:(NSArray *)sectionImages sectionSelectedImages:(NSArray *)sectionSelectedImages titlesForSections:(NSArray *)sectiontitles {
	self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self commonInit];
		
		if (sectionImages.count != sectiontitles.count) {
			[NSException raise:NSRangeException format:@"***%s: Images bounds (%ld) Dont match Title bounds (%ld)", sel_getName(_cmd), (unsigned long)sectionImages.count, (unsigned long)sectiontitles.count];
        }
		
        self.sectionImages = sectionImages;
        self.sectionSelectedImages = sectionSelectedImages;
		self.sectionTitles = sectiontitles;
        self.type = VMSegmentedControlTypeTextImages;
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.segmentHeight = 0.0f;
    [self commonInit];
}

- (void)commonInit {
    self.scrollView = [[VMScrollView alloc] init];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    self.font = [UIFont fontWithName:@"STHeitiSC-Light" size:18.0f];
    self.textColor = [UIColor blackColor];
    self.selectedTextColor = [UIColor blackColor];
    self.backgroundColor = [UIColor whiteColor];
    self.opaque = NO;
    self.selectionIndicatorColor = [UIColor colorWithRed:52.0f/255.0f green:181.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
    
    self.selectedSegmentIndex = 0;
    self.segmentEdgeInset = UIEdgeInsetsMake(4, 5, 0, 5);
    self.selectionIndicatorWidth = 5.0f;
    self.selectionIndicatorEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    self.selectionStyle = VMSegmentedControlSelectionStyleTextWidthStripe;
    self.selectionIndicatorLocation = VMSegmentedControlSelectionIndicatorLocationLeft;
    self.segmentWidthStyle = VMSegmentedControlSegmentWidthStyleFixed;
    self.userDraggable = YES;
    self.touchEnabled = YES;
    self.type = VMSegmentedControlTypeText;
    
    self.shouldAnimateUserSelection = YES;
    
    self.selectionIndicatorArrowLayer = [CALayer layer];
    self.selectionIndicatorStripLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer.opacity = self.selectionIndicatorBoxOpacity;
    self.selectionIndicatorBoxLayer.borderWidth = 1.0f;
    self.selectionIndicatorBoxOpacity = 0.2;
    
    self.contentMode = UIViewContentModeRedraw;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateSegmentsRects];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self updateSegmentsRects];
}

- (void)setSectionTitles:(NSArray *)sectionTitles {
    _sectionTitles = sectionTitles;
    
    [self setNeedsLayout];
}

- (void)setSectionImages:(NSArray *)sectionImages {
    _sectionImages = sectionImages;
    
    [self setNeedsLayout];
}

- (void)setSelectionIndicatorLocation:(VMSegmentedControlSelectionIndicatorLocation)selectionIndicatorLocation {
	_selectionIndicatorLocation = selectionIndicatorLocation;
	
	if (selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationNone) {
		self.selectionIndicatorWidth = 0.0f;
	}
}

- (void)setSelectionIndicatorBoxOpacity:(CGFloat)selectionIndicatorBoxOpacity {
    _selectionIndicatorBoxOpacity = selectionIndicatorBoxOpacity;
    
    self.selectionIndicatorBoxLayer.opacity = _selectionIndicatorBoxOpacity;
}

#pragma mark - Drawing

- (CALayer *) badage : (CGFloat) width{
//    NSLog(@"add arc layer %ld", (long)idx);
    //画圆
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect arc_rect = CGRectMake(0, 0, 10, 10);
    [path addArcWithCenter: CGPointMake( width - 2, 0) radius:arc_rect.size.width/2 startAngle:0 endAngle:2*M_PI clockwise:NO];
    
    CAShapeLayer* arcLayer = [CAShapeLayer layer];
    arcLayer.path = path.CGPath;//46,169,230
    
    arcLayer.fillColor = [UIColor colorWithRed:46.0/255.0 green:169.0/255.0 blue:230.0/255.0 alpha:1].CGColor;
    arcLayer.strokeColor = [UIColor colorWithWhite:1 alpha:0.7].CGColor;
    arcLayer.lineWidth = 1;
    arcLayer.frame = arc_rect;
    
    return arcLayer;
//    [imageLayer addSublayer:arcLayer];
}



- (void)drawRect:(CGRect)rect {
    [self.backgroundColor setFill];
    UIRectFill([self bounds]);
    
    self.selectionIndicatorArrowLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    self.selectionIndicatorStripLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    self.selectionIndicatorBoxLayer.backgroundColor   = self.selectionIndicatorColor.CGColor;
    self.selectionIndicatorBoxLayer.borderColor       = self.selectionIndicatorColor.CGColor;
    
    // Remove all sublayers to avoid drawing images over existing ones
    self.scrollView.layer.sublayers = nil;
    
    if (self.type == VMSegmentedControlTypeText) {
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            
            CGFloat stringWidth = 0;
            CGFloat stringHeight = 0;
            CGSize stringSize = [self getSizeByString:titleString];
            stringWidth = stringSize.width;
            stringHeight = stringSize.height;
            
            // Text inside the CATextLayer will appear blurry unless the rect values are rounded
            CGFloat x = roundf(CGRectGetWidth(self.frame) - self.selectionIndicatorWidth)/2 - stringWidth/2 + ((self.selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationLeft) ? self.selectionIndicatorWidth : 0);
//            CGFloat y = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight)/2 - stringHeight/2 + ((self.selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationUp) ? self.selectionIndicatorHeight : 0);
            CGRect rect;
            if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
                rect = CGRectMake(x, (self.segmentHeight * idx) + (self.segmentHeight - stringHeight)/2,  stringWidth, self.segmentHeight);
            } else if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                CGFloat yOffset = 0;
                NSInteger i = 0;
                for (NSNumber *heigth in self.segmentHeightsArray) {
                    if (idx == i)
                        break;
                    yOffset = yOffset + [heigth floatValue];
                    i++;
                }
                
                rect = CGRectMake(x, yOffset,  stringWidth, [[self.segmentHeightsArray objectAtIndex:idx] floatValue]);
            }
            
            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = rect;
            titleLayer.font = (__bridge CFTypeRef)(self.font.fontName);
            titleLayer.fontSize = self.font.pointSize;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            titleLayer.string = titleString;
            titleLayer.truncationMode = kCATruncationEnd;
            
            if (self.selectedSegmentIndex == idx) {
                titleLayer.foregroundColor = self.selectedTextColor.CGColor;
            } else {
                titleLayer.foregroundColor = self.textColor.CGColor;
            }
            
            titleLayer.contentsScale = [[UIScreen mainScreen] scale];
            [self.scrollView.layer addSublayer:titleLayer];
        }];
    } else if (self.type == VMSegmentedControlTypeImages) {
        
        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
            
            CGFloat x = ( CGRectGetWidth (self.frame) - imageWidth)/2.0f;
            CGFloat y = ( self.segmentHeight * idx) + + (self.segmentHeight - imageHeight)/2.0f;
            
            CGRect rect = CGRectMake(x, y, imageWidth, imageHeight);
            
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = rect;
            
            if (self.selectedSegmentIndex == idx) {
                if (self.sectionSelectedImages) {
                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
                    imageLayer.contents = (id)highlightIcon.CGImage;
                } else {
                    imageLayer.contents = (id)icon.CGImage;
                }
            } else {
                imageLayer.contents = (id)icon.CGImage;
            }
            
            [self.scrollView.layer addSublayer:imageLayer];
        }];
    } else if (self.type == VMSegmentedControlTypeTextImages){
		[self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            // When we have both an image and a title, we start with the image and use segmentImageTextPadding before drawing the text.
            // So the image will be left to the text, centered in the middle
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
			
            CGFloat stringWidth = 0;
            CGFloat stringHeight = 0;
            NSString * titleString = self.sectionTitles[idx];
            CGSize stringSize = [self getSizeByString:titleString];
            stringWidth = stringSize.width;
            stringHeight = stringSize.height;
            
            CGFloat xOffset = roundf(((CGRectGetWidth (self.frame) - self.selectionIndicatorWidth) / 2) - (imageWidth / 2));
            CGFloat xTitleOffset = roundf(((CGRectGetWidth (self.frame) - self.selectionIndicatorWidth) / 2) - (stringWidth / 2));
            
            CGFloat imageYOffset = self.segmentEdgeInset.top; // Start with edge inset
            
            if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed)
                imageYOffset = self.segmentHeight * idx;
            else if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                NSInteger i = 0;
                for (NSNumber *height in self.segmentHeightsArray) {
                    if (idx == i)
                        break;
                    imageYOffset = imageYOffset + [height floatValue];
                    i++;
                }
            }
            
            CGRect imageRect = CGRectMake(xOffset, imageYOffset, imageWidth, imageHeight);
			
            // Use the image offset and padding to calculate the text offset
            CGFloat textYOffset = imageYOffset + imageHeight + segmentImageTextPadding;
            
            // The text rect's width is the segment width without the image, image padding and insets
            CGRect textRect = CGRectMake(xTitleOffset, textYOffset, stringWidth, [[self.segmentHeightsArray objectAtIndex:idx] floatValue]-imageHeight-segmentImageTextPadding-self.segmentEdgeInset.top-self.segmentEdgeInset.bottom);
            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = textRect;
            titleLayer.font = (__bridge CFTypeRef)(self.font.fontName);
            titleLayer.fontSize = self.font.pointSize;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            titleLayer.string = self.sectionTitles[idx];
            titleLayer.truncationMode = kCATruncationEnd;
			
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = imageRect;
			
            if (self.selectedSegmentIndex == idx) {
                if (self.sectionSelectedImages) {
                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
                    imageLayer.contents = (id)highlightIcon.CGImage;
                } else {
                    imageLayer.contents = (id)icon.CGImage;
                }
				titleLayer.foregroundColor = self.selectedTextColor.CGColor;
            } else {
                imageLayer.contents = (id)icon.CGImage;
				titleLayer.foregroundColor = self.textColor.CGColor;
            }
            
            [self.scrollView.layer addSublayer:imageLayer];
			titleLayer.contentsScale = [[UIScreen mainScreen] scale];
            [self.scrollView.layer addSublayer:titleLayer];
			
        }];
	}
    
    // Add the selection indicators
    if (self.selectedSegmentIndex != VMSegmentedControlNoSegment) {
        if (self.selectionStyle == VMSegmentedControlSelectionStyleArrow) {
            if (!self.selectionIndicatorArrowLayer.superlayer) {
                [self setArrowFrame];
                [self.scrollView.layer addSublayer:self.selectionIndicatorArrowLayer];
            }
        } else {
            if (!self.selectionIndicatorStripLayer.superlayer) {
                self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
                [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                
                if (self.selectionStyle == VMSegmentedControlSelectionStyleBox && !self.selectionIndicatorBoxLayer.superlayer) {
                    self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
                    [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                }
            }
        }
    }
}

- (void)setArrowFrame {
    self.selectionIndicatorArrowLayer.frame = [self frameForSelectionIndicator];
    self.selectionIndicatorArrowLayer.mask = nil;
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    
    CGPoint p1 = CGPointZero;
    CGPoint p2 = CGPointZero;
    CGPoint p3 = CGPointZero;
    
    if (self.selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationRight) {
        p1 = CGPointMake(0,  self.selectionIndicatorArrowLayer.bounds.size.height / 2);
        p2 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width, 0);
        p3 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.height, self.selectionIndicatorArrowLayer.bounds.size.width);
    }
    
    if (self.selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationLeft) {
        p1 = CGPointMake(0, 0);
        p2 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width, self.selectionIndicatorArrowLayer.bounds.size.height / 2);
        p3 = CGPointMake(0, self.selectionIndicatorArrowLayer.bounds.size.height);
        
        
    }
    
    [arrowPath moveToPoint:p1];
    [arrowPath addLineToPoint:p2];
    [arrowPath addLineToPoint:p3];
    [arrowPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.selectionIndicatorArrowLayer.bounds;
    maskLayer.path = arrowPath.CGPath;
    self.selectionIndicatorArrowLayer.mask = maskLayer;
}

- (CGRect)frameForSelectionIndicator {
    CGFloat indicatorXOffset = 0.0f;
    
    if (self.selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationRight) {
        indicatorXOffset = self.bounds.size.width - self.selectionIndicatorWidth + self.selectionIndicatorEdgeInsets.right;
    }
    
    if (self.selectionIndicatorLocation == VMSegmentedControlSelectionIndicatorLocationLeft) {
        indicatorXOffset = self.selectionIndicatorEdgeInsets.left;
    }
    
    CGFloat sectionHeight = 0.0f;
    
    if (self.type == VMSegmentedControlTypeText) {
        CGFloat stringHeight = [[self.sectionTitles objectAtIndex:self.selectedSegmentIndex] sizeWithFont:self.font].height;
        sectionHeight = stringHeight;
    } else if (self.type == VMSegmentedControlTypeImages) {
        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
        CGFloat imageHeight = sectionImage.size.height;
        sectionHeight = imageHeight;
    } else if (self.type == VMSegmentedControlTypeTextImages) {
		CGFloat stringHeight = [[self.sectionTitles objectAtIndex:self.selectedSegmentIndex] sizeWithFont:self.font].height;
		UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
		CGFloat imageHeight = sectionImage.size.height;
        if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
            sectionHeight = MAX(stringHeight, imageHeight);
        } else if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
            sectionHeight = imageHeight + segmentImageTextPadding + stringHeight;
        }
	}
    
    if (self.selectionStyle == VMSegmentedControlSelectionStyleArrow) {
        CGFloat widthToEndOfSelectedSegment = (self.segmentHeight * self.selectedSegmentIndex) + self.segmentHeight;
        CGFloat widthToStartOfSelectedIndex = (self.segmentHeight * self.selectedSegmentIndex);
        
        CGFloat y = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (self.selectionIndicatorWidth/2);
        return CGRectMake(indicatorXOffset, y, self.selectionIndicatorWidth, self.selectionIndicatorWidth);
        
    } else {
        if (self.selectionStyle == VMSegmentedControlSelectionStyleTextWidthStripe && sectionHeight <= self.segmentHeight && self.segmentWidthStyle != VMSegmentedControlSegmentWidthStyleDynamic) {
            CGFloat widthToEndOfSelectedSegment = (self.segmentHeight * self.selectedSegmentIndex) + self.segmentHeight;
            CGFloat widthToStartOfSelectedIndex = (self.segmentHeight * self.selectedSegmentIndex);
            
            CGFloat y = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionHeight / 2);
            return CGRectMake(indicatorXOffset, y + self.selectionIndicatorEdgeInsets.top, self.selectionIndicatorWidth, sectionHeight - self.selectionIndicatorEdgeInsets.bottom);
        } else {
            if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
                CGFloat selectedSegmentOffset = 0.0f;
                
                NSInteger i = 0;
                for (NSNumber *height in self.segmentHeightsArray) {
                    if (self.selectedSegmentIndex == i)
                        break;
                    selectedSegmentOffset = selectedSegmentOffset + [height floatValue];
                    i++;
                }
                return CGRectMake(indicatorXOffset, selectedSegmentOffset + self.selectionIndicatorEdgeInsets.top, self.selectionIndicatorWidth + self.selectionIndicatorEdgeInsets.right,  [[self.segmentHeightsArray objectAtIndex:self.selectedSegmentIndex] floatValue] - self.selectionIndicatorEdgeInsets.bottom);
            }
            
            return CGRectMake(indicatorXOffset, (self.segmentHeight + self.selectionIndicatorEdgeInsets.top) * self.selectedSegmentIndex, self.selectionIndicatorWidth, self.segmentHeight - self.selectionIndicatorEdgeInsets.top);
        }
    }
}

- (CGRect)frameForFillerSelectionIndicator {
    if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
        CGFloat selectedSegmentOffset = 0.0f;
        
        NSInteger i = 0;
        for (NSNumber *height in self.segmentHeightsArray) {
            if (self.selectedSegmentIndex == i) {
                break;
            }
            selectedSegmentOffset = selectedSegmentOffset + [height floatValue];
            
            i++;
        }
        
        return CGRectMake( 0, selectedSegmentOffset, CGRectGetWidth(self.frame), [[self.segmentHeightsArray objectAtIndex:self.selectedSegmentIndex] floatValue]);
    }
    return CGRectMake(0, self.segmentHeight * self.selectedSegmentIndex,  CGRectGetWidth(self.frame), self.segmentHeight);
}



- (void)updateSegmentsRects {
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    // When `scrollEnabled` is set to YES, segment width will be automatically set to the width of the biggest segment's text or image,
    // otherwise it will be equal to the width of the control's frame divided by the number of segments.
    if ([self sectionCount] > 0) {
        self.segmentHeight = self.frame.size.height / [self sectionCount];
    }
    
    if (self.type == VMSegmentedControlTypeText && self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
        for (NSString *titleString in self.sectionTitles) {
            CGFloat stringHeight = [self getHeightByString:titleString];
            self.segmentHeight = MAX(stringHeight, self.segmentHeight);
        }
    } else if (self.type == VMSegmentedControlTypeText && self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentHeights = [NSMutableArray array];
        
        for (NSString *titleString in self.sectionTitles) {
            CGFloat stringHeight = [self getHeightByString:titleString];
            [mutableSegmentHeights addObject:[NSNumber numberWithFloat:stringHeight]];
        }
        self.segmentHeightsArray = [mutableSegmentHeights copy];
    } else if (self.type == VMSegmentedControlTypeImages && self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
        for (UIImage *sectionImage in self.sectionImages) {
//            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            CGFloat imageHeight = sectionImage.size.height + self.segmentEdgeInset.top + self.segmentEdgeInset.bottom;
            self.segmentHeight = MAX(imageHeight, self.segmentHeight);
        }
    } else if(self.type == VMSegmentedControlTypeImages && self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic){
        NSMutableArray *mutableSegmentHeights = [NSMutableArray array];
        
        for ( UIImage *sectionImage in self.sectionImages ) {
            CGFloat imageHeight = sectionImage.size.height + self.segmentEdgeInset.top + self.segmentEdgeInset.bottom;
            CGFloat height = MAX(imageHeight, self.segmentHeight);
            [mutableSegmentHeights addObject:[NSNumber numberWithFloat:height]];
        }
        self.segmentHeightsArray = [mutableSegmentHeights copy];
    } else if (self.type == VMSegmentedControlTypeTextImages && VMSegmentedControlSegmentWidthStyleFixed){
        //lets just use the title.. we will assume it is wider then images...
        for (NSString *titleString in self.sectionTitles) {
            CGFloat stringHeight = [self getHeightByString:titleString];
            self.segmentHeight = MAX(stringHeight, self.segmentHeight);
        }
    } else if (self.type == VMSegmentedControlTypeTextImages && VMSegmentedControlSegmentWidthStyleDynamic) {
//        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
        NSMutableArray *mutableSegmentHeights = [NSMutableArray array];
        
        int i = 0;
        for (NSString *titleString in self.sectionTitles) {
            CGFloat stringHeight = [self getHeightByString:titleString];
            UIImage *sectionImage = [self.sectionImages objectAtIndex:i];
//            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left;
//            CGFloat combinedWidth = imageWidth + segmentImageTextPadding + stringWidth;
//            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:combinedWidth]];
            
            CGFloat imageHeight = sectionImage.size.height + self.segmentEdgeInset.top;
            CGFloat combinedHeight = imageHeight + segmentImageTextPadding + stringHeight;
            [mutableSegmentHeights addObject:[NSNumber numberWithFloat:combinedHeight]];
            
            i++;
        }
        self.segmentHeightsArray = [mutableSegmentHeights copy];
    }
    
    self.scrollView.scrollEnabled = self.isUserDraggable;
    self.scrollView.contentSize = CGSizeMake([self totalSegmentedControlHeight], self.frame.size.height);
}

- (NSUInteger)sectionCount {
    if (self.type == VMSegmentedControlTypeText) {
        return self.sectionTitles.count;
    } else if (self.type == VMSegmentedControlTypeImages || self.type == VMSegmentedControlTypeTextImages) {
        return self.sectionImages.count;
    }
    
    return 0;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    // Control is being removed
    if (newSuperview == nil)
        return;
    
    if (self.sectionTitles || self.sectionImages) {
        [self updateSegmentsRects];
    }
}



- (CGSize) getSizeByString:(NSString *) string{
    CGFloat stringWidth = 0;
    CGFloat stringHeight = 0;
    if([string respondsToSelector:@selector(sizeWithAttributes:)]) {
        stringWidth = [string sizeWithAttributes:@{NSFontAttributeName: self.font}].width;
        stringHeight = [string sizeWithAttributes:@{NSFontAttributeName: self.font}].height;
    } else {
        stringWidth = roundf([string sizeWithFont:self.font].width);
        stringHeight = roundf([string sizeWithFont:self.font].height);
    }
    
    return CGSizeMake(stringWidth, stringHeight);
}

- (CGFloat) getHeightByString:(NSString *) string{
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    CGFloat stringHeight = [string sizeWithAttributes:@{NSFontAttributeName: self.font}].height + self.segmentEdgeInset.top + self.segmentEdgeInset.bottom;
#else
    CGFloat stringHeight = [string sizeWithFont:self.font].height + self.segmentEdgeInset.top + self.segmentEdgeInset.bottom;
#endif
    return stringHeight;
}

- (CGFloat) getWidthByString:(NSString*) string{
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    CGFloat stringWidth = [string sizeWithAttributes:@{NSFontAttributeName: self.font}].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#else
    CGFloat stringWidth = [string sizeWithFont:self.font].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#endif
    return stringWidth;
}





#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.bounds, touchLocation)) {
        NSInteger segment = 0;
        if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
            segment = (touchLocation.y + self.scrollView.contentOffset.y) / self.segmentHeight;
        } else if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
            // To know which segment the user touched, we need to loop over the widths and substract it from the x position.
            CGFloat hightTop = (touchLocation.y + self.scrollView.contentOffset.y);
            for (NSNumber *height in self.segmentHeightsArray) {
                hightTop = hightTop - [height floatValue];
                
                // When we don't have any hight top to substract, we have the segment index.
                if (hightTop <= 0)
                    break;
                
                segment++;
            }
        }
        
        NSUInteger sectionsCount = 0;
        
        if (self.type == VMSegmentedControlTypeImages) {
            sectionsCount = [self.sectionImages count];
        } else if (self.type == VMSegmentedControlTypeTextImages || self.type == VMSegmentedControlTypeText) {
            sectionsCount = [self.sectionTitles count];
        }
        
        if (segment != self.selectedSegmentIndex && segment < sectionsCount) {
            // Check if we have to do anything with the touch event
            if (self.isTouchEnabled)
                [self setSelectedSegmentIndex:segment animated:self.shouldAnimateUserSelection notify:YES];
        }
    }
}




#pragma mark - Scrolling

- (CGFloat)totalSegmentedControlHeight {
    if (self.type == VMSegmentedControlTypeText && self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
        return self.sectionTitles.count * self.segmentHeight;
    } else if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
        return [[self.segmentHeightsArray valueForKeyPath:@"@sum.self"] floatValue];
    } else {
        return self.sectionImages.count * self.segmentHeight;
    }
}

- (void)scrollToSelectedSegmentIndex {
    CGRect rectForSelectedIndex;
    CGFloat selectedSegmentOffset = 0;
    if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleFixed) {
        
        rectForSelectedIndex = CGRectMake(0,
                                          self.segmentHeight * self.selectedSegmentIndex,
                                          self.frame.size.width,
                                          self.segmentHeight);
        
        selectedSegmentOffset = (CGRectGetHeight(self.frame) / 2) - (self.segmentHeight / 2);
        
    } else if (self.segmentWidthStyle == VMSegmentedControlSegmentWidthStyleDynamic) {
        
        NSInteger i = 0;
        CGFloat offsetter = 0;
        for (NSNumber *height in self.segmentHeightsArray) {
            if (self.selectedSegmentIndex == i)
                break;
            offsetter = offsetter + [height floatValue];
            i++;
        }
        
        rectForSelectedIndex = CGRectMake(0,
                                          offsetter,
                                          self.frame.size.width,
                                          [[self.segmentHeightsArray objectAtIndex:self.selectedSegmentIndex] floatValue]);
        
        selectedSegmentOffset = (CGRectGetHeight(self.frame) / 2) - ([[self.segmentHeightsArray objectAtIndex:self.selectedSegmentIndex] floatValue] / 2);
        
    }
    
    
    CGRect rectToScrollTo = rectForSelectedIndex;
    rectToScrollTo.origin.y -= selectedSegmentOffset;
    rectToScrollTo.size.height += selectedSegmentOffset * 2;
    [self.scrollView scrollRectToVisible:rectToScrollTo animated:YES];
}

#pragma mark - Index change

- (void)setSelectedSegmentIndex:(NSInteger)index {
    [self setSelectedSegmentIndex:index animated:NO notify:NO];
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated {
    [self setSelectedSegmentIndex:index animated:animated notify:NO];
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated notify:(BOOL)notify {
    _selectedSegmentIndex = index;
    [self setNeedsDisplay];
    
    if (index == VMSegmentedControlNoSegment) {
        [self.selectionIndicatorArrowLayer removeFromSuperlayer];
        [self.selectionIndicatorStripLayer removeFromSuperlayer];
        [self.selectionIndicatorBoxLayer removeFromSuperlayer];
    } else {
        [self scrollToSelectedSegmentIndex];
        
        if (animated) {
            // If the selected segment layer is not added to the super layer, that means no
            // index is currently selected, so add the layer then move it to the new
            // segment index without animating.
            if(self.selectionStyle == VMSegmentedControlSelectionStyleArrow) {
                if ([self.selectionIndicatorArrowLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorArrowLayer];
                    
                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }else {
                if ([self.selectionIndicatorStripLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                    
                    if (self.selectionStyle == VMSegmentedControlSelectionStyleBox && [self.selectionIndicatorBoxLayer superlayer] == nil)
                        [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                    
                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
            
            // Restore CALayer animations
            self.selectionIndicatorArrowLayer.actions = nil;
            self.selectionIndicatorStripLayer.actions = nil;
            self.selectionIndicatorBoxLayer.actions = nil;
            
            // Animate to new position
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.15f];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [self setArrowFrame];
            self.selectionIndicatorBoxLayer.frame = [self frameForSelectionIndicator];
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            [CATransaction commit];
        } else {
            // Disable CALayer animations
            NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", [NSNull null], @"bounds", nil];
            self.selectionIndicatorArrowLayer.actions = newActions;
            [self setArrowFrame];
            
            self.selectionIndicatorStripLayer.actions = newActions;
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
            
            self.selectionIndicatorBoxLayer.actions = newActions;
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
        }
    }
}

- (void)notifyForSegmentChangeToIndex:(NSInteger)index {
    if (self.superview)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    if (self.indexChangeBlock)
        self.indexChangeBlock(index);
}

@end
