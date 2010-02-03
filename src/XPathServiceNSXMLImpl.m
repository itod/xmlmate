//
//  XPathServiceNSXMLImpl.m
//  TeXMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XPathServiceNSXMLImpl.h"
#import "XMLParseCommand.h"

@interface XPathServiceNSXMLImpl (Private)
- (void)doExecuteQuery:(NSArray *)args;
- (void)success:(NSArray *)sequence;
- (void)doSuccess:(NSArray *)sequence;
- (void)error:(NSString *)errInfo;
- (void)doError:(NSString *)errInfo;
@end

@implementation XPathServiceNSXMLImpl

#pragma mark -

- (id)initWithDelegate:(id)aDelegate;
{
	self = [super init];
	if (self != nil) {
		delegate = aDelegate;
	}
	return self;
}


#pragma mark -
#pragma mark XPathService

- (void)executeQuery:(NSString *)queryString withCommand:(XMLParseCommand *)command;
{
	NSArray *args = [NSArray arrayWithObjects:queryString, command, nil];
	
	[NSThread detachNewThreadSelector:@selector(doExecuteQuery:)
							 toTarget:self
						   withObject:args];
}


#pragma mark -
#pragma mark Private 

- (void)doExecuteQuery:(NSArray *)args;
{
	/*
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"do query!!!!!!!!!!!");

	NSString *queryString = [args objectAtIndex:0];
	XMLParseCommand *command = [args objectAtIndex:1];
	
	NSError *err = nil;
	
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:XMLString
														   options:NSXMLNodePreserveAll
															 error:&err] autorelease];
		
	if (!doc) {
		if (err) {
			[self error:[err localizedDescription]];
		} else {
			[self error:@"Unknown error while parsing source document"];
		}
		[pool release];
		return;
	}
	
	err = nil;
	
	NSArray *result = [doc objectsForXQuery:queryString error:&err];
	
	if (err) {
		[self error:[err localizedDescription]];
		[pool release];
		return;
	}
	
	[self success:result];
	
	[pool release];
	 */
}


- (void)success:(NSArray *)sequence;
{
	[self performSelectorOnMainThread:@selector(doSuccess:)
						   withObject:sequence
						waitUntilDone:NO];
}


- (void)doSuccess:(NSArray *)sequence;
{
	[delegate queryService:self didFinish:sequence];
}


- (void)error:(NSString *)errInfo;
{
	[self performSelectorOnMainThread:@selector(doError:)
						   withObject:errInfo
						waitUntilDone:NO];
}


- (void)doError:(NSString *)errInfo;
{
	[delegate queryService:self error:errInfo];	
}

@end
