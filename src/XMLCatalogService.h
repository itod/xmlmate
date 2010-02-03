//
//  XMLCatalogService.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/31/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XMLCatalogService <NSObject>
- (id)initWithDelegate:(id)aDelegate environmentVariables:(id)vars;
- (void)setPrefer:(NSInteger)n;
- (void)putCatalogContents:(NSArray *)catalogContents;
@end

@interface NSObject (XMLCatalogServiceDelegate)
- (void)catalogService:(id <XMLCatalogService>)service didUpdate:(NSString *)catalogXMLString;
- (void)catalogService:(id <XMLCatalogService>)service didError:(NSDictionary *)errInfo;
- (void)catalogService:(id <XMLCatalogService>)service setCatalogXMLString:(NSString *)newStr;
@end