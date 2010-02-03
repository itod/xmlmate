//
//  XMLParsingStrategy.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSString+libxml2Support.h"
#import "XMLParseCommand.h"

@class XMLParsingServiceLibxmlImpl;

@interface XMLParsingStrategy : NSObject {
	XMLParsingServiceLibxmlImpl *service;
}
- (id)initWithService:(XMLParsingServiceLibxmlImpl *)aService;
- (void)parse:(XMLParseCommand *)command;

- (NSInteger)optionsForCommand:(XMLParseCommand *)command;
- (NSData *)fetchDataForResource:(NSString *)URLString error:(NSError **)err;
@end
