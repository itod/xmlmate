//
//  CatalogItem.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/31/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "CatalogItem.h"

@implementation CatalogItem

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	[self setType:[coder decodeIntForKey:@"type"]];
	[self setOrig:[coder decodeObjectForKey:@"orig"]];
	[self setReplace:[coder decodeObjectForKey:@"replace"]];
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:type forKey:@"type"];
	[coder encodeObject:orig forKey:@"orig"];
	[coder encodeObject:replace forKey:@"replace"];
}


- (void)dealloc {
	[self setOrig:nil];
	[self setReplace:nil];
	[super dealloc];
}

#pragma mark -

- (NSString *)description {
	return [NSString stringWithFormat:@"<CatalogItem { \n\ttype:%d, \n\torig: %@, \n\treplace: %@ }",
		type, orig, replace];
}


#pragma mark -
#pragma mark Accessors

- (NSInteger)type {
	return type;
}


- (void)setType:(NSInteger)newType {
	type = newType;
}


- (NSString *)orig {
	return orig;
}


- (void)setOrig:(NSString *)newStr {
	if (orig != newStr) {
		[orig autorelease];
		orig = [newStr retain];
	}
}


- (NSString *)replace {
	return replace;
}


- (void)setReplace:(NSString *)newStr {
	if (replace != newStr) {
		[replace autorelease];
		replace = [newStr retain];
	}
}

@end
