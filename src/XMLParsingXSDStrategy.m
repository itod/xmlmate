//
//  XMLParsingXSDStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/24/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingXSDStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <libxml/parser.h>
#import <libxml/xmlschemas.h>
#import <libxml/xinclude.h>

@implementation XMLParsingXSDStrategy

- (void)parse:(XMLParseCommand *)command {
	//NSLog(@"XMLParsingXSDStrategy parse:");
	
	xmlSchemaParserCtxtPtr parserCtxt	= NULL;
	xmlSchemaPtr schemaPtr				= NULL;
	xmlSchemaValidCtxtPtr validCtxt		= NULL;
	xmlDocPtr docPtr					= NULL;
	
	[service strategyWillParse:command];
	
	NSString *schemaURLString = [command schemaURLString];
	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];
	
	[service strategyWillParseSchema:schemaURLString];

	NSDate *start = [NSDate date];

	parserCtxt = xmlSchemaNewParserCtxt([schemaURLString UTF8String]);
	
	if (!parserCtxt) {
		goto leave;
	}
	
	@try {
		schemaPtr = xmlSchemaParse(parserCtxt);
	} @catch (NSException *e) {
		goto leave;
	}
		
	if (!schemaPtr) {
		goto leave;
	}
	
	validCtxt = xmlSchemaNewValidCtxt(schemaPtr);
	
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
	
	xmlSchemaValidateDoc(validCtxt, docPtr);
	
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
		xmlSchemaFree(schemaPtr);
		schemaPtr = NULL;
	}
	if (NULL != validCtxt) {
		xmlSchemaFreeValidCtxt(validCtxt);
		validCtxt = NULL;
	}
	if (NULL != parserCtxt) {
		xmlSchemaFreeParserCtxt(parserCtxt);
		parserCtxt = NULL;
	}
}

@end
