#import "BTDropInContentView.h"
#import "BTDropInLocalizedString.h"

#import "DTCoreText.h"
#import "DTAttributedTextContentView.h"

@interface BTDropInContentView () <UIGestureRecognizerDelegate, DTAttributedTextContentViewDelegate>
@property (nonatomic, strong) NSArray *verticalLayoutConstraints;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@end

@implementation BTDropInContentView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialize Subviews

    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityView.hidden = YES;
    [self addSubview:self.activityView];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];

    self.summaryView = [[BTUISummaryView alloc] init];

    UIView *summaryBorderBottom = [[UIView alloc] init];
    summaryBorderBottom.backgroundColor = self.theme.borderColor;
    summaryBorderBottom.translatesAutoresizingMaskIntoConstraints = NO;
    [self.summaryView addSubview:summaryBorderBottom];
    [self.summaryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[border]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:@{@"border": summaryBorderBottom}]];
    [self.summaryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[border(==borderWidth)]|"
                                                                             options:0
                                                                             metrics:@{@"borderWidth": @(self.theme.borderWidth)}
                                                                               views:@{@"border": summaryBorderBottom}]];

    self.paymentButton = [[BTPaymentButton alloc] init];

    self.cardFormSectionHeader = [[UILabel alloc] init];

    self.cardForm = [[BTUICardFormView alloc] init];
    [self.cardForm setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

    self.selectedPaymentMethodView = [[BTUIPaymentMethodView alloc] init];

    self.changeSelectedPaymentMethodButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changeSelectedPaymentMethodButton setTitle:BTDropInLocalizedString(DROP_IN_CHANGE_PAYMENT_METHOD_BUTTON_TEXT)
                                            forState:UIControlStateNormal];

    self.ctaControl = [[BTUICTAControl alloc] init];

    self.agreementAttributedLabel = [[DTAttributedLabel alloc] init];

    NSString *htmlString = @"By submitting your order, you agree to our <a href='https://www.teacherspayteachers.com/Terms-of-Service'>Terms of Service</a> and <a href='https://www.teacherspayteachers.com/Privacy-Policy'>Privacy Policy</a>.";
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *options = @{
                              DTUseiOS6Attributes: @YES,
                              DTDefaultFontName: @"SourceSansPro-Light",
                              DTDefaultFontSize: @14,
                              DTDefaultTextColor: [UIColor colorWithWhite:30.0/255.0 alpha:1],
                              DTDefaultLinkColor: [UIColor colorWithRed:16.0/255.0 green:169.0/255.0 blue:108.0/255.0 alpha:1],
                              DTDefaultLinkDecoration: @NO
                              };

    DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:htmlData options:options documentAttributes:nil];

    [self.agreementAttributedLabel setAttributedString:stringBuilder.generatedAttributedString];
    [self.agreementAttributedLabel sizeToFit];
    self.agreementAttributedLabel.layoutFrameHeightIsConstrainedByBounds = NO;
    self.agreementAttributedLabel.delegate = self;
    self.agreementAttributedLabel.backgroundColor = [UIColor clearColor];

    // Add Constraints & Subviews

    // Full-Width Views
    for (UIView *view in @[self.paymentButton, self.selectedPaymentMethodView, self.summaryView, self.ctaControl, self.cardForm]) {
      [self addSubview:view];
      view.translatesAutoresizingMaskIntoConstraints = NO;
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"view": view}]];
    }

    // Not quite full-width views
    for (UIView *view in @[self.cardFormSectionHeader, self.changeSelectedPaymentMethodButton, self.agreementAttributedLabel]) {
      [self addSubview:view];
      view.translatesAutoresizingMaskIntoConstraints = NO;
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(horizontalMargin)-[view]-(horizontalMargin)-|"
                                                                   options:0
                                                                   metrics:@{@"horizontalMargin": @(self.theme.horizontalMargin)}
                                                                     views:@{@"view": view}]];
    }


    self.state = BTDropInContentViewStateForm;

    // Keyboard dismissal when tapping outside text field
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
  }
  return self;
}

- (void)updateConstraints {

  if (self.verticalLayoutConstraints != nil) {
    [self removeConstraints:self.verticalLayoutConstraints];
  }

  NSDictionary *viewBindings = @{
                                 @"activityView": self.activityView,
                                 @"summaryView": self.summaryView,
                                 @"paymentButton": self.paymentButton,
                                 @"cardFormSectionHeader": self.cardFormSectionHeader,
                                 @"cardForm": self.cardForm,
                                 @"ctaControl": self.ctaControl,
                                 @"selectedPaymentMethodView": self.selectedPaymentMethodView,
                                 @"changeSelectedPaymentMethodButton": self.changeSelectedPaymentMethodButton,
                                 @"agreementAttributedLabel": self.agreementAttributedLabel
                                 };

  NSMutableArray *newConstraints = [NSMutableArray array];
  for (NSString *visualFormat in [self evaluateVisualFormat]) {
    [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:viewBindings]];
  }

  if(self.heightConstraint != nil) {
    [self.superview removeConstraint:self.heightConstraint];
  }

  if (self.state != BTDropInContentViewStateForm) {

    self.heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0f
                                                          constant:0];
    [self.superview addConstraint:self.heightConstraint];
  }
  [self.superview setNeedsLayout];

  [self addConstraints:newConstraints];
  self.verticalLayoutConstraints = newConstraints;

  [super updateConstraints];

}
- (void)setHideSummary:(BOOL)hideSummary {
  _hideSummary = hideSummary;
  [self updateLayout];
}

- (void)setHideCTA:(BOOL)hideCTA {
  _hideCTA = hideCTA;
  [self updateLayout];
}

- (void)setState:(BTDropInContentViewStateType)state {
  _state = state;
  [self updateLayout];
}

- (void)setState:(BTDropInContentViewStateType)newState animate:(BOOL)animate {
  if (!animate) {
    [self setState:newState];
  } else {
    BTDropInContentViewStateType oldState = self.state;
    CGFloat duration = 0.2f;
    if (oldState == BTDropInContentViewStateActivity) {
      if (newState == BTDropInContentViewStateForm) {
        [UIView animateWithDuration:duration animations:^{
          self.activityView.alpha = 0.0f;
        } completion:^(__unused BOOL finished) {
          [self setState:newState];
          self.paymentButton.alpha = 0.0f;
          self.cardForm.alpha = 0.0f;
          self.cardFormSectionHeader.alpha = 0.0f;
          self.ctaControl.alpha = 0.0f;
          [self setNeedsUpdateConstraints];
          [self layoutIfNeeded];
          [UIView animateWithDuration:duration animations:^{
            self.paymentButton.alpha = 1.0f;
            self.cardForm.alpha = 1.0f;
            self.cardFormSectionHeader.alpha = 1.0f;
            self.ctaControl.alpha = 1.0f;
          }];
        }];
        return;
      }

      if (newState == BTDropInContentViewStatePaymentMethodsOnFile) {
        self.activityView.alpha = 1.0f;
        [UIView animateWithDuration:duration animations:^{
          self.activityView.alpha = 0.0f;
        } completion:^(__unused BOOL finished) {
          [self setState:newState];
          self.selectedPaymentMethodView.alpha = 0.0f;
          self.changeSelectedPaymentMethodButton.alpha = 0.0f;
          self.ctaControl.alpha = 0.0f;
          [self setNeedsUpdateConstraints];
          [self layoutIfNeeded];
          [UIView animateWithDuration:duration animations:^{
            self.selectedPaymentMethodView.alpha = 1.0f;
            self.changeSelectedPaymentMethodButton.alpha = 1.0f;
            self.ctaControl.alpha = 1.0f;
          }];
        }];
        return;
      }
    }
    [self setState:newState];
  }
}

- (void)setHidePaymentButton:(BOOL)hidePaymentButton {
  _hidePaymentButton = hidePaymentButton;
  self.paymentButton.hidden = hidePaymentButton;
  [self updateLayout];
}

- (void)updateLayout {

  // Reset all to hidden, just for clarity
  self.activityView.hidden = YES;
  self.summaryView.hidden = self.hideSummary;
  self.paymentButton.hidden = YES;
  self.cardFormSectionHeader.hidden = YES;
  self.cardForm.hidden = YES;
  self.selectedPaymentMethodView.hidden = YES;
  self.changeSelectedPaymentMethodButton.hidden = YES;
  self.ctaControl.hidden = YES;
  self.agreementAttributedLabel.hidden = YES;

  switch (self.state) {
    case BTDropInContentViewStateForm:
      self.activityView.hidden = YES;
      [self.activityView stopAnimating];
      self.ctaControl.hidden = self.hideCTA;
      self.agreementAttributedLabel.hidden = self.hideCTA;
      self.paymentButton.hidden = self.hidePaymentButton;
      self.cardFormSectionHeader.hidden = NO;
      self.cardForm.hidden = NO;
      break;
    case BTDropInContentViewStatePaymentMethodsOnFile:
      self.activityView.hidden = YES;
      [self.activityView stopAnimating];
      self.ctaControl.hidden = self.hideCTA;
      self.agreementAttributedLabel.hidden = self.hideCTA;
      self.selectedPaymentMethodView.hidden = NO;
      self.changeSelectedPaymentMethodButton.hidden = NO;
      break;
    case BTDropInContentViewStateActivity:
      self.activityView.hidden = NO;
      self.activityView.alpha = 1.0f;
      [self.activityView startAnimating];
      break;
    default:
      break;
  }
  [self setNeedsUpdateConstraints];
}


#pragma mark Tap Gesture Delegate

- (BOOL)gestureRecognizer:(__unused UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  // Disallow recognition of tap gestures on UIControls (like, say, buttons)
  if ([touch.view isKindOfClass:[UIControl class]] || [touch.view isDescendantOfView:self.paymentButton]) {
    return NO;
  }
  return YES;
}


- (void)tapped {
  [self.cardForm endEditing:YES];
}

- (NSArray*) evaluateVisualFormat{
  NSString *summaryViewVisualFormat = self.summaryView.hidden ? @"" : @"[summaryView(>=60)]";
  NSString *ctaControlVisualFormat = self.ctaControl.hidden ? @"" : @"[agreementAttributedLabel(==100)]-[ctaControl(==50)]";

  if (self.state == BTDropInContentViewStateActivity) {
    return @[[NSString stringWithFormat:@"V:|%@-(40)-[activityView]-(>=40)-%@|", summaryViewVisualFormat, ctaControlVisualFormat]];

  } else if (self.state != BTDropInContentViewStatePaymentMethodsOnFile) {
    if (!self.ctaControl.hidden) {
      ctaControlVisualFormat = [NSString stringWithFormat:@"-(15)-%@-(>=0)-", ctaControlVisualFormat];
    }
    if (self.hidePaymentButton){
      return @[[NSString stringWithFormat:@"V:|%@-(35)-[cardFormSectionHeader]-(7)-[cardForm]%@|", summaryViewVisualFormat, ctaControlVisualFormat]];
    } else {
      summaryViewVisualFormat = [NSString stringWithFormat:@"%@-(35)-", summaryViewVisualFormat];
      return @[[NSString stringWithFormat:@"V:|%@[paymentButton(==44)]-(18)-[cardFormSectionHeader]-(7)-[cardForm]%@|", summaryViewVisualFormat, ctaControlVisualFormat]];
    }

  } else {
    NSString *primaryLayout = [NSString stringWithFormat:@"V:|%@-(15)-[selectedPaymentMethodView(==45)]-(15)-[changeSelectedPaymentMethodButton]-(>=15)-%@|", summaryViewVisualFormat, ctaControlVisualFormat];
    NSMutableArray *visualLayouts = [NSMutableArray arrayWithObject:primaryLayout];
    if (!self.ctaControl.hidden) {
      [visualLayouts addObject:@"V:[ctaControl]|"];
    }
    return visualLayouts;
  }
}

#pragma mark DTAttributedTextContentViewDelegate

- (UIView *)attributedTextContentView: (DTAttributedTextContentView *)attributedTextContentView viewForLink: (NSURL *)url identifier: (NSString *)identifier frame:(CGRect)frame {
  DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
  button.URL = url;
  button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
  button.GUID = identifier;

  [button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];

  return button;
}

- (void)linkPushed: (DTLinkButton*)button {
  NSString *url = button.URL.absoluteString;
  if (self.userDidTapAgreementLink) {
    self.userDidTapAgreementLink(url);
  }
}

@end
