//
//  NSXMLDocument+SyntaxHighlite.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/6/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSXMLNode (SyntaxHighlite)
- (NSAttributedString *)highlitedAttributedStringWithSelectedXPaths:(NSArray *)xpaths;
- (NSAttributedString *)highlitedAttributedStringForAttributeWithSelectedXPaths:(NSArray *)xpaths;
- (NSAttributedString *)highlitedAttributedStringForCommentWithSelectedXPaths:(NSArray *)xpaths;
- (NSAttributedString *)highlitedAttributedStringForPIWithSelectedXPaths:(NSArray *)xpaths;
- (NSAttributedString *)highlitedAttributedStringForTextWithSelectedXPaths:(NSArray *)xpaths;
@end

@interface NSXMLElement (SyntaxHighlite)
- (NSString *)startTagXMLString;
- (NSString *)endTagXMLString;

// returns true if this element has attributes or explicit namespace declarations (contains quote symbol in start tag)
- (BOOL)isDecorated;

// returns true if no close tag <foo/>
- (BOOL)isEmpty;
@end
