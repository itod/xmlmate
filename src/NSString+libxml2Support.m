//
//  NSString+libxml2Support.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "NSString+libxml2Support.h"
#import <libxml/xmlstring.h>

@implementation NSString (libxml2Support)

+ (id)stringWithXmlChar:(const xmlChar *)xc {
	return [NSString stringWithUTF8String:(char *)xc];
}


- (const xmlChar *)xmlChar {
	return (const unsigned char *)[self UTF8String];
}


- (NSString *)stringByRemovingCurlyBraces {
	if ([self hasPrefix:@"{"]) {
		NSRange r = NSMakeRange(1, [self length]-2);
		return [self substringWithRange:r];
	} else {
		return self;
	}
}

@end

