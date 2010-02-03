//
//  XMLParsingSchematronStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/24/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingSchematronStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import "XMLMatePlugIn.h"
#import "AGRegex.h"
#import "NSString+libxml2Support.h"
#import <libxml/xinclude.h>
#import <libxslt/transform.h>
#import <libxslt/xsltutils.h>
#import <libxslt/extensions.h>
#import <libxml/xpathInternals.h>
#import <libexslt/exslt.h>

static XMLParsingSchematronStrategy *instance = nil;

static void myGenericErrorAdapter(id self, const char *str, ...) {
	va_list vargs;
	va_start(vargs, str);
	
	NSString *format = [NSString stringWithUTF8String:str];
	NSString *msg = [[[NSString alloc] initWithFormat:format arguments:vargs] autorelease];
	NSLog(msg);
	
	va_end(vargs);
}

static int regexpModuleGetOptions(xmlChar *optStr) {
	int opts = 0;
	NSString *flags = [NSString stringWithUTF8String:(char *)optStr];
	NSRange r = [flags rangeOfString:@"i"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexCaseInsensitive);
	r = [flags rangeOfString:@"s"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexDotAll);
	r = [flags rangeOfString:@"x"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexExtended);
	r = [flags rangeOfString:@"m"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexMultiline);	
	return opts;
}


static void regexpModuleFunctionReplace(xmlXPathParserContextPtr ctxt, int nargs) {
	int opts = 0;
	if (4 == nargs) {
		opts = regexpModuleGetOptions(xmlXPathPopString(ctxt));
	}
	
	const xmlChar *replacePattern = xmlXPathPopString(ctxt);
	const xmlChar *matchPattern = xmlXPathPopString(ctxt);
	const xmlChar *input = xmlXPathPopString(ctxt);
	
	AGRegex *regex = [AGRegex regexWithPattern:[NSString stringWithUTF8String:(const char*)matchPattern]
									   options:opts];
	
	NSString *result = [regex replaceWithString:[NSString stringWithUTF8String:(const char*)replacePattern]
									   inString:[NSString stringWithUTF8String:(const char*)input]];
	
	xmlXPathObjectPtr value = xmlXPathNewString((xmlChar *)[result UTF8String]);
	valuePush(ctxt, value);
}


static void regexpModuleFunctionTest(xmlXPathParserContextPtr ctxt, int nargs) {
	int opts = 0;
	if (3 == nargs) {
		opts = regexpModuleGetOptions(xmlXPathPopString(ctxt));
	}
	
	const xmlChar *matchPattern = xmlXPathPopString(ctxt);
	const xmlChar *input = xmlXPathPopString(ctxt);
	
	AGRegex *regex = [AGRegex regexWithPattern:[NSString stringWithUTF8String:(const char*)matchPattern]
									   options:opts];
	
	BOOL result = [[regex findInString:[NSString stringWithUTF8String:(const char*)input]] count];
	
	xmlXPathObjectPtr value = xmlXPathNewBoolean(result);
	valuePush(ctxt, value);
}


static void regexpModuleFunctionMatch(xmlXPathParserContextPtr ctxt, int nargs) {
	int opts = 0;
	if (3 == nargs) {
		opts = regexpModuleGetOptions(xmlXPathPopString(ctxt));
	}
	
	const xmlChar *matchPattern = xmlXPathPopString(ctxt);
	const xmlChar *input = xmlXPathPopString(ctxt);
	
	AGRegex *regex = [AGRegex regexWithPattern:[NSString stringWithUTF8String:(const char*)matchPattern]
									   options:opts];
	
	AGRegexMatch *match = [[regex findAllInString:[NSString stringWithUTF8String:(const char*)input]] objectAtIndex:0];
	
	int len = [match count];
	
	xmlNodePtr node = xmlNewNode(NULL, (const xmlChar *)"match");
	xmlNodeSetContent(node, (const xmlChar *)[[match groupAtIndex:0] UTF8String]);
	xmlNodeSetPtr nodeSet = xmlXPathNodeSetCreate(node);
	
	int i;
	NSString *item;
	for (i = 1; i < len; i++) {
		item = [match groupAtIndex:i];
		
		node = xmlNewNode(NULL, (const xmlChar *)"match");
		if (item) {
			xmlNodeSetContent(node, (const xmlChar *)[[match groupAtIndex:i] UTF8String]);
		} else {
			xmlNodeSetContent(node, (const xmlChar *)"");
		}
		xmlXPathNodeSetAdd(nodeSet, node);
	}
	
	xmlXPathObjectPtr value = xmlXPathWrapNodeSet(nodeSet);
	valuePush(ctxt, value);
}


static void *regexpModuleInit(xsltTransformContextPtr ctxt, const xmlChar *URI) {
	xsltRegisterExtFunction(ctxt, (const xmlChar *)"replace", URI,
							(xmlXPathFunction)regexpModuleFunctionReplace);
	xsltRegisterExtFunction(ctxt, (const xmlChar *)"test", URI,
							(xmlXPathFunction)regexpModuleFunctionTest);
	xsltRegisterExtFunction(ctxt, (const xmlChar *)"match", URI,
							(xmlXPathFunction)regexpModuleFunctionMatch);
	
	return NULL;
}


static void *regexpModuleShutdown(xsltTransformContextPtr ctxt, const xmlChar *URI, void *data) {
	return NULL;
}


static const xmlChar *getStringValueForAttr(xsltTransformContextPtr ctxt, xmlNodePtr inputNode, xmlAttrPtr currAttr) {
	const xmlNodePtr children = currAttr->children;
	if (NULL == children) {
		return NULL;
	}
	
	const xmlChar *content = children->content;
	return content;
}


static const xmlChar *evalExprAgainstNode(xsltTransformContextPtr ctxt, xmlNodePtr inputNode, xmlChar *expr) {
	//NSLog(@"inputNode->name: %s", inputNode->name);
	
	// get the current transformation's XPath context
	xmlXPathContextPtr xpathCtxt = ctxt->xpathCtxt;
	// set the XPath context's context node to the input node matched by <xsl:template>
	xpathCtxt->node = inputNode;
	// evaluate the expr against the XPath context
	xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression(expr, xpathCtxt);
	// get the resulting node-set
	const xmlChar *strVal = xpathObj->stringval;
	
	return strVal;
}

static void handleMessageFired(xsltTransformContextPtr ctxt,
							   xmlNodePtr inputNode,
							   xmlNodePtr sheetNode,
							   xsltStylePreCompPtr comp,
							   BOOL isAssert)
{
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:5];
	
	//NSLog(@"inputNode->name: %s", inputNode->name);
	//NSLog(@"sheetNode->name: %s", sheetNode->name);
	
	NSNumber *line = [NSNumber numberWithInt:inputNode->line]; 
	if (line) {
		[info setObject:line forKey:XMLParseErrorLineKey];
	}

	NSString *filename = [NSString stringWithUTF8String:(const char *)inputNode->doc->URL];
	if (NULL != filename) {
		[info setObject:filename forKey:XMLParseErrorFilenameKey];
	}

	[info setObject:@"Schematron " forKey:XMLParseErrorDomainStrKey];
	[info setObject:(isAssert ? @"Assert Failed" : @"Report") forKey:XMLParseErrorLevelStrKey];

	// get message which is string-value of inputNode's first child (t:msg)
	const xmlChar *msg = evalExprAgainstNode(ctxt, sheetNode, (xmlChar *)"string(*[1])");
	if (NULL != msg) {
		[info setObject:[NSString stringWithXmlChar:msg] forKey:XMLParseErrorMessageKey];
	}

	// get message which is string-value of inputNode's second child (t:diag)
	const xmlChar *diag = evalExprAgainstNode(ctxt, sheetNode, (xmlChar *)"string(*[2])");
	if (NULL != diag) {
		[info setObject:[NSString stringWithXmlChar:diag] forKey:XMLParseErrorDiagnosticsKey];
	}
	
	// get subj which is string-value of inputNode's third child (t:subj), and eval
	const xmlChar *subjExpr = evalExprAgainstNode(ctxt, sheetNode, (xmlChar *)"string(*[3])");
	if (NULL != subjExpr) {
		xmlChar *subjStrExpr = [[NSString stringWithFormat:@"string(%s)", subjExpr] xmlChar];
		const xmlChar *subj = evalExprAgainstNode(ctxt, inputNode, subjStrExpr);
		if (NULL != subj) {
			[info setObject:[NSString stringWithXmlChar:subj] forKey:XMLParseErrorSubjectKey];
		}
	}
	
	// get the attributes of my <fired-assert> element
	xmlAttrPtr currAttr	= sheetNode->properties;
	
	do {
		const xmlChar *currName = currAttr->name;
		
		if (NULL != currName) {
			const xmlChar *currVal = getStringValueForAttr(ctxt, inputNode, currAttr);
			
			if (NULL != currVal) {
				NSString *key = [NSString stringWithXmlChar:currName];
				
				// use test expr as context string for shcematron messages
				if ([key isEqualToString:@"test"]) {
					key = XMLParseErrorContextStrKey;
				}

				[info setObject:[NSString stringWithXmlChar:currVal] forKey:key];
			}
			
		}
		currAttr = currAttr->next;
	} while (NULL != currAttr);
		
	SEL sel = (isAssert) ? @selector(assertFired:) : @selector(reportFired:);
	
	[instance performSelector:sel withObject:info];
}


static void xmlmateModuleElementReportFired(xsltTransformContextPtr ctxt,
											  xmlNodePtr inputNode,
											  xmlNodePtr sheetNode,
											  xsltStylePreCompPtr comp) 
{
	handleMessageFired(ctxt, inputNode, sheetNode, comp, NO);
}	


static void xmlmateModuleElementAssertFired(xsltTransformContextPtr ctxt,
											  xmlNodePtr inputNode,
											  xmlNodePtr sheetNode,
											  xsltStylePreCompPtr comp)
{
	handleMessageFired(ctxt, inputNode, sheetNode, comp, YES);
}


static void *xmlmateModuleInit(xsltTransformContextPtr ctxt, const xmlChar *URI) {
	xsltRegisterExtElement(ctxt,(const xmlChar *)"assert-fired", URI, 
						   (xsltTransformFunction)xmlmateModuleElementAssertFired);
	xsltRegisterExtElement(ctxt,(const xmlChar *)"report-fired", URI, 
						   (xsltTransformFunction)xmlmateModuleElementReportFired);
	return NULL;
}


static void *xmlmateModuleShutdown(xsltTransformContextPtr ctxt, const xmlChar *URI, void *data) {
	return NULL;
}


@interface XMLParsingSchematronStrategy (Private)
- (void)loadMetaStylesheet;
@end

@implementation XMLParsingSchematronStrategy

#pragma mark -

- (id)initWithService:(XMLParsingServiceLibxmlImpl *)aService {
	self = [super initWithService:aService];
	if (self != nil) {
		[self loadMetaStylesheet];
		instance = self;
	}
	return self;
}


- (void)dealloc {
	xsltFreeStylesheet(metaStylesheet);
	xsltCleanupGlobals();
	instance = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Strategy

- (void)parse:(XMLParseCommand *)command {
	//NSLog(@"XMLParsingSchematronStrategy parse:");
	
	xmlDocPtr schematron				 = NULL;
	xmlDocPtr compiledStylesheetDocPtr   = NULL;
	xsltStylesheetPtr compiledStylesheet = NULL;
	xmlDocPtr docPtr					 = NULL;
	
	[service strategyWillParse:command];
	
	NSString *schemaURLString = [command schemaURLString];
	NSString *sourceURLString = [command sourceURLString];
	NSData *sourceXMLData = [command sourceXMLData];
	
	[service strategyWillParseSchema:schemaURLString];
	
	if (!metaStylesheet) {
		goto leave;
	}
	
	NSDate *start = [NSDate date];
	
	schematron = xmlParseFile([schemaURLString UTF8String]);
	
	if (!schematron) {
		goto leave;
	}
	
	const char *params[] = {
		"sourceURLString", [sourceURLString UTF8String],
		"schemaURLString", [schemaURLString UTF8String],
		NULL
	};

	compiledStylesheetDocPtr = xsltApplyStylesheet(metaStylesheet, schematron, params);
	
	if (!compiledStylesheetDocPtr) {
		goto leave;
	}
	
	// apparently frees the docPtr???
	compiledStylesheet = xsltParseStylesheetDoc(compiledStylesheetDocPtr);
	
	if (!compiledStylesheet) {
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
	
	// ignore result. side effects are callbacks
	xsltApplyStylesheet(compiledStylesheet, docPtr, NULL);
	
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
	if (NULL != compiledStylesheet) {
		xsltFreeStylesheet(compiledStylesheet);
		compiledStylesheet = NULL;
	}
	if (NULL != compiledStylesheetDocPtr) {
		//xmlFreeDoc(compiledStylesheetDocPtr);
		compiledStylesheetDocPtr = NULL;
	}
	if (NULL != schematron) {
		xmlFreeDoc(schematron);
		schematron = NULL;
	}
}


#pragma mark -
#pragma mark Private

- (void)loadMetaStylesheet {
	xsltRegisterExtModule((const xmlChar *)"http://exslt.org/regular-expressions",
						  (xsltExtInitFunction)regexpModuleInit,
						  (xsltExtShutdownFunction)regexpModuleShutdown);

	xsltRegisterExtModule((const xmlChar *)"http://scan.dalo.us/xmlmate",
						  (xsltExtInitFunction)xmlmateModuleInit,
						  (xsltExtShutdownFunction)xmlmateModuleShutdown);
	
	//xmlSubstituteEntitiesDefaultValue = 1;
	//xmlLoadExtDtdDefaultValue = 1;
	exsltRegisterAll();
	
	// not sure if this callback is ever called. only use of myGenericErrorAdapter.
	xsltSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorAdapter);

	NSString *path = [[XMLMatePlugIn bundle] pathForResource:@"sch-custom" ofType:@"xsl"];
	
	metaStylesheet = xsltParseStylesheetFile([path xmlChar]);
}


- (void)assertFired:(NSDictionary *)info {
	[service strategyAssertFired:info];
}


- (void)reportFired:(NSDictionary *)info {
	[service strategyReportFired:info];
}


#pragma mark -
#pragma mark Accessors

@end
