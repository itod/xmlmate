//
//  XMLCatalogServiceLibxmlImpl.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/31/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libxml/catalog.h>

@protocol XMLCatalogService;

@interface XMLCatalogServiceLibxmlImpl : NSObject <XMLCatalogService> {
	id delegate;
	xmlCatalogPtr catalog;
	id environmentVariables;
}

@end
