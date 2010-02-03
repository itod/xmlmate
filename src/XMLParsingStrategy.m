//
//  XMLParsingStrategy.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLParsingStrategy.h"
#import "XMLParsingServiceLibxmlImpl.h"

@interface XMLParsingStrategy (Private)
- (NSData *)fetchRemoteResource:(NSString *)URLString error:(NSError **)err;
- (NSData *)fetchLocalResource:(NSString *)URLString error:(NSError **)err;
@end

@implementation XMLParsingStrategy

- (id)initWithService:(XMLParsingServiceLibxmlImpl *)aService {
	self = [super init];
	if (self != nil) {
		service = aService;
	}
	return self;
}


- (void)dealloc {
	//NSLog(@"%@ dealloc", NSStringFromClass([self class]));
	[super dealloc];
}


#pragma mark -
#pragma mark XMLParsingStrategy

- (void)parse:(XMLParseCommand *)command {
	[NSException raise:@"NotImplException" 
				format:@"Subclass '%@' of XMLParsingStrategy should implement parse:", 
		NSStringFromClass([self class])];
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


- (NSData* )fetchDataForResource:(NSString *)URLString error:(NSError **)err {
	if ([URLString hasPrefix:@"http://"] || [URLString hasPrefix:@"https://"]) {
		return [self fetchRemoteResource:URLString error:err];
	} else {
		return [self fetchLocalResource:URLString error:err];
	}
}


#pragma mark -
#pragma mark Private

- (NSData *)fetchRemoteResource:(NSString *)URLString error:(NSError **)err {
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	NSURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:err];
	return data;
}


- (NSData *)fetchLocalResource:(NSString *)URLString error:(NSError **)err {
	return [NSData dataWithContentsOfFile:URLString options:0 error:err];
}

@end