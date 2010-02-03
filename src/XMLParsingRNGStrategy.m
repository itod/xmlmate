//
//  XMLParsingRNGStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/24/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingRNGStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <libxml/parser.h>
#import <libxml/relaxng.h>
#import <libxml/xinclude.h>

@implementation XMLParsingRNGStrategy

- (void)parse:(XMLParseCommand *)command {
	//NSLog(@"XMLParsingXSDStrategy parse:");
	
	xmlRelaxNGParserCtxtPtr parserCtxt	= NULL;
	xmlRelaxNGPtr schemaPtr				= NULL;
	xmlRelaxNGValidCtxtPtr validCtxt	= NULL;
	xmlDocPtr docPtr					= NULL;
	
	[service strategyWillParse:command];
	
	NSString *schemaURLString = [command schemaURLString];
	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];
	
	[service strategyWillParseSchema:schemaURLString];
	
	NSDate *start = [NSDate date];
	
	parserCtxt = xmlRelaxNGNewParserCtxt([schemaURLString UTF8String]);
	
	if (!parserCtxt) {
		goto leave;
	}
	
	schemaPtr = xmlRelaxNGParse(parserCtxt);
	
	if (!schemaPtr) {
		goto leave;
	}
	
	validCtxt = xmlRelaxNGNewValidCtxt(schemaPtr);
	
	if (!validCtxt) {
		goto leave;
	}
	
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	
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
	
	xmlRelaxNGValidateDoc(validCtxt, docPtr);
	
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
	if (NULL != schemaPtr) {
		xmlRelaxNGFree(schemaPtr);
		schemaPtr = NULL;
	}
	if (NULL != validCtxt) {
		xmlRelaxNGFreeValidCtxt(validCtxt);
		validCtxt = NULL;
	}
	if (NULL != parserCtxt) {
		xmlRelaxNGFreeParserCtxt(parserCtxt);
		parserCtxt = NULL;
	}
}

@end
