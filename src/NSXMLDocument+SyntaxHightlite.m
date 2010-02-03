//
//  NSXMLDocument+SyntaxHighlite.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/6/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "NSXMLDocument+SyntaxHighlite.h"

@interface NSXMLNode (SyntaxHighlitePrivate)
- (void)setSelectionAttributes:(NSMutableDictionary *)attrs;
- (void)setNonSelectionAttributes:(NSMutableDictionary *)attrs;
@end


static NSNumber *selectionExpansionStyle() {
	return [NSNumber numberWithFloat:.2];
}


static NSNumber *nonSelectionExpansionStyle() {
	return [NSNumber numberWithFloat:0.];
}


static NSNumber *selectionUnderlineStyle() {
	return [NSNumber numberWithInt:(NSUnderlinePatternSolid|NSUnderlineStyleSingle)];
}


static NSNumber *nonSelectionUnderlineStyle() {
	return [NSNumber numberWithInt:NSUnderlineStyleNone];
}


static NSColor *selectionUnderlineColor() {
	return [NSColor blackColor];
}


static NSColor *selectionBackgroundColor() {
	return [NSColor yellowColor];
}


static NSColor *nonSelectionBackgroundColor() {
	return [NSColor whiteColor];
}


static NSColor *elementNameColor() {
	return [NSColor purpleColor];
}


static NSColor *angleBracketColor() {
	return [NSColor blackColor];
}


static NSColor *attributeNameColor() {
	return [NSColor blackColor];
}


static NSColor *quoteSymbolColor() {
	return [NSColor blueColor];
}


static NSColor *equalSymbolColor() {
	return [NSColor blackColor];
}


static NSColor *attributeValueColor() {
	return [NSColor blueColor];
}


@implementation NSXMLDocument (SyntaxHighlite)

- (NSAttributedString *)highlitedAttributedStringWithSelectedXPaths:(NSArray *)xpaths {
	NSMutableAttributedString *res = [[[NSMutableAttributedString alloc] init] autorelease];
	
	NSArray *kids = [self children];
	NSEnumerator *e = [kids objectEnumerator];
	NSXMLNode *kid = nil;
	
	while (kid = [e nextObject]) {
		[res appendAttributedString:[kid highlitedAttributedStringWithSelectedXPaths:xpaths]];
	}
	
	return res;
}

@end

@implementation NSXMLElement (SyntaxHighlite)

- (NSString *)startTagXMLString {
	//NSString *XMLString = [self XMLStringWithOptions:NSXMLNodePreserveAll];
	NSString *XMLString = [self description];
	NSRange r = [XMLString rangeOfString:@">"];
	int i = r.location;
	return [XMLString substringToIndex:i+1];
}


- (NSString *)endTagXMLString {
	//NSString *XMLString = [self XMLStringWithOptions:NSXMLNodePreserveAll];
	NSString *XMLString = [self description];
	NSRange r = [XMLString rangeOfString:@"<" options:NSBackwardsSearch];
	int i = r.location;
	if (NSNotFound == i) {
		return nil;
	}
	
	r = [XMLString rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]
								   options:NSBackwardsSearch
									 range:NSMakeRange(0, i)];

	i = r.location;
	if (NSNotFound == i) {
		return nil;
	}
		
	i += 1;
	r = NSMakeRange(i, [XMLString length] - i);
	return [XMLString substringWithRange:r];
}


- (BOOL)isDecorated {
	NSCharacterSet *quoteCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
	return NSNotFound != [[self startTagXMLString] rangeOfCharacterFromSet:quoteCharacterSet].location;
}


- (BOOL)isEmpty {
	return NO;
	NSScanner *scanner = [NSScanner scannerWithString:[self startTagXMLString]];
	NSString *tmp = nil;
	// scanner removes whitespace by default
	[scanner scanUpToString:@">" intoString:&tmp];
	// so if this element is empty, fwd slash will be last char in tmp
	NSRange r = [tmp rangeOfString:@"/"];
	return r.location == [tmp length] - 1;
}


- (NSAttributedString *)highlitedAttributedStringWithSelectedXPaths:(NSArray *)xpaths {
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:6];
	[attrs setObject:[NSFont fontWithName:@"Monaco" size:9.] forKey:NSFontAttributeName];
	[attrs setObject:[NSColor whiteColor] forKey:NSBackgroundColorAttributeName];

	NSMutableAttributedString *res = [[[NSMutableAttributedString alloc] init] autorelease];

	NSCharacterSet *angleBracketCharacterSet	= [NSCharacterSet characterSetWithCharactersInString:@"</>"];
	NSCharacterSet *notAngleBracketCharacterSet	= [angleBracketCharacterSet invertedSet];
	NSCharacterSet *greaterThanCharacterSet		= [NSCharacterSet characterSetWithCharactersInString:@">/"];
	NSCharacterSet *notGreaterThanCharacterSet	= [greaterThanCharacterSet invertedSet];
	
	// do start tag
	NSScanner *scanner = [NSScanner scannerWithString:[self startTagXMLString]];
	[scanner setCharactersToBeSkipped:nil];
	NSString *tmp = nil;
	
	if ([scanner scanUpToString:@"<" intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	if ([scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&tmp]) {
		[attrs setObject:angleBracketColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	BOOL isSelected = [xpaths containsObject:[self XPath]];

	if ([self isDecorated]) {
		// do attrs and namespace decls
		
		if ([scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&tmp]) {
			[attrs setObject:angleBracketColor() forKey:NSForegroundColorAttributeName];
			//??
			//[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
		}
		
		if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&tmp]) {
			[attrs setObject:elementNameColor() forKey:NSForegroundColorAttributeName];
			if (isSelected) {
				[self setSelectionAttributes:attrs];
			}
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
			if (isSelected) {
				[self setNonSelectionAttributes:attrs];
			}
		}
		
		NSArray *nsNodes = [self namespaces];
		NSXMLNode *node = nil;
		NSEnumerator *e = [nsNodes objectEnumerator];
		while (node = [e nextObject]) {
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:@" " attributes:attrs] autorelease]];			
			[res appendAttributedString:[node highlitedAttributedStringForAttributeWithSelectedXPaths:xpaths]];
		}
		
		NSArray *attrNodes = [self attributes];
		e = [attrNodes objectEnumerator];
		while (node = [e nextObject]) {
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:@" " attributes:attrs] autorelease]];			
			[res appendAttributedString:[node highlitedAttributedStringForAttributeWithSelectedXPaths:xpaths]];
		}

		[scanner scanUpToString:@">" intoString:nil];
		
	} else {
		
		if ([scanner scanUpToCharactersFromSet:greaterThanCharacterSet intoString:&tmp]) {
			[attrs setObject:elementNameColor() forKey:NSForegroundColorAttributeName];
			if (isSelected) {
				[self setSelectionAttributes:attrs];
			}
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
			if (isSelected) {
				[self setNonSelectionAttributes:attrs];
			}
		}
		
	}
	
	if ([scanner scanUpToCharactersFromSet:notGreaterThanCharacterSet intoString:&tmp]) {
		[attrs setObject:angleBracketColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}

	// do child stuff
	NSArray *kids = [self children];
	NSEnumerator *e = [kids objectEnumerator];
	NSXMLNode *kid = nil;
	while (kid = [e nextObject]) {
		[res appendAttributedString:[kid highlitedAttributedStringWithSelectedXPaths:xpaths]];
	}	

	if (![self isEmpty]) {
		
		// do end tag
		scanner = [NSScanner scannerWithString:[self endTagXMLString]];
		[scanner setCharactersToBeSkipped:nil];
		
		// closing whitespace... not sure why NSXML puts this here, but it does
		if ([scanner scanUpToCharactersFromSet:angleBracketCharacterSet intoString:&tmp]) {
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
		}
		
		if ([scanner scanUpToCharactersFromSet:notAngleBracketCharacterSet intoString:&tmp]) {
			[attrs setObject:angleBracketColor() forKey:NSForegroundColorAttributeName];
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
		}
		
		if ([scanner scanUpToCharactersFromSet:angleBracketCharacterSet intoString:&tmp]) {
			[attrs setObject:elementNameColor() forKey:NSForegroundColorAttributeName];
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
		}
		
		if ([scanner scanUpToCharactersFromSet:notAngleBracketCharacterSet intoString:&tmp]) {
			[attrs setObject:angleBracketColor() forKey:NSForegroundColorAttributeName];
			[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
		}
		
	}
	
	if ([scanner scanUpToString:@"" intoString:&tmp]) {
		[attrs setObject:angleBracketColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	return res;
}

@end

@implementation NSXMLDTD (SyntaxHighlite)

- (NSAttributedString *)highlitedAttributedStringWithSelectedXPaths:(NSArray *)xpaths {
	//NSString *XMLString = [self XMLStringWithOptions:NSXMLNodePreserveAll];
	NSString *XMLString = [self description];
	
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor purpleColor], NSForegroundColorAttributeName,
		[NSFont fontWithName:@"Monaco" size:9.], NSFontAttributeName,
		nil];
	
	
	NSAttributedString *res = [[[NSAttributedString alloc] initWithString:XMLString attributes:attrs] autorelease];
	return res;
}

@end

@implementation NSXMLNode (SyntaxHighlite)

- (NSAttributedString *)highlitedAttributedStringForAttributeWithSelectedXPaths:(NSArray *)xpaths {	
	NSMutableAttributedString *res = [[[NSMutableAttributedString alloc] init] autorelease];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:6];
	
	[attrs setObject:[NSFont fontWithName:@"Monaco" size:9.] forKey:NSFontAttributeName];
	[attrs setObject:[NSColor whiteColor] forKey:NSBackgroundColorAttributeName];
	
	//NSScanner *scanner = [NSScanner scannerWithString:[self XMLStringWithOptions:NSXMLNodePreserveAll]];
	NSScanner *scanner = [NSScanner scannerWithString:[self description]];
	[scanner setCharactersToBeSkipped:nil];
	NSString *tmp = nil;
	
	NSCharacterSet *quoteCharacterSet	 = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
	NSCharacterSet *notQuoteCharacterSet = [quoteCharacterSet invertedSet];	
	
	BOOL isSelected = [xpaths containsObject:[self XPath]];
	
	if (isSelected) {
		[self setSelectionAttributes:attrs];
	}
	
	if ([scanner scanUpToString:@"=" intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
		[attrs setObject:attributeNameColor() forKey:NSForegroundColorAttributeName];
	}

	if (isSelected) {
		[self setNonSelectionAttributes:attrs];
	}
	
	if ([scanner scanUpToCharactersFromSet:quoteCharacterSet intoString:&tmp]) {
		[attrs setObject:equalSymbolColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}

	NSRange r = NSMakeRange([scanner scanLocation], 1);
	NSString *quoteChar = [[scanner string] substringWithRange:r];

	if ([scanner scanUpToCharactersFromSet:notQuoteCharacterSet intoString:&tmp]) {
		[attrs setObject:quoteSymbolColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}

	if ([scanner scanUpToString:quoteChar intoString:&tmp]) {
		[attrs setObject:attributeValueColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}

	if ([scanner scanUpToCharactersFromSet:notQuoteCharacterSet intoString:&tmp]) {
		[attrs setObject:quoteSymbolColor() forKey:NSForegroundColorAttributeName];
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}		

	return res;
}


- (NSAttributedString *)highlitedAttributedStringForPIWithSelectedXPaths:(NSArray *)xpaths {	
	NSMutableAttributedString *res = [[[NSMutableAttributedString alloc] init] autorelease];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:6];

	NSColor *color = [NSColor colorWithCalibratedRed:0. green:137. blue:147. alpha:1.];
	[attrs setObject:color forKey:NSForegroundColorAttributeName];
	[attrs setObject:[NSFont fontWithName:@"Monaco" size:9.] forKey:NSFontAttributeName];
	[attrs setObject:[NSColor whiteColor] forKey:NSBackgroundColorAttributeName];
	
	//NSScanner *scanner = [NSScanner scannerWithString:[self XMLStringWithOptions:NSXMLNodePreserveAll]];
	NSScanner *scanner = [NSScanner scannerWithString:[self description]];
	[scanner setCharactersToBeSkipped:nil];
	NSString *tmp = nil;
	
	NSCharacterSet *startSet = [NSCharacterSet characterSetWithCharactersInString:@"<?"];
	
	if ([scanner scanUpToCharactersFromSet:startSet intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	if ([scanner scanUpToCharactersFromSet:[startSet invertedSet] intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	BOOL isSelected = [xpaths containsObject:[self XPath]];
	
	if (isSelected) {
		[self setSelectionAttributes:attrs];
	}
	
	if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}	
	
	if (isSelected) {
		[self setNonSelectionAttributes:attrs];
	}
	
	if ([scanner scanUpToString:@"" intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}	
	
	return res;
}


- (NSAttributedString *)highlitedAttributedStringForCommentWithSelectedXPaths:(NSArray *)xpaths {
	NSMutableAttributedString *res = [[[NSMutableAttributedString alloc] init] autorelease];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:6];
	[attrs setObject:[NSFont fontWithName:@"Monaco" size:9.] forKey:NSFontAttributeName];
	[attrs setObject:[NSColor whiteColor] forKey:NSBackgroundColorAttributeName];
	
	//NSScanner *scanner = [NSScanner scannerWithString:[self XMLStringWithOptions:NSXMLNodePreserveAll]];
	NSScanner *scanner = [NSScanner scannerWithString:[self description]];
	[scanner setCharactersToBeSkipped:nil];
	NSString *tmp = nil;
	
	NSCharacterSet *startSet = [NSCharacterSet characterSetWithCharactersInString:@"<!--"];
	
	if ([scanner scanUpToCharactersFromSet:startSet intoString:&tmp]){
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	if ([scanner scanUpToCharactersFromSet:[startSet invertedSet] intoString:&tmp]){
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}
	
	
	BOOL isSelected = [xpaths containsObject:[self XPath]];
	
	if (isSelected) {
		[self setSelectionAttributes:attrs];
	}
	
	if ([scanner scanUpToString:@"--" intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}	
	
	if (isSelected) {
		[self setNonSelectionAttributes:attrs];
	}
	
	if ([scanner scanUpToString:@"" intoString:&tmp]) {
		[res appendAttributedString:[[[NSAttributedString alloc] initWithString:tmp attributes:attrs] autorelease]];
	}	
	
	return res;
}


- (NSAttributedString *)highlitedAttributedStringForTextWithSelectedXPaths:(NSArray *)xpaths {
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:6];
	
	[attrs setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[attrs setObject:[NSFont fontWithName:@"Monaco" size:9.] forKey:NSFontAttributeName];
	
	BOOL isSelected = [xpaths containsObject:[self XPath]];
	
	
	if (isSelected) {
		[self setSelectionAttributes:attrs];
	} else {
		[self setNonSelectionAttributes:attrs];
	}
	
	//NSAttributedString *res = [[[NSAttributedString alloc] initWithString:[self XMLStringWithOptions:NSXMLNodePreserveAll]
	NSAttributedString *res = [[[NSAttributedString alloc] initWithString:[self description] attributes:attrs] autorelease];
	return res;
}


- (NSAttributedString *)highlitedAttributedStringWithSelectedXPaths:(NSArray *)xpaths {
	NSAttributedString *res	= nil;
	
	switch ([self kind]) {
		case NSXMLCommentKind:
			res = [self highlitedAttributedStringForCommentWithSelectedXPaths:xpaths];
			break;
		case NSXMLProcessingInstructionKind:
			res = [self highlitedAttributedStringForPIWithSelectedXPaths:xpaths];
			break;
		case NSXMLDTDKind:
		case NSXMLEntityDeclarationKind:
		case NSXMLAttributeDeclarationKind:
		case NSXMLElementDeclarationKind:
		case NSXMLNotationDeclarationKind:
		case NSXMLTextKind:
			res = [self highlitedAttributedStringForTextWithSelectedXPaths:xpaths];
			break;
	}
	
	if (!res) {
		//NSString *XMLString = [self XMLStringWithOptions:NSXMLNodePreserveAll];
		NSString *XMLString = [self description];
		
		NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSColor redColor], NSForegroundColorAttributeName,
			[NSFont fontWithName:@"Monaco" size:9.], NSFontAttributeName,
			nil];
		
		if ([xpaths containsObject:[self XPath]]) {
			[self setSelectionAttributes:attrs];
		}
		
		res = [[[NSAttributedString alloc] initWithString:XMLString attributes:attrs] autorelease];
	}
	
	return res;
}


- (void)setSelectionAttributes:(NSMutableDictionary *)attrs {
	[attrs setObject:selectionBackgroundColor() forKey:NSBackgroundColorAttributeName];
	[attrs setObject:selectionUnderlineColor() forKey:NSUnderlineColorAttributeName];
	[attrs setObject:selectionUnderlineStyle() forKey:NSUnderlineStyleAttributeName];
	[attrs setObject:selectionExpansionStyle() forKey:NSExpansionAttributeName];
}


- (void)setNonSelectionAttributes:(NSMutableDictionary *)attrs {
	[attrs setObject:nonSelectionBackgroundColor() forKey:NSBackgroundColorAttributeName];
	[attrs setObject:nonSelectionUnderlineStyle() forKey:NSUnderlineStyleAttributeName];
	[attrs setObject:nonSelectionExpansionStyle() forKey:NSExpansionAttributeName];
}

@end
