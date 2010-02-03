//
//  XMLParsingNoneStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingNoneStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <libxml/parser.h>
#import <libxml/valid.h>
#import <libxml/xinclude.h>

@implementation XMLParsingNoneStrategy

- (void)parse:(XMLParseCommand *)command {
	//NSLog(@"XMLParsingNoneStrategy parse:");

	[service strategyWillParse:command];
	
	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];
	
	[service strategyWillParseSource:sourceURLString];
	
	xmlDocPtr docPtr = NULL;
	
	BOOL processXIncludes = [command processXIncludes];
	
	NSDate *start = [NSDate date];
	
	//docPtr = xmlReadFile([sourceURLString UTF8String], NULL, [self optionsForCommand:command]);
	docPtr = xmlReadMemory([sourceXMLData bytes], 
						   [sourceXMLData length], 
						   [sourceURLString UTF8String],
						   "utf-8", 
						   [self optionsForCommand:command]);
	
	if (processXIncludes) {
		xmlXIncludeProcess(docPtr);
	}
	
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];

	if (!docPtr) {
		goto leave;
	}

	xmlChar *mem = NULL;
	int size = 0;
	xmlDocDumpMemoryEnc(docPtr, &mem, &size, "utf-8");
	NSString *XMLString = [[[NSString alloc] initWithBytesNoCopy:mem
														  length:size
														encoding:NSUTF8StringEncoding
													freeWhenDone:NO] autorelease];
	xmlFree((void *)mem);
		
	[service strategyDidParseSource:sourceURLString sourceXMLString:XMLString duration:duration];
	
leave:
	[service strategyDidParse:command];
		
	if (NULL != docPtr) {
		xmlFreeDoc(docPtr);
		docPtr = NULL;
	}
}

@end
