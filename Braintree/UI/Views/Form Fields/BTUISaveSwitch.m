//
//  BTUISaveSwitch.m
//  Braintree
//
//  Created by Amol Chaudhari on 6/26/15.
//
//

#import "BTUISaveSwitch.h"
#import "BTUIFormField_Protected.h"

@interface BTUISaveSwitch ()

@property (nonatomic) UISwitch *saveSwitch;

@end



@implementation BTUISaveSwitch

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.saveSwitch = [[UISwitch alloc]init];
        self.saveSwitch.translatesAutoresizingMaskIntoConstraints = YES;
        self.saveSwitch.frame = CGRectMake(0, 0, 100, 100);
        self.textField.userInteractionEnabled = NO;
        [self.saveSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

        [self addSubview:self.saveSwitch];
        [self setThemedPlaceholder:@"SAVE CARD"];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.saveSwitch
                                                           attribute:NSLayoutAttributeRight
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeLeft multiplier:1
                                                            constant:0]];
    }
    return self;
}

- (void)switchChanged:(id)sender {
    UISwitch *switchButton = (UISwitch *)sender;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:switchButton.on forKey:@"SAVE_CREDIT_CARD"];
    [userDefaults synchronize];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
