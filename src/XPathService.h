//
//  XPathService.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/1/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XMLParseCommand;

@protocol XPathService <NSObject>
- (id)initWithDelegate:(id)d;
- (void)executeQuery:(NSString *)XPathString withCommand:(XMLParseCommand *)c;
@end

@interface NSObject (XPathServiceDelegate)
- (void)xpathService:(id <XPathService>)service didFinish:(id)result;
- (void)xpathService:(id <XPathService>)service info:(id)info;
- (void)xpathService:(id <XPathService>)service error:(id)error;
- (void)xpathService:(id <XPathService>)service parseError:(id)error;
@end
