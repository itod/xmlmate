//
//  XMLParseCommand.m
//  XML Nanny
//
//  Created by Todd Ditchendorf on 6/30/06.
//  Copyright 2006 Scandalous Software. All rights reserved.
//

#import "XMLParseCommand.h"

@implementation XMLParseCommand

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setDoNamespaces:YES];
		[self setVerbose:YES];
		[self setLoadDTD:YES];
		[self setDefaultDTDAttributes:YES];
		[self setSubstituteEntities:YES];
		[self setMergeCDATA:YES];
		[self setProcessXIncludes:YES];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	[self setSourceURLString:[coder decodeObjectForKey:@"sourceURLString"]];
	[self setSchemaURLString:[coder decodeObjectForKey:@"schemaURLString"]];
	[self setValidationType:[coder decodeIntForKey:@"validationType"]];
	[self setVerbose:[coder decodeBoolForKey:@"verbose"]];
	[self setDoNamespaces:[coder decodeBoolForKey:@"doNamespaces"]];
	[self setLoadDTD:[coder decodeBoolForKey:@"loadDTD"]];
	[self setDefaultDTDAttributes:[coder decodeBoolForKey:@"defaultDTDAttributes"]];
	[self setSubstituteEntities:[coder decodeBoolForKey:@"substituteEntities"]];
	[self setMergeCDATA:[coder decodeBoolForKey:@"mergeCDATA"]];
	[self setProcessXIncludes:[coder decodeBoolForKey:@"processXIncludes"]];
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:sourceURLString forKey:@"sourceURLString"];
	[coder encodeObject:schemaURLString forKey:@"schemaURLString"];
	[coder encodeInt:validationType forKey:@"validationType"];
	[coder encodeBool:verbose forKey:@"verbose"];
	[coder encodeBool:doNamespaces forKey:@"doNamespaces"];
	[coder encodeBool:loadDTD forKey:@"loadDTD"];
	[coder encodeBool:defaultDTDAttributes forKey:@"defaultDTDAttributes"];
	[coder encodeBool:substituteEntities forKey:@"substituteEntities"];
	[coder encodeBool:mergeCDATA forKey:@"mergeCDATA"];
	[coder encodeBool:processXIncludes forKey:@"processXIncludes"];
}


- (void)dealloc {
	[self setSourceURLString:nil];
	[self setSchemaURLString:nil];
	[self setSourceXMLData:nil];
	[super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSString *)description {
	return [NSString stringWithFormat:
		@"<XMLParseCommand { \n\tsourceURLString = %@\n\tschemaURLString = %@\n\tvalidationType = %d\n\tverbose = %d\n\tloadDTD = %d\n\tdefaultDTDAttributes = %d\n\tsubstituteEntities = %d\n\tmergeCDATA = %d\n\tprocessXIncludes = %d \n}>",
		sourceURLString, schemaURLString, validationType, verbose, loadDTD, defaultDTDAttributes, substituteEntities, mergeCDATA, processXIncludes];
	
}

#pragma mark -
#pragma mark Accessors

- (NSString *)sourceURLString {
	return sourceURLString;
}


- (void)setSourceURLString:(NSString *)newString {
	if (sourceURLString != newString) {
		[sourceURLString autorelease];
		sourceURLString = [newString retain];
	}
}


- (NSData *)sourceXMLData {
	return sourceXMLData;
}


- (void)setSourceXMLData:(NSData *)newData {
	if (sourceXMLData != newData) {
		[sourceXMLData autorelease];
		sourceXMLData = [newData retain];
	}
}


- (NSString *)schemaURLString {
	return schemaURLString;
}


- (void)setSchemaURLString:(NSString *)newString {
	if (schemaURLString != newString) {
		[schemaURLString autorelease];
		schemaURLString = [newString retain];
	}
}


- (XMLValidationType)validationType {
	return validationType;
}


- (void)setValidationType:(XMLValidationType)newType {
	validationType = newType;
}


- (BOOL)verbose {
	return verbose;
}


- (void)setVerbose:(BOOL)yn {
	verbose = yn;
}


- (BOOL)doNamespaces {
	return doNamespaces;
}


- (void)setDoNamespaces:(BOOL)yn {
	doNamespaces = yn;
}


- (BOOL)loadDTD {
	return loadDTD;
}


- (void)setLoadDTD:(BOOL)yn {
	loadDTD = yn;
}


- (BOOL)defaultDTDAttributes {
	return defaultDTDAttributes;
}


- (void)setDefaultDTDAttributes:(BOOL)yn {
	defaultDTDAttributes = yn;
}


- (BOOL)substituteEntities {
	return substituteEntities;
}


- (void)setSubstituteEntities:(BOOL)yn {
	substituteEntities = yn;
}


- (BOOL)mergeCDATA {
	return mergeCDATA;
}


- (void)setMergeCDATA:(BOOL)yn {
	mergeCDATA = yn;
}


- (BOOL)processXIncludes {
	return processXIncludes;
}


- (void)setProcessXIncludes:(BOOL)yn {
	processXIncludes = yn;
}

@end
