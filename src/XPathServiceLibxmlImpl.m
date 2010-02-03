//
//  XPathServiceLibxmlImpl.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/3/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "XPathServiceLibxmlImpl.h"
#import "XMLParseCommand.h"
#import "NSString+libxml2Support.h"
#import "NSXMLDocument+SyntaxHighlite.h"
#import <libxml/parser.h>
#import <libxml/xinclude.h>
#import <libxml/xpath.h>

@interface XPathServiceLibxmlImpl (Private)
- (void)doExecuteQuery:(NSArray *)args;
- (NSInteger)optionsForCommand:(XMLParseCommand *)command;
- (id)resultsForExpr:(NSString *)xpathExr XMLString:(NSString *)XMLString error:(NSError **)err;
- (NSAttributedString *)attributedStringFromError:(NSError *)err;
- (void)success:(id)sequence;
- (void)doSuccess:(id)sequence;
- (void)error:(id)errInfo;
- (void)doError:(id)errInfo;
- (void)parseError:(id)errInfo;
- (void)doParseError:(id)errInfo;
@end

@implementation XPathServiceLibxmlImpl

- (id)initWithDelegate:(id)d {
	self = [super init];
	if (self != nil) {
		delegate = d;
	}
	return self;
}


- (void)dealloc {
    delegate = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark XPathService

- (void)executeQuery:(NSString *)XPathString withCommand:(XMLParseCommand *)c {
	NSArray *args = [NSArray arrayWithObjects:XPathString, c, nil];
	[NSThread detachNewThreadSelector:@selector(doExecuteQuery:) toTarget:self withObject:args];
}


#pragma mark -
#pragma mark Private 

static BOOL terminated;

static void switchToParseTabStructuredHandler(id self, xmlErrorPtr error) {
	if (!terminated) {
		terminated = YES;
		[self parseError:nil];
	}
}


- (void)doExecuteQuery:(NSArray *)args {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	terminated = NO;
	
	xmlDocPtr docPtr = NULL;
	xmlXPathContextPtr xpathCtxt = NULL;
	xmlXPathObjectPtr xpathObj = NULL;
	
	xmlSetStructuredErrorFunc((void *)self, (xmlStructuredErrorFunc)switchToParseTabStructuredHandler);

	NSString *xpathExpr = [args objectAtIndex:0];
	XMLParseCommand *command = [args objectAtIndex:1];
	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];
			
	docPtr = xmlReadMemory([sourceXMLData bytes], 
						   [sourceXMLData length], 
						   [sourceURLString UTF8String],
						   NULL, 
						   [self optionsForCommand:command]);
	
	if ([command processXIncludes]) {
		xmlXIncludeProcess(docPtr);
	}
		
	if (!docPtr) {
		goto leave;
	}
/*	
	xpathCtxt = xmlXPathNewContext(docPtr);
	
	if (!xpathCtxt) {
		goto leave;
	}
	
	// TODO consider xmlXPathEval() instead for location path-only evaling
	xpathObj = xmlXPathEvalExpression([xpathExpr xmlChar], xpathCtxt);
	
	
	NSLog(@"xpathObj->stringval: %s", xpathObj->stringval);
	NSLog(@"xpathObj->type: %d", xpathObj->type);
	
	xmlNodeSetPtr nodeSet = xpathObj->nodesetval;
	NSLog(@"nodeSet->nodeNr: %d", nodeSet->nodeNr);
	
	NSMutableArray *lineArray = [NSMutableArray arrayWithCapacity:nodeSet->nodeNr];
	xmlNodePtr node;
	for (int i = 0; i < nodeSet->nodeNr; i++) {
		node = nodeSet->nodeTab[i];
		[lineArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:node->line], @"line",
			[NSString stringWithXmlChar:node->name], @"name",
			nil]];
	}
 */	
	
	xmlChar *docTxtPtr = NULL;
	int docTxtLen = 0;
	xmlDocDumpMemoryEnc(docPtr, &docTxtPtr, &docTxtLen, "utf-8");
	NSString *XMLString = [[[NSString alloc] initWithBytesNoCopy:docTxtPtr
														  length:docTxtLen
														encoding:NSUTF8StringEncoding
													freeWhenDone:NO] autorelease];
	xmlFree((void *)docTxtPtr);
	
	NSError *err = nil;
	id results = [self resultsForExpr:xpathExpr XMLString:XMLString error:&err];
		
	if (err) {
		[self error:[self attributedStringFromError:err]];
		goto leave;
	}
	
	[self success:results];

leave:	

	if (NULL != xpathObj) {
		xmlXPathFreeObject(xpathObj);
		xpathObj = NULL;
	}
	if (NULL != xpathCtxt) {
		xmlXPathFreeContext(xpathCtxt);
		xpathCtxt = NULL;
	}
	if (NULL != docPtr) {
		xmlFreeDoc(docPtr);
		docPtr = NULL;
	}

	[pool release];
}


- (NSInteger)optionsForCommand:(XMLParseCommand *)command {
	int opts = 0; //XML_PARSE_PEDANTIC;
	
	if ([command loadDTD])
		opts = (opts|XML_PARSE_DTDLOAD);
	
	if ([command defaultDTDAttributes])
		opts = (opts|XML_PARSE_DTDATTR);
	
	if ([command substituteEntities])
		opts = (opts|XML_PARSE_NOENT);
	
	if ([command mergeCDATA])
		opts = (opts|XML_PARSE_NOCDATA);
	
	return opts;
}


- (id)resultsForExpr:(NSString *)xpathExpr XMLString:(NSString *)XMLString error:(NSError **)outError {
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:XMLString options:NSXMLNodePreserveAll error:outError] autorelease];
	
	//	NSArray *nodes = [doc nodesForXPath:xpathExpr error:err];
	NSArray *nodes = [doc objectsForXQuery:xpathExpr error:outError];
    
	if (*outError) {
		return nil;
	}
	
	NSMutableArray *xpaths = [NSMutableArray arrayWithCapacity:[nodes count]];
	NSEnumerator *e = [nodes objectEnumerator];
	id node = nil;
	NSString *xpath = nil;
	while (node = [e nextObject]) {
		if ([node respondsToSelector:@selector(XPath)]) {
			xpath = [node XPath];
			if (xpath) {
				[xpaths addObject:xpath];
			}
		}
	}
	
	NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
		xpaths, @"xpaths",
		nodes, @"nodes",
		[doc highlitedAttributedStringWithSelectedXPaths:xpaths], @"highlitedAttributedString",
		nil];
	
	return result;
}


- (NSAttributedString *)attributedStringFromError:(NSError *)err {
	//NSColor *color = [NSColor colorWithDeviceRed:255. green:15. blue:0. alpha:1.];
	NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	NSAttributedString *res = [[NSAttributedString alloc] initWithString:[err localizedDescription] attributes:attrs];
	return [res autorelease];
}


- (void)success:(id)sequence {
	if (terminated) return;
	[self performSelectorOnMainThread:@selector(doSuccess:) withObject:sequence waitUntilDone:NO];
}


- (void)doSuccess:(id)sequence {
	[delegate xpathService:self didFinish:sequence];
}


- (void)error:(id)errInfo {
	[self performSelectorOnMainThread:@selector(doError:) withObject:errInfo waitUntilDone:NO];
}


- (void)doError:(id)errInfo {
	[delegate xpathService:self error:errInfo];	
}


- (void)parseError:(id)errInfo {
	[self performSelectorOnMainThread:@selector(doParseError:) withObject:errInfo waitUntilDone:NO];
}


- (void)doParseError:(id)errInfo {
	[delegate xpathService:self parseError:errInfo];	
}

@end
