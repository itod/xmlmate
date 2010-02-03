//
//  XMLParsingServiceLibxmlImpl.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingServiceLibxmlImpl.h"
#import "XMLParsingStrategy.h"
#import "XMLParseCommand.h"
#import "XMLParsingNoneStrategy.h"
#import "XMLParsingAutoDTDStrategy.h"
#import "XMLParsingUserSelectedDTDStrategy.h"
#import "XMLParsingXSDStrategy.h"
#import "XMLParsingRNGStrategy.h"
#import "XMLParsingRNCStrategy.h"
#import "XMLParsingSchematronStrategy.h"
#import <libxslt/xsltutils.h>

NSString * const XMLParseErrorFilenameKey	= @"filename";
NSString * const XMLParseErrorLineKey		= @"line";
NSString * const XMLParseErrorLevelStrKey	= @"levelStr";
NSString * const XMLParseErrorDomainStrKey	= @"domainStr";
NSString * const XMLParseErrorMessageKey	= @"message";
NSString * const XMLParseErrorElementNameKey= @"elementName";
NSString * const XMLParseErrorContextStrKey	= @"contextStr";

NSString * const XMLParseErrorTestKey		= @"test";
NSString * const XMLParseErrorRoleKey		= @"role";
NSString * const XMLParseErrorSubjectKey	= @"subject";
NSString * const XMLParseErrorDiagnosticsKey= @"diagnostics";

//static char *myCodes[692];

static void myStructuredErrorAdapter(id self, xmlErrorPtr err);
static void myParserPrintFileContext(xmlParserInputPtr input, NSMutableString *msg);

@interface XMLParsingServiceLibxmlImpl (Private)
+ (void)setupLibxml;
- (void)setupErrorHandlers;
- (void)warning:(NSDictionary *)info;
- (void)error:(NSDictionary *)info;
- (void)fatalError:(NSDictionary *)info;
- (void)doParse:(XMLParseCommand *)command;
- (void)setStrategyForParseCommand:(XMLParseCommand *)command;

- (XMLParsingStrategy *)strategy;
- (void)setStrategy:(XMLParsingStrategy *)newStrategy;
@end

@interface XMLParsingServiceLibxmlImpl (PrivateDelegateCalltos)
- (void)willParse:(XMLParseCommand *)command;
- (void)didParse:(XMLParseCommand *)command;
- (void)willParseSchema:(NSString *)schemaURLString;
- (void)didParseSchema:(NSArray *)args;
- (void)willParseSource:(NSString *)sourceURLString;
- (void)didParseSource:(NSArray *)args;
@end

@implementation XMLParsingServiceLibxmlImpl

+ (void)initialize {
	[self setupLibxml];
}


- (id)initWithDelegate:(id)d {
	self = [super init];
	if (self != nil) {
		delegate = d;
	}
	return self;
}


- (void)dealloc {
    delegate = nil;
	// cleanup libxml
	xmlCleanupParser();
	[super dealloc];
}


#pragma mark -
#pragma mark XMLParsingService

+ (void)setupLibxml {
    /*
     * this initialize the library and check potential ABI mismatches
     * between the version it was compiled for and the actual shared
     * library used.
     */
	xmlInitParser();
    LIBXML_TEST_VERSION
	//NSLog(@"initializeLibxml");
}


- (void)setupErrorHandlers {
	xmlSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorHandler);
	xmlSetStructuredErrorFunc((void *)self, (xmlStructuredErrorFunc)myStructuredErrorAdapter);
}


- (void)parse:(XMLParseCommand *)command {
	[NSThread detachNewThreadSelector:@selector(doParse:)
							 toTarget:self
						   withObject:command];
}


#pragma mark -
#pragma mark StrategyCallbacks

- (void)strategyWillParse:(XMLParseCommand *)command {
	[self performSelectorOnMainThread:@selector(willParse:)
						   withObject:command
						waitUntilDone:NO];
}


- (void)strategyDidParse:(XMLParseCommand *)command {
	[self performSelectorOnMainThread:@selector(didParse:)
						   withObject:command
						waitUntilDone:NO];
}


- (void)strategyWillFetchSchema:(NSString *)schemaURLString {
	[self performSelectorOnMainThread:@selector(willFetchSchema:)
						   withObject:schemaURLString
						waitUntilDone:NO];
}


- (void)strategyDidFetchSchema:(NSString *)schemaURLString duration:(NSTimeInterval)duration {
	[self performSelectorOnMainThread:@selector(didFetchSchema:)
						   withObject:schemaURLString
						waitUntilDone:NO];
}


- (void)strategyWillParseSchema:(NSString *)schemaURLString {
	[self performSelectorOnMainThread:@selector(willParseSchema:)
						   withObject:schemaURLString
						waitUntilDone:NO];
}


- (void)strategyDidParseSchema:(NSString *)schemaURLString duration:(NSTimeInterval)duration {
	NSArray *args = [NSArray arrayWithObjects:schemaURLString, [NSNumber numberWithInt:duration], nil];
	[self performSelectorOnMainThread:@selector(didParseSchema:)
						   withObject:args
						waitUntilDone:NO];
}

- (void)strategyWillFetchSource:(NSString *)sourceURLString {
	[self performSelectorOnMainThread:@selector(willFetchSource:)
						   withObject:sourceURLString
						waitUntilDone:NO];
}


- (void)strategyDidFetchSource:(NSString *)sourceURLString duration:(NSTimeInterval)duration {
	[self performSelectorOnMainThread:@selector(didFetchSource:)
						   withObject:sourceURLString
						waitUntilDone:NO];
}


- (void)strategyWillParseSource:(NSString *)sourceURLString {
	[self performSelectorOnMainThread:@selector(willParseSource:)
						   withObject:sourceURLString
						waitUntilDone:NO];
}


- (void)strategyDidParseSource:(NSString *)sourceURLString sourceXMLString:(NSString *)XMLString duration:(NSTimeInterval)duration {
	NSArray *args = [NSArray arrayWithObjects:sourceURLString, XMLString, [NSNumber numberWithInt:duration], nil];
	[self performSelectorOnMainThread:@selector(didParseSource:)
						   withObject:args
						waitUntilDone:NO];
}


- (void)strategyAssertFired:(NSDictionary *)info {
	[self performSelectorOnMainThread:@selector(assertFired:)
						   withObject:info
						waitUntilDone:NO];
}


- (void)strategyReportFired:(NSDictionary *)info {
	[self performSelectorOnMainThread:@selector(reportFired:)
						   withObject:info
						waitUntilDone:NO];
}


#pragma mark -
#pragma mark PrivateDelegateCalltos

- (void)willParse:(XMLParseCommand *)command {
	[delegate parsingService:self willParse:command];
}


- (void)didParse:(XMLParseCommand *)command {
	[delegate parsingService:self didParse:command];
}


- (void)willParseSchema:(NSString *)schemaURLString {
	[delegate parsingService:self willParseSchema:schemaURLString];
}


- (void)didParseSchema:(NSArray *)args {
	NSString *schemaURLString = [args objectAtIndex:0];
	NSTimeInterval duration   = [[args objectAtIndex:1] intValue];
	
	[delegate parsingService:self didParseSchema:schemaURLString duration:duration];
}


- (void)willParseSource:(NSString *)sourceURLString {
	[delegate parsingService:self willParseSource:sourceURLString];
}


- (void)didParseSource:(NSArray *)args {
	NSString *sourceURLString = [args objectAtIndex:0];
	NSString *XMLString = [args objectAtIndex:1];
	NSTimeInterval duration   = [[args objectAtIndex:2] intValue];
	[delegate parsingService:self didParseSource:sourceURLString sourceXMLString:XMLString duration:duration];
}


#pragma mark -
#pragma mark Private

- (void)doParse:(XMLParseCommand *)command {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self setupErrorHandlers];

	[self setStrategyForParseCommand:command];

	[strategy parse:command];
	
	[pool release];
}


- (void)setStrategyForParseCommand:(XMLParseCommand *)command {
	XMLValidationType type = [command validationType];
	
	Class class;
	
	switch (type) {
		case XMLValidationTypeDTD:
			if ([[command schemaURLString] length]) {
				class = [XMLParsingUserSelectedDTDStrategy class];
			} else {
				class = [XMLParsingAutoDTDStrategy class];
			}
			break;
		case XMLValidationTypeXSD:
			class = [XMLParsingXSDStrategy class];
			break;
		case XMLValidationTypeRNG:
			class = [XMLParsingRNGStrategy class];
			break;
		case XMLValidationTypeRNC:
			class = [XMLParsingRNCStrategy class];
			break;
		case XMLValidationTypeSchematron:
			class = [XMLParsingSchematronStrategy class];
			break;
		default:
			class = [XMLParsingNoneStrategy class];
			break;
	}

	// only create new strategy if different from the last one.
	if (class != [strategy class]) {
		[self setStrategy:[[[class alloc] initWithService:self] autorelease]];
	}
}


#pragma mark ErrorHandler 

- (void)warning:(NSDictionary *)info {
	[delegate parsingService:self warning:info];
}


- (void)error:(NSDictionary *)info {
	[delegate parsingService:self error:info];
}


- (void)fatalError:(NSDictionary *)info {
	[delegate parsingService:self fatalError:info];
}


#pragma mark SchematronMessageHandler 

- (void)assertFired:(NSDictionary *)info {
	[delegate parsingService:self assertFired:info];
}


- (void)reportFired:(NSDictionary *)info {
	[delegate parsingService:self reportFired:info];
}


static void myParserPrintFileContext(xmlParserInputPtr input, NSMutableString *msg) {
    const xmlChar *cur, *base;
    unsigned int n, col;	/* GCC warns if signed, because compared with sizeof() */
    xmlChar  content[81]; /* space for 80 chars + line terminator */
    xmlChar *ctnt;

	//NSLog(@"input == NULL: %d", (input == NULL));
	
    if (input == NULL || input->id < 0 || input->id > 1000000) return;

	// seems to be a libxml bug... somtimes a non-fully-initialized input obj
	// will arrive here which can cause a crasher when accessing some of it's fields
	// Luckily, you seem to be able to notice this case cuz although the input obj
	// is non-null, it's id == 0 || > 1000000
	//NSLog(@"input->id: %d", input->id);

	cur = input->cur;
    base = input->base;
    /* skip backwards over any end-of-lines */
    while ((cur > base) && ((*(cur) == '\n') || (*(cur) == '\r'))) {
		cur--;
    }
    n = 0;
    /* search backwards for beginning-of-line (to max buff size) */
    while ((n++ < (sizeof(content)-1)) && (cur > base) && 
    	   (*(cur) != '\n') && (*(cur) != '\r'))
        cur--;
    if ((*(cur) == '\n') || (*(cur) == '\r')) cur++;
    /* calculate the error position in terms of the current position */
    col = input->cur - cur;
    /* search forward for end-of-line (to max buff size) */
    n = 0;
    ctnt = content;
    /* copy selected text to our buffer */
    while ((*cur != 0) && (*(cur) != '\n') && 
    	   (*(cur) != '\r') && (n < sizeof(content)-1)) {
		*ctnt++ = *cur++;
		n++;
    }
    *ctnt = 0;
    /* print out the selected text */
	
	NSData *data = [NSData dataWithBytes:content length:strlen((const char *)content)];
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
    [msg appendFormat:@"%@\n", str];
    /* create blank line with problem pointer */
    n = 0;
    ctnt = content;
    /* (leave buffer space for pointer + line terminator) */
    while ((n<col) && (n++ < sizeof(content)-2) && (*ctnt != 0)) {
		if (*(ctnt) != '\t')
			*(ctnt) = ' ';
		ctnt++;
    }
    *ctnt++ = '^';
    *ctnt = 0;
    [msg appendFormat:@"%s\n", content];
}


static void myStructuredErrorAdapter(id self, xmlErrorPtr err) {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:7];
    
    // context is incomplete and preventing the display of error line numbers for xml schema
    //xmlParserCtxtPtr ctxt = err->ctxt;
    xmlParserCtxtPtr ctxt = NULL;
    const char *str = err->message;
	
    char *file = NULL;
    int line = 0;
    int code = -1;
    int domain = 0;
    const xmlChar *name = NULL;
    xmlNodePtr node;
    xmlErrorLevel level;
    xmlParserInputPtr input = NULL;
    xmlParserInputPtr cur = NULL;
	
    if (err == NULL)
        return;
    file = err->file;
    line = err->line;
    code = err->code;
    domain = err->domain;
    level = err->level;
    node = err->node;
	
    if (code == XML_ERR_OK)
        return;
	
    if ((node != NULL) && (node->type == XML_ELEMENT_NODE))
        name = node->name;
	
	id obj = nil;
	
    /*
     * Maintain the compatibility with the legacy error handling
     */
    if (ctxt != NULL) {
        input = ctxt->input;
        if ((input != NULL) && (input->filename == NULL) &&
            (ctxt->inputNr > 1)) {
            cur = input;
            input = ctxt->inputTab[ctxt->inputNr - 2];
        }

        if (input != NULL && input->id >= 0 && input->id < 1000000) {
			// seems to be a libxml bug... somtimes a non-fully-initialized input obj
			// will arrive here which can cause a crasher when accessing some of it's fields
			// Luckily, you seem to be able to notice this case cuz although the input obj
			// is non-null, it's id == 0 || > 1000000
			//NSLog(@"input->id: %d", input->id);
			
			const char *filename = NULL;
            if (input->filename)
				filename = input->filename;
            else if ((line != 0) && (domain == XML_FROM_PARSER))
                filename = "Entity";
			
			if (filename != NULL) {
				obj = [NSString stringWithUTF8String:filename];
				if (obj) {
					[info setObject:obj forKey:XMLParseErrorFilenameKey];
				}
			}
			obj = [NSNumber numberWithInt:input->line];
			if (obj) {
				[info setObject:obj forKey:XMLParseErrorLineKey];
			}

        }
    } else {

		const char *filename = NULL;
		if (file != NULL)
            filename = file;
        else if ((line != 0) && (domain == XML_FROM_PARSER))
			filename = "Entity";
		
		if (filename != NULL) {
			obj = [NSString stringWithUTF8String:filename];
			if (obj) {
				[info setObject:obj forKey:XMLParseErrorFilenameKey];
			}
		}		obj = [NSNumber numberWithInt:line];
		if (obj) {
			[info setObject:obj forKey:XMLParseErrorLineKey];
		}

	}
    if (name != NULL) {
		obj = [NSString stringWithUTF8String:(const char *)name];
		if (obj) {
			[info setObject:obj forKey:XMLParseErrorElementNameKey];
		}
    }
	NSString * domainStr = nil;
    switch (domain) {
        case XML_FROM_PARSER:
            domainStr = @"parser ";
            break;
        case XML_FROM_NAMESPACE:
            domainStr = @"namespace ";
            break;
        case XML_FROM_DTD:
        case XML_FROM_VALID:
            domainStr = @"validity ";
            break;
        case XML_FROM_HTML:
            domainStr = @"HTML parser ";
            break;
        case XML_FROM_MEMORY:
            domainStr = @"memory ";
            break;
        case XML_FROM_OUTPUT:
            domainStr = @"output ";
            break;
        case XML_FROM_IO:
            domainStr = @"I/O ";
            break;
        case XML_FROM_XINCLUDE:
            domainStr = @"XInclude ";
            break;
        case XML_FROM_XPATH:
            domainStr = @"XPath ";
            break;
        case XML_FROM_XPOINTER:
            domainStr = @"parser ";
            break;
        case XML_FROM_REGEXP:
            domainStr = @"regexp ";
            break;
        case XML_FROM_SCHEMASV:
            domainStr = @"Schemas validity ";
            break;
        case XML_FROM_SCHEMASP:
            domainStr = @"Schemas parser ";
            break;
        case XML_FROM_RELAXNGP:
            domainStr = @"RELAX NG parser ";
            break;
        case XML_FROM_RELAXNGV:
            domainStr = @"RELAX NG validity ";
            break;
        case XML_FROM_CATALOG:
            domainStr = @"Catalog ";
            break;
        case XML_FROM_C14N:
            domainStr = @"C14N ";
            break;
        case XML_FROM_XSLT:
            domainStr = @"XSLT ";
            break;
        default:
            break;
    }
	
	if (domainStr) {
		[info setObject:domainStr forKey:XMLParseErrorDomainStrKey];
	}
	
	NSString *levelStr = nil;
    switch (level) {
        case XML_ERR_NONE:
            levelStr = @"";
            break;
        case XML_ERR_WARNING:
            levelStr = @"warning";
            break;
        case XML_ERR_ERROR:
            levelStr = @"error";
            break;
        case XML_ERR_FATAL:
            levelStr = @"fatal error";
            break;
    }
	
	if (levelStr) {
		[info setObject:levelStr forKey:XMLParseErrorLevelStrKey];
	}
	
	NSString *message = nil;
    if (str != NULL) {
        int len;
		len = xmlStrlen((const xmlChar *)str);
		if ((len > 0) && (str[len - 1] != '\n'))
			message = [NSString stringWithFormat:@"%s\n", str];
		else
			message = [NSString stringWithFormat:@"%s", str];
    } else {
		message = [NSString stringWithFormat:@"%s\n", "out of memory error"];
    }
	
	if (message) {
		[info setObject:message forKey:XMLParseErrorMessageKey];
	}
	
	NSMutableString *contextStr = [NSMutableString string];
	//NSLog(@"gonna create contextStr!");
	//NSLog(@"ctxt == NULL : %d", (ctxt == NULL));
	
    if (ctxt != NULL) {
        myParserPrintFileContext(input, contextStr);
        if (cur != NULL) {
            if (cur->filename)
                [contextStr appendFormat:@"%s:%d: \n", cur->filename, cur->line];
            else if ((line != 0) && (domain == XML_FROM_PARSER))
                [contextStr appendFormat:@"Entity: line %d: \n", cur->line];
            myParserPrintFileContext(cur, contextStr);
        }
    }
    if ((domain == XML_FROM_XPATH) && (err->str1 != NULL) &&
        (err->int1 < 100) &&
		(err->int1 < xmlStrlen((const xmlChar *)err->str1))) {
		xmlChar buf[150];
		int i;
		
		[contextStr appendFormat:@"%s\n", err->str1];
		for (i=0;i < err->int1;i++)
			buf[i] = ' ';
		buf[i++] = '^';
		buf[i] = 0;
		[contextStr appendFormat:@"%s\n", buf];
    }
	
	if (contextStr) {
		[info setObject:contextStr forKey:XMLParseErrorContextStrKey];
	}
	
	SEL sel = nil;
	
	switch (level) {
		case XML_ERR_WARNING:
			sel = @selector(warning:);
			break;
		case XML_ERR_FATAL:
			sel = @selector(fatalError:);
			break;
		default:
			sel = @selector(error:);
			break;
	}
	
	[self performSelectorOnMainThread:sel withObject:info waitUntilDone:NO];
}



/*
 
 /Users/itod/Desktop/test.xml:2: parser error : Opening and ending tag mismatch: c line 2 and a
 <b/><c></a>
 ^
 
 /Users/itod/Desktop/test.xml:2: parser error : Premature end of data in tag a line 1
 <b/><c></a>
 ^
 */ 

void myGenericErrorHandler(id self, const char *msg, ...) {
	va_list vargs;
	va_start(vargs, msg);
	
	NSString *format = [NSString stringWithUTF8String:msg];
	NSMutableString *str = [[[NSMutableString alloc] initWithFormat:format arguments:vargs] autorelease];
	
	NSLog(str);
	
	va_end(vargs);
}


#pragma mark -
#pragma mark Accessors

- (XMLParsingStrategy *)strategy {
	return strategy;
}


- (void)setStrategy:(XMLParsingStrategy *)newStrategy {
	if (strategy != newStrategy) {
		[strategy autorelease];
		strategy = [newStrategy retain];
	}
}

@end
