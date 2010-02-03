//
//  XMLParseCommand.h
//  XML Nanny
//
//  Created by Todd Ditchendorf on 6/30/06.
//  Copyright 2006 Scandalous Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMLParsingService.h"

@interface XMLParseCommand : NSObject <NSCoding> {
	NSString *sourceURLString;
	XMLValidationType validationType;
	NSString *schemaURLString;
	NSData *sourceXMLData;
	BOOL verbose;
	BOOL doNamespaces;
	
	BOOL loadDTD;
	BOOL defaultDTDAttributes;
	BOOL substituteEntities;
	BOOL mergeCDATA;
	BOOL processXIncludes;
}

// Accessors
- (NSString *)sourceURLString;
- (void)setSourceURLString:(NSString *)newString;

- (NSData *)sourceXMLData;
- (void)setSourceXMLData:(NSData *)newData;

- (NSString *)schemaURLString;
- (void)setSchemaURLString:(NSString *)newString;

- (XMLValidationType)validationType;
- (void)setValidationType:(XMLValidationType)newType;

- (BOOL)verbose;
- (void)setVerbose:(BOOL)yn;

- (BOOL)doNamespaces;
- (void)setDoNamespaces:(BOOL)yn;

- (BOOL)loadDTD;
- (void)setLoadDTD:(BOOL)yn;

- (BOOL)defaultDTDAttributes;
- (void)setDefaultDTDAttributes:(BOOL)yn;

- (BOOL)substituteEntities;
- (void)setSubstituteEntities:(BOOL)yn;

- (BOOL)mergeCDATA;
- (void)setMergeCDATA:(BOOL)yn;

- (BOOL)processXIncludes;
- (void)setProcessXIncludes:(BOOL)yn;
@end
