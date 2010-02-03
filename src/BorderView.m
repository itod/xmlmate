#import "BorderView.h"

@implementation BorderView

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect]) != nil) {
		self.topColor = [NSColor grayColor];
	}
	return self;
}


- (void)dealloc {
	self.topColor = nil;
	[super dealloc];
}


- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
	[topColor set];
	[NSBezierPath strokeRect:rect];

}

@synthesize topColor;
@end
