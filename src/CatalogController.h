//
//  CatalogController.h
//  TeXMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/30/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TeXMLMateController;
@protocol XMLCatalogService;

@interface CatalogController : NSObject {
	IBOutlet TeXMLMateController *mainController;
	IBOutlet NSTableView *paramsTable;
	IBOutlet NSMenu *typePopupMenu;

	NSMutableDictionary *params;
	int lastClickedCol;

	id <XMLCatalogService> service;
	BOOL isEdited;
}

- (void)storeCatalogChanges;
- (void)updateFromDictionary:(NSDictionary *)dict;
- (void)writeToDictionary:(NSMutableDictionary *)dict;

- (IBAction)insertParam:(id)sender;
- (IBAction)removeParam:(id)sender;

- (void)handleTableClicked:(id)sender;
- (void)handleTextChanged:(id)sender;

- (void)insertParamAtIndex:(int)index;
- (void)removeParamAtIndex:(int)index;

- (void)setupParamsTable;
- (void)registerForNotifications;

- (NSImage *)plusImage;
- (NSImage *)minusImage;
- (NSTextFieldCell *)textFieldCellWithTag:(int)tag;
- (void)windowDidResize:(NSNotification *)aNotification;
- (BOOL)paramsAreEmpty;

- (NSMutableDictionary *)params;
- (void)setParams:(NSMutableDictionary *)newParams;
@end
