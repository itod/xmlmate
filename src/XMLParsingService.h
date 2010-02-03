//
//  XMLParsingService.h
//  XML Nanny
//
//  Created by itod on 5/24/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum XMLValidationType {
	XMLValidationTypeNone = 0,
	XMLValidationTypeDTD,
	XMLValidationTypeXSD,
	XMLValidationTypeRNG,
	XMLValidationTypeRNC,
	XMLValidationTypeSchematron
} XMLValidationType;

extern NSString * const XMLParseErrorFilenameKey;
extern NSString * const XMLParseErrorLineKey;
extern NSString * const XMLParseErrorLevelStrKey;
extern NSString * const XMLParseErrorDomainStrKey;
extern NSString * const XMLParseErrorMessageKey;
extern NSString * const XMLParseErrorElementNameKey;
extern NSString * const XMLParseErrorContextStrKey;

// schematron-only keys
extern NSString * const XMLParseErrorTestKey;
extern NSString * const XMLParseErrorRoleKey;
extern NSString * const XMLParseErrorSubjectKey;
extern NSString * const XMLParseErrorDiagnosticsKey;

@class XMLParseCommand;

@protocol XMLParsingService <NSObject>
- (id)initWithDelegate:(id)aDelegate;
- (void)parse:(XMLParseCommand *)c;
@end

@interface NSObject (XMLParsingServiceDelegate)

// guaranteed to be called before any other delegate callback
- (void)parsingService:(id <XMLParsingService>)service willParse:(XMLParseCommand *)command;
// guarantted to be called after all other delegate callbacks.
// guaranteed to be called when parser stops, whether due to error or successfull completion.
- (void)parsingService:(id <XMLParsingService>)service didParse:(XMLParseCommand *)command;


- (void)parsingService:(id <XMLParsingService>)service willFetchSchema:(NSString *)schemaURLString;
- (void)parsingService:(id <XMLParsingService>)service didFetchSchema:(NSString *)schemaURLString;

- (void)parsingService:(id <XMLParsingService>)service willParseSchema:(NSString *)schemaURLString;
- (void)parsingService:(id <XMLParsingService>)service didParseSchema:(NSString *)schemaURLString duration:(NSTimeInterval)duration;

- (void)parsingService:(id <XMLParsingService>)service willFetchSource:(NSString *)sourceURLString;
- (void)parsingService:(id <XMLParsingService>)service didFetchSource:(NSString *)sourceURLString duration:(NSTimeInterval)duration;

- (void)parsingService:(id <XMLParsingService>)service willParseSource:(NSString *)sourceURLString;
- (void)parsingService:(id <XMLParsingService>)service didParseSource:(NSString *)sourceURLString sourceXMLString:(NSString *)XMLString duration:(NSTimeInterval)duration;

- (void)parsingService:(id <XMLParsingService>)service didDetectMimeType:(NSString *)mimeType;
- (void)parsingService:(id <XMLParsingService>)service didDetectEncoding:(NSString *)encoding;


// ErrorHandler
- (void)parsingService:(id <XMLParsingService>)service warning:(NSDictionary *)info;
- (void)parsingService:(id <XMLParsingService>)service error:(NSDictionary *)info;
- (void)parsingService:(id <XMLParsingService>)service fatalError:(NSDictionary *)info;

// SchematronMessageHandler
- (void)parsingService:(id <XMLParsingService>)service assertFired:(NSDictionary *)info;
- (void)parsingService:(id <XMLParsingService>)service reportFired:(NSDictionary *)info;

	
/*
 // ContentHandler
- (void)parsingService:(id <XMLParsingService>)service didStartDocument:(NSString *)sourceURLString;
- (void)parsingService:(id <XMLParsingService>)service didEndDocument:(NSString *)sourceURLString duration:(NSTimeInterval)duration;
- (void)parsingService:(id <XMLParsingService>)service didStartPrefixMapping:(NSString *)prefix forNamespace:(NSString *)nsURI;
- (void)parsingService:(id <XMLParsingService>)service didEndPrefixMapping:(NSString *)prefix;
- (void)parsingService:(id <XMLParsingService>)service didSkipEntity:(NSString *)name;
- (void)parsingService:(id <XMLParsingService>)service didProcessingInstruction:(NSString *)target data:(NSString *)data;
- (void)parsingService:(id <XMLParsingService>)service didCharacters:(NSString *)str;
- (void)parsingService:(id <XMLParsingService>)service didIgnorableWhitespace:(NSString *)str;
- (void)parsingService:(id <XMLParsingService>)service didStartElement:(NSString *)nsURI localName:(NSString *)localName qName:(NSString *)qName;
- (void)parsingService:(id <XMLParsingService>)service didEndElement:(NSString *)nsURI localName:(NSString *)localName qName:(NSString *)qName;
- (void)parsingService:(id <XMLParsingService>)service didAttribute:(NSString *)nsURI localName:(NSString *)localName qName:(NSString *)qName value:(NSString *)value;

// DTDHandler
- (void)parsingService:(id <XMLParsingService>)service didNotationDecl:(NSString *)name publicId:(NSString *)publicId systemId:(NSString *)systemId;
- (void)parsingService:(id <XMLParsingService>)service didUparsedEntityDecl:(NSString *)name publicId:(NSString *)publicId systemId:(NSString *)systemId notationName:(NSString *)notationName;

// DeclHandler
- (void)parsingService:(id <XMLParsingService>)service didAttributeDecl:(NSString *)eName aName:(NSString *)aName type:(NSString *)type valueDefault:(NSString *)valueDefault;
- (void)parsingService:(id <XMLParsingService>)service didElementDecl:(NSString *)name model:(NSString *)model;
- (void)parsingService:(id <XMLParsingService>)service didExternalEtityDecl:(NSString *)name publicId:(NSString *)publicId systemId:(NSString *)systemId;
- (void)parsingService:(id <XMLParsingService>)service didInternalEntityDecl:(NSString *)name value:(NSString *)value;

// LexicalHandler
- (void)parsingService:(id <XMLParsingService>)service didStartDTD:(NSString *)name publicId:(NSString *)publicId systemId:(NSString *)systemId;
- (void)parsingServiceDidEndDTD:(id <XMLParsingService>)service;
- (void)parsingService:(id <XMLParsingService>)service didComment:(NSString *)comment;
- (void)parsingServiceDidStartCDATA:(id <XMLParsingService>)service;
- (void)parsingServiceDidEndCDATA:(id <XMLParsingService>)service;
- (void)parsingService:(id <XMLParsingService>)service didStartEntity:(NSString *)name;
- (void)parsingService:(id <XMLParsingService>)service didEndEntity:(NSString *)name;

*/
@end



/*
@interface NSObject (XMLParsingServiceCallbacks)
// Content Handler called from actual C++ content handler
- (void)attribute:(NSDictionary *)args;
- (void)characters:(NSString *)chars;
- (void)endDocument;
- (void)endElement:(NSDictionary *)args;
- (void)ignorableWhitespace:(NSString *)chars;
- (void)processingInstruction:(NSDictionary *)args;
- (void)startDocument;
- (void)startElement:(NSDictionary *)args;
- (void)startPrefixMapping:(NSDictionary *)args;
- (void)endPrefixMapping:(NSString *)prefix;
- (void)skippedEntity:(NSString *)name;

	// Error Handler called from actual C++ error handler
- (void)warning:(NSDictionary *)args;
- (void)error:(NSDictionary *)args;
- (void)fatalError:(NSDictionary *)args;

	// DTDHandler called from actual C++ DTD handler
- (void)notationDecl:(NSDictionary *)args;
- (void)uparsedEntityDecl:(NSDictionary *)args;

	// DeclHandler called from actual C++ DeclHandler handler
- (void)attributeDecl:(NSDictionary *)args;
- (void)elementDecl:(NSDictionary *)args;
- (void)externalEntityDecl:(NSDictionary *)args;
- (void)internalEntityDecl:(NSDictionary *)args;

	// LexicalHandler called from actual C++ LexicalHandler handler
- (void)startDTD:(NSDictionary *)args;
- (void)endDTD;
- (void)comment:(NSString *)comment;
- (void)startCDATA;
- (void)endCDATA;
- (void)startEntity:(NSString *)name;
- (void)endEntity:(NSString *)name;

@end
*/
