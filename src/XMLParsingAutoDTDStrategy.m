//
//  XMLParsingAutoDTDStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/24/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingAutoDTDStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <libxml/parser.h>
#import <libxml/valid.h>
#import <libxml/xinclude.h>

@implementation XMLParsingAutoDTDStrategy

- (void)parse:(XMLParseCommand *)command {
	//NSLog(@"XMLParsingAutoDTDStrategy parse:");

	xmlDocPtr docPtr	= NULL;
	xmlChar * buffer	= NULL;

	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];
	
	int opts = [self optionsForCommand:command];
	
	[service strategyWillParse:command];
	

	BOOL processXIncludes = [command processXIncludes];
	
	[service strategyWillParseSource:sourceURLString];

	NSDate *start = nil;
	
	if (processXIncludes) {

		start = [NSDate date];
 
		//docPtr = xmlReadFile([sourceURLString UTF8String], NULL, [self optionsForCommand:command]);
		docPtr = xmlReadMemory([sourceXMLData bytes], 
							   [sourceXMLData length], 
							   [sourceURLString UTF8String],
							   "utf-8", 
							   opts);
		
		if (processXIncludes) {
			xmlXIncludeProcess(docPtr);
		}
		
		int size = 0;

		xmlDocDumpMemoryEnc(docPtr, &buffer, &size, "utf-8");
		
		opts = (XML_PARSE_DTDVALID|opts);
		
		xmlReadDoc(buffer, [sourceURLString UTF8String], "utf-8", opts);

	} else {
		
		start = [NSDate date];
		
		opts = (XML_PARSE_DTDVALID|opts);

		//docPtr = xmlReadFile([sourceURLString UTF8String], NULL, [self optionsForCommand:command]);
		docPtr = xmlReadMemory([sourceXMLData bytes], 
							   [sourceXMLData length], 
							   [sourceURLString UTF8String],
							   "utf-8", 
							   opts);
		
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
		
	if (NULL != buffer) {
		free(buffer);
		buffer = NULL;
	}
	if (NULL != docPtr) {
		xmlFreeDoc(docPtr);
		docPtr = NULL;
	}
}

@end
