//
//  XPathObjWrapper.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 1/3/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "XPathObjWrapper.h"

@implementation XPathObjWrapper

- (id)initWithObj:(xmlXPathObjectPtr)newObj {
	self = [super init];
	if (self != nil) {
		obj = newObj;
	}
	return self;
}


- (void)dealloc {
	if (NULL != obj) {
		xmlXPathFreeObject(obj);
		obj = NULL;
	}
	[super dealloc];
}


- (xmlXPathObjectPtr)obj {
	return obj;
}

@end
