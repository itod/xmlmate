//
//  XMLMateController.h
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;
@class XMLParseCommand;
@protocol XMLParsingService;
@protocol XMLCatalogService;
@protocol XPathService;

@interface XMLMateController : NSWindowController {
	IBOutlet NSTabView *tabView;
	IBOutlet WebView *parseResultsWebView;
	IBOutlet NSComboBox *schemaURLComboBox;
	IBOutlet NSComboBox *xpathComboBox;
	IBOutlet NSButton *browseButton;
	IBOutlet NSTextView *sourceXMLTextView;
	IBOutlet NSTextView *catalogXMLTextView;
	IBOutlet NSTextView *xpathTreeTextView;
	IBOutlet NSTextView *xpathArrayTextView;
	IBOutlet NSView *bottomView;
	IBOutlet NSTableView *catalogTable;
	IBOutlet NSMenu *catalogItemTypeMenu;

	id <XMLCatalogService> catalogService;
	NSMutableArray *catalogItems;
	NSString *catalogXMLString;
	NSInteger preferedCatalogItemType;
	
	BOOL busy;
	BOOL showSettings;
	BOOL playSounds;

	id <XMLParsingService> parsingService;
	NSInteger errorCount;
	NSArray *contextMenuItems;
	XMLParseCommand *command;
	NSMutableArray *recentSchemaURLStrings;
	NSMutableArray *recentXPathStrings;
	NSString *sourceXMLString;
	
	id <XPathService> xpathService;
	NSString *XPathString;
	NSAttributedString *queryResultString;
	NSMutableString *queryConsoleString;
	NSInteger queryResultLength;
	NSArray *queryResultNodes;
}

- (IBAction)parameterWasChanged:(id)sender;
- (IBAction)validationTypeWasChanged:(id)sender;
- (IBAction)browse:(id)sender;
- (IBAction)parse:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)executeQuery:(id)sender;

@property (nonatomic) BOOL busy;
@property (nonatomic) BOOL showSettings;
@property (nonatomic) BOOL playSounds;
@property (nonatomic) NSInteger preferedCatalogItemType;
@property (nonatomic, retain) NSMutableArray *catalogItems;
@property (nonatomic, retain) XMLParseCommand *command;
@property (nonatomic, retain) NSMutableArray *recentSchemaURLStrings;
@property (nonatomic, retain) NSMutableArray *recentXPathStrings;
@property (nonatomic, copy) NSString *sourceXMLString;
@property (nonatomic, copy) NSString *catalogXMLString;

@property (nonatomic, copy) NSString *XPathString;
@property (nonatomic, copy) NSAttributedString *queryResultString;
@property (nonatomic, copy) NSMutableString *queryConsoleString;
@property (nonatomic) NSInteger queryResultLength;
@property (nonatomic, retain) NSArray *queryResultNodes;
@end
