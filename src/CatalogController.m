//
//  CatalogController.m
//  TeXMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/30/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "CatalogController.h"
#import "TeXMLMateController.h"
#import "XMLCatalogService.h"
#import "XMLCatalogServiceLibxmlImpl.h"

static NSString *const KeyXSLTParams	  = @"XSLTParams";
static NSString *const KeyXSLTParamsOrder = @"XSLTParamsOrder";
static NSString *const WhiteSpace		  = @" ";

@implementation CatalogController

- (id)init;
{
	self = [super init];
	if (self != nil) {
		service = [[XMLCatalogServiceLibxmlImpl alloc] initWithDelegate:self];
		
		NSDictionary *dict = [NSDictionary dictionary];
		NSMutableDictionary *d = [dict objectForKey:KeyXSLTParams];
		NSMutableArray *a = [dict objectForKey:KeyXSLTParamsOrder];
		if (!d) {
			d = [NSMutableDictionary dictionaryWithObject:WhiteSpace forKey:WhiteSpace];
			a = [NSMutableArray arrayWithObject:WhiteSpace];
		}
		[self setParams:d];
		[self setParamsOrder:a];
	}
	return self;
}


- (void)dealloc;
{
	[service release];
	[self setParams:nil];
	[self setParamsOrder:nil];
	[super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)insertParam:(id)sender;
{
	int index = [paramsTable selectedRow];
	[self insertParamAtIndex:index+1];
	[paramsTable reloadData];
}


- (IBAction)removeParam:(id)sender;
{
	int index = [paramsTable selectedRow];
	[self removeParamAtIndex:index];
	[paramsTable reloadData];
}


#pragma mark -
#pragma mark PrivateActions

- (void)handleTableClicked:(id)sender;
{
	lastClickedCol = [sender clickedColumn];
}


- (void)handleTextChanged:(id)sender;
{
	int rowIndex = [sender selectedRow];
	int colIndex = [sender clickedColumn];
	if (-1 == colIndex) {
		colIndex = lastClickedCol;
	}
	
	NSMutableDictionary *reqHeaders = [self params];
	
	if (0 == colIndex) { // name changed
		
		NSString *oldName = [headerOrder objectAtIndex:rowIndex];
		NSString *newName = [sender stringValue];
		NSString *value   = [reqHeaders objectForKey:oldName];
		[headerOrder replaceObjectAtIndex:rowIndex withObject:newName];
		[reqHeaders removeObjectForKey:oldName];
		[reqHeaders setObject:value forKey:newName];
		
	} else { // value changed
		
		NSString *name = [headerOrder objectAtIndex:rowIndex];
		NSString *value = [sender stringValue];
		[reqHeaders setObject:value forKey:name];
		
	}
}


#pragma mark -

- (void)updateFromDictionary:(NSDictionary *)dict;
{
	[self setupParamsTable];
	[self registerForNotifications];
}


- (void)writeToDictionary:(NSMutableDictionary *)dict;
{
	if (![self paramsAreEmpty]) {
		[dict setObject:params forKey:KeyXSLTParams];
	}
}


- (void)storeCatalogChanges;
{
	if (!isEdited) {
		return;
	}

	[mainController setBusy:YES];
	[service putCatalogContents:nil];
}


#pragma mark -
#pragma mark Protected

- (BOOL)paramsAreEmpty;
{
	return ([params count] == 0 || ([params count] == 1 && [[paramsOrder objectAtIndex:0] isEqualToString:WhiteSpace]));
}


- (void)setupParamsTable;
{	
	[paramsTable setTarget:self];
	[paramsTable setAction:@selector(handleTableClicked:)];
	
	NSButtonCell *cell = [[paramsTable tableColumnWithIdentifier:@"plus"] dataCell];
	[cell setTarget:self];
	[cell setAction:@selector(insertParam:)];
	[cell setImage:[self plusImage]];
	[cell setImagePosition:NSImageOnly];
	
	cell = [[paramsTable tableColumnWithIdentifier:@"minus"] dataCell];
	[cell setTarget:self];
	[cell setAction:@selector(removeParam:)];
	[cell setImage:[self minusImage]];
	[cell setImagePosition:NSImageOnly];
	
	NSPopUpButtonCell *pCell = [[paramsTable tableColumnWithIdentifier:@"type"] dataCell];
	[pCell setMenu:typePopupMenu];
	
	[paramsTable setNeedsDisplay:YES];
}


- (NSImage *)plusImage;
{
    float scaleFactor = 1.0;// hi dpi...? * [[NSScreen mainScreen] use
    float imageSize = 8 * scaleFactor;
    NSImage *result = [[[NSImage alloc] initWithSize:NSMakeSize(imageSize, imageSize)] autorelease];
    [result lockFocus];
    [[NSColor grayColor] set];
	
    // Horz line
    NSRectFill(NSMakeRect(0, 3 * scaleFactor, imageSize, 2 * scaleFactor));
    // Top part
    NSRectFill(NSMakeRect(3 * scaleFactor, 0, 2 * scaleFactor, 3 * scaleFactor));
    // Bottom part
    NSRectFill(NSMakeRect(3 * scaleFactor, imageSize - 3 * scaleFactor, 2 * scaleFactor, 3 * scaleFactor));
	
    [result unlockFocus];
	
    return result;
}


- (NSImage *)minusImage;
{
    float scaleFactor = 1.0;// hi dpi...? * [[NSScreen mainScreen] use
    float imageSize = 8 * scaleFactor;
    NSImage *result = [[[NSImage alloc] initWithSize:NSMakeSize(imageSize, imageSize)] autorelease];
    [result lockFocus];
    [[NSColor grayColor] set];
	
    // Horz line
    NSRectFill(NSMakeRect(0, 3 * scaleFactor, imageSize, 2 * scaleFactor));	
	
    [result unlockFocus];
	
    return result;
}


- (NSTextFieldCell *)textFieldCellWithTag:(int)tag;
{
	NSTextFieldCell *tfCell = [[NSTextFieldCell alloc] init];
	[tfCell setEditable:YES];
	[tfCell setFocusRingType:NSFocusRingTypeNone];
	[tfCell setControlSize:NSSmallControlSize];
	[tfCell setFont:[NSFont fontWithName:@"Lucida Grande" size:10.]];
	[tfCell setTarget:self];
	[tfCell setAction:@selector(handleTextChanged:)];
	[tfCell setTag:tag];
	return tfCell;
}


- (void)registerForNotifications;
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(controlTextDidChange:)
			   name:NSControlTextDidChangeNotification
			 object:paramsTable];
	
	[nc addObserver:self
		   selector:@selector(controlTextDidEndEditing:)
			   name:NSControlTextDidEndEditingNotification
			 object:paramsTable];
}


- (void)windowDidResize:(NSNotification *)aNotification;
{
	[paramsTable sizeToFit];
}


- (void)insertParamAtIndex:(int)index;
{
	[[self params] setObject:WhiteSpace forKey:WhiteSpace];
}


- (void)removeParamAtIndex:(int)index;
{
	NSString *name = [[self paramsOrder] objectAtIndex:index];
	[[self params] removeObjectForKey:name];
	[[self paramsOrder] removeObjectAtIndex:index];
	
	if (0 == index && 0 == [[self paramsOrder] count]) {
		[[self params] setObject:WhiteSpace forKey:WhiteSpace];
		[[self paramsOrder] addObject:WhiteSpace];
	}
	
}


#pragma mark -
#pragma mark NSTableDataSource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	return [[self params] count];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
{
	NSString *identifier = [aTableColumn identifier];
	NSString *name = [[self paramsOrder] objectAtIndex:rowIndex];
	
	if ([identifier isEqualToString:@"name"]) {
		return name;
	} else if ([identifier isEqualToString:@"value"]) {
		return [[self params] objectForKey:name];
	} else if ([identifier isEqualToString:@"buttons"]) {
		return [NSNumber numberWithInt:1];
	}
	return nil;
}


#pragma mark -
#pragma mark NSControlTextChangedNotification

- (void)controlTextDidChange:(NSNotification *)aNotification;
{
	id obj = [aNotification object];
	if (obj == paramsTable) {
		[self handleTextChanged:[aNotification object]];
		[[[NSDocumentController sharedDocumentController] currentDocument] updateChangeCount:NSChangeDone];
	}
}


#pragma mark -
#pragma mark NSControlTextChangedNotification

- (void)controlTextDidEndEditing:(NSNotification *)aNotification;
{
	if (0 == lastClickedCol) {
		lastClickedCol++;
	}
}


#pragma mark -
#pragma mark Accessors

- (NSMutableDictionary *)params;
{
	return params;
}


- (void)setParams:(NSMutableDictionary *)newParams;
{
	if (params != newParams) {
		[params autorelease];
		params = [newParams retain];
	}
}


- (NSMutableArray *)paramsOrder;
{
	return paramsOrder;
}


- (void)setParamsOrder:(NSMutableArray *)newOrder;
{
	if (paramsOrder != newOrder) {
		[paramsOrder autorelease];
		paramsOrder = [newOrder retain];
	}
}

@end