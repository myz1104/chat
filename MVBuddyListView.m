//
//  MVBuddyListView.m
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import "MVBuddyListView.h"
#import "MVRoundedTextView.h"
#import "NSEvent+CharacterDetection.h"

static NSGradient *backgroundGradient = nil;

@interface MVBuddyListView () <MVRoundedTextViewDelegate>

@property (strong, readwrite) TUITableView *tableView;
@property (strong, readwrite) TUIView *searchFieldContainerView;
@property (strong, readwrite) TUIView *searchFieldView;
@property (strong, readwrite) MVRoundedTextView *searchField;
@property (readwrite, getter = isSearchFieldVisible) BOOL searchFieldVisible;

@end

@implementation MVBuddyListView

@synthesize tableView = tableView_,
            searchFieldContainerView = searchFieldContainerView_,
            searchFieldView = searchFieldView_,
            searchField = searchField_,
            searchFieldVisible = searchFieldVisible_;

+ (void)initialize
{
  if(!backgroundGradient)
  {
    NSColor *bottomColor = [NSColor colorWithDeviceRed:0.8863
                                                 green:0.9059
                                                  blue:0.9529
                                                 alpha:1.0000];
    NSColor *topColor = [NSColor colorWithDeviceRed:0.9216
                                              green:0.9373
                                               blue:0.9686
                                              alpha:1.0000];
    
    backgroundGradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                       endingColor:topColor];
  }
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    tableView_ = [[TUITableView alloc] initWithFrame:self.bounds
                                               style:TUITableViewStylePlain];
    tableView_.backgroundColor = [TUIColor clearColor];
    tableView_.opaque = NO;
    tableView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                  TUIViewAutoresizingFlexibleHeight;
    tableView_.animateSelectionChanges = NO;
    
//    [self addSubview:tableView_];
    
    searchFieldContainerView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                          self.bounds.size.width,
                                                                          39)];
    
    CGRect searchFieldViewFrame = CGRectMake(0, searchFieldContainerView_.bounds.size.height,
                                             searchFieldContainerView_.bounds.size.width,
                                             searchFieldContainerView_.bounds.size.height);
    searchFieldView_ = [[TUIView alloc] initWithFrame:searchFieldViewFrame];
    searchFieldView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    searchFieldView_.opaque = NO;
    searchFieldView_.backgroundColor = [TUIColor clearColor];
    searchFieldView_.drawRect = ^(TUIView *view, CGRect rect) {
      // bg
      NSColor *bottomColor = [NSColor colorWithDeviceRed:0.9059 green:0.9255 blue:0.9608 alpha:1];
      NSColor *topColor = [NSColor colorWithDeviceRed:0.9647 green:0.9725 blue:0.9843 alpha:1];
      NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                           endingColor:topColor];
      [gradient drawInRect:CGRectMake(0, 2, view.bounds.size.width, 36) angle:90];
      
      // shadow
      bottomColor = [NSColor colorWithDeviceRed:0.6784 green:0.7098 blue:0.7647 alpha:0];
      topColor = [NSColor colorWithDeviceRed:0.6784 green:0.7098 blue:0.7647 alpha:0.82];
      gradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                           endingColor:topColor];
      [gradient drawInRect:CGRectMake(0, 0, view.bounds.size.width, 2) angle:90];
      
      // line
      [[NSColor colorWithDeviceRed:0.6118 green:0.6392 blue:0.6902 alpha:1.0000] set];
      [NSBezierPath fillRect:CGRectMake(0, 2, view.bounds.size.width, 0.5)];
    };
    [searchFieldView_ setNeedsDisplay];
    
    CGRect searchFieldFrame = CGRectMake(4, 6, searchFieldView_.bounds.size.width - 8, 29);
    searchField_ = [[MVRoundedTextView alloc] initWithFrame:searchFieldFrame];
    searchField_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    searchField_.placeholder = @"Search buddy";
    searchField_.delegate = self;
    
    [searchFieldContainerView_ addSubview:searchFieldView_];
    [searchFieldView_ addSubview:searchField_];
    [self addSubview:self.searchFieldContainerView];

    searchFieldVisible_ = NO;
  }
  return self;
}

- (void)setSearchFieldVisible:(BOOL)visible animated:(BOOL)animated
{
  if(self.searchFieldVisible == visible)
    return;
  
  self.searchFieldVisible = visible;
  __block CGRect rect = self.searchFieldView.frame;
  if(self.searchFieldVisible) {
    [TUIView animateWithDuration:0.2 animations:^{
      [TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
      rect.origin.y = 0;
      self.searchFieldView.frame = rect;
    }];
    [self.searchField setEditable:YES];
    [self.searchField makeFirstResponder];
  }
  else {
    [TUIView animateWithDuration:0.2 animations:^{
      [TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
      rect.origin.y = rect.size.height;
      self.searchFieldView.frame = rect;
    } completion:^(BOOL finished) {
      [self.searchField setEditable:NO];
    }];
  }
}

- (void)layoutSubviews
{
  self.searchFieldContainerView.frame = CGRectMake(0, self.bounds.size.height -
                                                   self.searchFieldContainerView.frame.size.height,
                                                   self.bounds.size.width,
                                                   self.searchFieldContainerView.frame.size.height);
}

#pragma mark Drawing Methods

- (void)drawRect:(CGRect)rect
{
  [backgroundGradient drawInRect:self.bounds
                           angle:90];
  
  [[NSColor colorWithDeviceRed:0.9608 green:0.9686 blue:0.9843 alpha:1.0000] set];
  NSRectFill(CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1));
}

#pragma mark Events Handling

- (void)mouseDown:(NSEvent *)theEvent
{
  [self makeFirstResponder];
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)keyDown:(NSEvent *)event
{
  if(event.isDigit || event.isChar)
  {
    [self.searchField setSelectedRange:NSMakeRange(0, self.searchField.text.length)];
    CGPoint location = CGPointMake(10, 5);
    location = [self.searchField convertPoint:location toView:nil];
    location = [self.nsView convertPoint:location toView:nil];
    NSEvent *keyEvent = [NSEvent keyEventWithType:event.type
                                         location:location
                                    modifierFlags:event.modifierFlags
                                        timestamp:event.timestamp
                                     windowNumber:event.windowNumber
                                          context:[NSGraphicsContext currentContext]
                                       characters:event.characters
                      charactersIgnoringModifiers:event.charactersIgnoringModifiers
                                        isARepeat:event.isARepeat
                                          keyCode:event.keyCode];
    [self.nsWindow postEvent:keyEvent atStart:YES];
    [self setSearchFieldVisible:YES animated:YES];
  }
}

#pragma mark MVRoundedTextViewDelegate Methods

- (void)roundedTextViewCancelOperation:(MVRoundedTextView*)roundedTextView
{
  [self setSearchFieldVisible:NO animated:YES];
}

@end