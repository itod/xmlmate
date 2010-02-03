//
//  XMLParsingServiceLibxmlImpl.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMLParsingService.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <libxml/parser.h>
#import <libxml/xmlerror.h>

void myGenericErrorHandler(id self, const char *msg, ...);

@class XMLParsingStrategy;

@interface XMLParsingServiceLibxmlImpl : NSObject <XMLParsingService> {
	id delegate;
	XMLParsingStrategy *strategy;
}

@end

@interface XMLParsingServiceLibxmlImpl (StrategyCallbacks)
- (void)strategyWillParse:(XMLParseCommand *)command;
- (void)strategyDidParse:(XMLParseCommand *)command;
- (void)strategyWillFetchSchema:(NSString *)schemaURLString;
- (void)strategyDidFetchSchema:(NSString *)schemaURLString duration:(NSTimeInterval)duration;
- (void)strategyWillParseSchema:(NSString *)schemaURLString;
- (void)strategyDidParseSchema:(NSString *)schemaURLString duration:(NSTimeInterval)duration;
- (void)strategyWillFetchSource:(NSString *)sourceURLString;
- (void)strategyDidFetchSource:(NSString *)sourceURLString duration:(NSTimeInterval)duration;
- (void)strategyWillParseSource:(NSString *)sourceURLString;
- (void)strategyDidParseSource:(NSString *)sourceURLString sourceXMLString:(NSString *)XMLString duration:(NSTimeInterval)duration;
- (void)strategyAssertFired:(NSDictionary *)info;
- (void)strategyReportFired:(NSDictionary *)info;
@end

