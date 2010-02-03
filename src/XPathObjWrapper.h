//
//  XPathObjWrapper.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/3/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libxml/xpath.h>

@interface XPathObjWrapper : NSObject {
	xmlXPathObjectPtr obj;
}
- (id)initWithObj:(xmlXPathObjectPtr)newObj;
- (xmlXPathObjectPtr)obj;
@end
