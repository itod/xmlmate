//
//  XMLParsingUserSelectedDTDStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingUserSelectedDTDStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <libxml/parser.h>
#import <libxml/valid.h>
#import <libxml/xinclude.h>

@implementation XMLParsingUserSelectedDTDStrategy

- (void)parse:(XMLParseCommand *)command {
	//NSLog(@"XMLParsingUserSelectedDTDStrategy parse:");

	xmlValidCtxtPtr validCtxt	= NULL;
	xmlDtdPtr dtdPtr			= NULL;
	xmlDocPtr docPtr			= NULL;
	
	[service strategyWillParse:command];
	
	NSString *schemaURLString = [command schemaURLString];
	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];

	validCtxt = xmlNewValidCtxt();
	
	if (!validCtxt) {
		goto leave;
	}
		
	[service strategyWillParseSchema:schemaURLString];
	
	NSDate *start = [NSDate date];
	
	dtdPtr = xmlParseDTD(NULL, [schemaURLString xmlChar]);
	
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	
	if (!dtdPtr) {
		goto leave;
	}
	
	[service strategyDidParseSchema:schemaURLString duration:duration];
	
	[service strategyWillParseSource:sourceURLString];
	
	BOOL processXIncludes = [command processXIncludes];
	
	start = [NSDate date];
	
	//docPtr = xmlReadFile([sourceURLString UTF8String], NULL, [self optionsForCommand:command]);
	docPtr = xmlReadMemory([sourceXMLData bytes], 
						   [sourceXMLData length], 
						   [sourceURLString UTF8String],
						   "utf-8",
						   [self optionsForCommand:command]);
	
	if (processXIncludes) {
		xmlXIncludeProcess(docPtr);
	}
	
	duration = [[NSDate date] timeIntervalSinceDate:start];
	
	if (!docPtr) {
		goto leave;
	}

	xmlValidateDtd(validCtxt, docPtr, dtdPtr);

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
	if (NULL != dtdPtr) {
		xmlFreeDtd(dtdPtr);
		dtdPtr = NULL;
	}
	if (NULL != validCtxt) {
		xmlFreeValidCtxt(validCtxt);
		validCtxt = NULL;
	}
}

@end
