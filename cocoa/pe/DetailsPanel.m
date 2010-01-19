/* 
Copyright 2010 Hardcoded Software (http://www.hardcoded.net)

This software is licensed under the "HS" License as described in the "LICENSE" file, 
which should be included with this package. The terms are also available at 
http://www.hardcoded.net/licenses/hs_license
*/

#import "Utils.h"
#import "NSNotificationAdditions.h"
#import "NSImageAdditions.h"
#import "PyDupeGuru.h"
#import "DetailsPanel.h"
#import "Consts.h"

@implementation DetailsPanel
- (id)initWithPy:(PyApp *)aPy
{
    self = [super initWithPy:aPy];
    py = aPy;
    _needsRefresh = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoaded:) name:ImageLoadedNotification object:self];
    return self;
}

- (void)loadImageAsync:(NSString *)imagePath
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSImage *image = [[NSImage alloc] initByReferencingFile:imagePath];
    NSImage *thumbnail = [image imageByScalingProportionallyToSize:NSMakeSize(512,512)];
    [image release];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:imagePath forKey:@"imagePath"];
    [params setValue:thumbnail forKey:@"image"];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ImageLoadedNotification object:self userInfo:params waitUntilDone:YES];
    [pool release];
}

- (void)refresh
{
    if (!_needsRefresh)
        return;
    [detailsTable reloadData];
    
    NSString *refPath = [(PyDupeGuru *)py getSelectedDupeRefPath];
    if (_refPath != nil)
        [_refPath autorelease];
    _refPath = [refPath retain];
    [NSThread detachNewThreadSelector:@selector(loadImageAsync:) toTarget:self withObject:refPath];
    NSString *dupePath = [(PyDupeGuru *)py getSelectedDupePath];
    if (_dupePath != nil)
        [_dupePath autorelease];
    _dupePath = [dupePath retain];
    if (![dupePath isEqual: refPath])
        [NSThread detachNewThreadSelector:@selector(loadImageAsync:) toTarget:self withObject:dupePath];
    [refProgressIndicator startAnimation:nil];
    [dupeProgressIndicator startAnimation:nil];
    _needsRefresh = NO;
}

/* Notifications */
- (void)duplicateSelectionChanged:(NSNotification *)aNotification
{
    _needsRefresh = YES;
	[super duplicateSelectionChanged:aNotification];
}

- (void)imageLoaded:(NSNotification *)aNotification
{
    NSString *imagePath = [[aNotification userInfo] valueForKey:@"imagePath"];
    NSImage *image = [[aNotification userInfo] valueForKey:@"image"];
    if ([imagePath isEqual: _refPath])
    {
        [refImage setImage:image];
        [refProgressIndicator stopAnimation:nil];
    }
    if ([imagePath isEqual: _dupePath])
    {
        [dupeImage setImage:image];
        [dupeProgressIndicator stopAnimation:nil];
    }
}
@end