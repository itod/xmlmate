//
//  XMLCatalogServiceLibxmlImpl.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/31/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLCatalogService.h"
#import "XMLCatalogServiceLibxmlImpl.h"
#import "CatalogItem.h"
#import "XMLMateController.h"
#import "NSString+libxml2Support.h"
#import "XMLMatePlugIn.h"
#import <libxml/catalog.h>

#import <stdlib.h>

//char *getenv(const char *name);
//int setenv(const char *name, const char *value, int overwrite);

static const char * const typeNames[] = {
	"del", "public", "system", "rewriteSystem", NULL
};

@interface XMLCatalogServiceLibxmlImpl (Private)
- (void)doPutCatalogContents:(NSArray *)catalogContents;
- (NSString *)writeCatalogToDiskAndLoad;
- (NSString *)pathForXMLFileNamed:(NSString *)name;
- (void)success:(NSString *)XMLString;
- (void)doSuccess:(NSString *)XMLString;
- (void)error:(NSDictionary *)errInfo;
- (void)doError:(NSDictionary *)errInfo;
@end

@implementation XMLCatalogServiceLibxmlImpl

- (id)initWithDelegate:(id)aDelegate environmentVariables:(id)vars {
	self = [super init];
	if (self != nil) {
		delegate = aDelegate;
		//xmlCatalogSetDebug(1);
		xmlCatalogSetDefaults(XML_CATA_ALLOW_GLOBAL);
		environmentVariables = [vars retain];
	}
	return self;
}


- (void)dealloc {
	[environmentVariables release];
	[super dealloc];
}


#pragma mark -
#pragma mark XMLCatalogService

- (void)setPrefer:(NSInteger)n {
	//NSLog(@"setting prefer: %d", n);
	@synchronized(self) {
		xmlCatalogSetDefaultPrefer(1);
	}
}


- (void)putCatalogContents:(NSArray *)catalogContents {
	[NSThread detachNewThreadSelector:@selector(doPutCatalogContents:)
							 toTarget:self
						   withObject:catalogContents];
}


#pragma mark -
#pragma mark Private

- (void)doPutCatalogContents:(NSArray *)catalogContents {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized(self) {
		
		//NSLog(@"putCatalogContents: %@", catalogContents);
		
		if ([catalogContents count]) {
			xmlCatalogCleanup();
		}

		NSString *path = [self pathForXMLFileNamed:@"emptyCatalog"];
		xmlLoadCatalog([path UTF8String]);

		xmlInitializeCatalog();
		//char *envar = getenv("XML_CATALOG_FILES");
		//NSLog(@"XML_CATALOG_FILES: %s", envar);
		
		//NSLog(@"environmentVariables: %@", environmentVariables);

		NSEnumerator *e = [catalogContents objectEnumerator];
		CatalogItem *item;
		while (item = [e nextObject]) {
			int type = [item type];
			int err;
			if (!type) {
				err = xmlCatalogRemove([[item orig] xmlChar]);
				if (-1 == err) {
					err = 1;
				}
			} else {
				err = xmlCatalogAdd((const xmlChar *)typeNames[type], 
									[[item orig] xmlChar], 
									[[item replace] xmlChar]);
			}
			if (err) {
				[self error:nil];
				[pool release];
				return;
			}
		}
		
		NSString *XMLString = [self writeCatalogToDiskAndLoad];
		
		[self success:XMLString];
	}
	
	[pool release];
}


- (NSString *)writeCatalogToDiskAndLoad {
	NSString *path = [self pathForXMLFileNamed:@"catalog"];
	FILE *f = fopen([path UTF8String], "w");
	
	NSString *XMLString = nil;
	
	if (f) {
		xmlCatalogDump(f);		
		XMLString = [NSString stringWithContentsOfFile:path];
	}
	
	xmlLoadCatalog([path UTF8String]);

	return XMLString;
}


- (NSString *)pathForXMLFileNamed:(NSString *)name {
	NSString *path = [[XMLMatePlugIn bundle] resourcePath];
	path = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"xml"];
	return path;
}


- (void)success:(NSString *)XMLString {
	[self performSelectorOnMainThread:@selector(doSuccess:) withObject:XMLString waitUntilDone:NO];
}


- (void)doSuccess:(NSString *)XMLString {
	[delegate catalogService:self didUpdate:XMLString];
}


- (void)error:(NSDictionary *)errInfo {
	[self performSelectorOnMainThread:@selector(doError:) withObject:errInfo waitUntilDone:NO];
}


- (void)doError:(NSDictionary *)errInfo {
	[delegate catalogService:self didError:errInfo];	
}

@end
