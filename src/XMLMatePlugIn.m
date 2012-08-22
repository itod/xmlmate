//
//  XMLMatePlugIn.m
//  XMLMatePlugIn
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XMLMatePlugIn.h"
#import "XMLParseCommand.h"
#import "XMLMateController.h"

//defaults write us.dalo.BlogMate floatingPanel -bool NO
//defaults write com.macromates.TextMate BlogMateFloatingPanel -bool NO

static NSString * const kFLoatingPanelKey			= @"XMLMateFloatingPanel";
static NSString * const XMLMateBundleIdentifier		= @"us.dalo.TeXMLMate";

static NSString * const PreferedCatalogItemTypeKey	= @"preferedCatalogItemType";
static NSString * const CatalogItemsKey				= @"catalogItems";
static NSString * const WindowFrameStringKey		= @"windowFrameString";
static NSString * const ShowSettingsKey				= @"showSettings";
static NSString * const PlaySoundsKey				= @"playSounds";
static NSString * const XMLParseCommandKey			= @"command";
static NSString * const RecentSchemaURLStrings		= @"recentSchemaURLStrings";
static NSString * const RecentXPathStrings			= @"recentXPathStrings";

static NSString * const PrefsFileName				= @"XMLMatePlugInPrefs";
static NSString * const PrefsFileExt				= @"plist";

@interface XMLMatePlugIn (Private)
- (void)initController;
- (void)determineFloatingPanelStatus;
- (void)loadPlugInPrefs;
- (void)savePlugInPrefs;
@end

@implementation XMLMatePlugIn

+ (void)initialize {
	//NSLog(@"registering defaults");
	NSDictionary *values = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kFLoatingPanelKey];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:values];
}


+ (NSBundle *)bundle {
	return [NSBundle bundleWithIdentifier:XMLMateBundleIdentifier];
}


- (id)initWithPlugInController:(id <TMPlugInController>)aController {
	self = [super init];
	if (self != nil) {
		NSApp = [NSApplication sharedApplication];
		[self installMenuItems];
	}
	return self;
}


- (void)dealloc {
	self.controller = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Public

- (void)installMenuItems {
    NSString *title = NSLocalizedString(@"Window", @"");
	id windowMenu = [[[NSApp mainMenu] itemWithTitle:title] submenu];
	
	if (windowMenu) {
		NSInteger idx = 0;
		NSArray *items = [windowMenu itemArray];
		for (NSInteger separators = 0; idx != [items count] && separators != 2; idx++)
			separators += [[items objectAtIndex:idx] isSeparatorItem] ? 1 : 0;
        
        NSString *title = NSLocalizedString(@"Show XMLMate Palette", @"");
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(showPalette:) keyEquivalent:@""];
		[menuItem setTarget:self];
		[windowMenu insertItem:menuItem atIndex:idx ? idx-1 : 0];
        [menuItem release];
	}
}


#pragma mark -
#pragma mark Actions

- (void)showPalette:(id)sender {
	[self initController];
	[self determineFloatingPanelStatus];
	[self loadPlugInPrefs];
	[controller showWindow:self];
}


#pragma mark -
#pragma mark Private

- (void)initController {
	@synchronized (self) {
		if (!controller) {
			[self setController:[[[XMLMateController alloc] init] autorelease]];
			
			NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

			[nc addObserver:self
				   selector:@selector(windowWillClose:)
					   name:NSWindowWillCloseNotification
					 object:[controller window]];			
		}
	}
}


- (void)determineFloatingPanelStatus {
	BOOL floatingPanel = [[NSUserDefaults standardUserDefaults] boolForKey:kFLoatingPanelKey];
	[(NSPanel *)[controller window] setFloatingPanel:floatingPanel];
	//[(NSPanel *)[self window] setHidesOnDeactivate:!floatingPanel];
}


- (void)loadPlugInPrefs {
	NSBundle *bundle = [XMLMatePlugIn bundle];
	NSString *path	 = [bundle pathForResource:PrefsFileName ofType:PrefsFileExt];
	
	NSDictionary *d = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	
	//int preferedCatalogItemType			   = [[d objectForKey:PreferedCatalogItemTypeKey] intValue];
	NSMutableArray *catalogItems		   = [NSMutableArray arrayWithArray:[d objectForKey:CatalogItemsKey]];
	NSString *windowFrameString			   = [d objectForKey:WindowFrameStringKey];
	BOOL showSettings					   = [[d objectForKey:ShowSettingsKey] boolValue];
	BOOL playSounds						   = [[d objectForKey:PlaySoundsKey] boolValue];
	XMLParseCommand *command			   = [d objectForKey:XMLParseCommandKey];
	NSMutableArray *recentSchemaURLStrings = [NSMutableArray arrayWithArray:[d objectForKey:RecentSchemaURLStrings]];
	NSMutableArray *recentXPathStrings	   = [NSMutableArray arrayWithArray:[d objectForKey:RecentXPathStrings]];

	if (!command) {
		command = [[[XMLParseCommand alloc] init] autorelease];
	}
	
	[controller setPreferedCatalogItemType:1];
	[controller setCatalogItems:catalogItems];
	[[controller window] setFrameFromString:windowFrameString];
	[controller setShowSettings:showSettings];
	[controller setPlaySounds:playSounds];
	[controller setCommand:command];
	[controller setRecentSchemaURLStrings:recentSchemaURLStrings];
	[controller setRecentXPathStrings:recentXPathStrings];
}


- (void)savePlugInPrefs {
	NSString *path = [[XMLMatePlugIn bundle] resourcePath];
	path = [[path stringByAppendingPathComponent:PrefsFileName] stringByAppendingPathExtension:PrefsFileExt];
		
	NSNumber *preferedCatalogItemType	= [NSNumber numberWithInt:[controller preferedCatalogItemType]];
	NSMutableArray *catalogItems		= [controller catalogItems];
	NSString *windowFrameString			= [[controller window] stringWithSavedFrame];
	NSNumber *showSettings				= [NSNumber numberWithBool:[controller showSettings]];
	NSNumber *playSounds				= [NSNumber numberWithBool:[controller playSounds]];
	XMLParseCommand *command			= [controller command];
	NSArray *recentSchemaURLStrings		= [controller recentSchemaURLStrings];
	NSArray *recentXPathStrings			= [controller recentXPathStrings];
	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
		preferedCatalogItemType, PreferedCatalogItemTypeKey,
		catalogItems, CatalogItemsKey,
		windowFrameString, WindowFrameStringKey,
		showSettings, ShowSettingsKey,
		playSounds, PlaySoundsKey,
		command, XMLParseCommandKey,
		recentSchemaURLStrings, RecentSchemaURLStrings,
		recentXPathStrings, RecentXPathStrings,
		nil];
	
	[NSKeyedArchiver archiveRootObject:d toFile:path];
}


#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowWillClose:(NSNotification *)n {	
	[self savePlugInPrefs];
	[self setController:nil];
}

@synthesize controller;
@end
