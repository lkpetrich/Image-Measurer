//
//  MeasurementDisplayer.m
//  Image Measurer
//
//  Created by Loren Petrich on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MeasurementDisplayer.h"
#import "MeasurementExporter.h"


@implementation MeasurementDisplayer

@synthesize Measurements;
@synthesize SPDisplay;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Just in case
        SPs = NULL;
        // Load up the display object
        SPDisplay = [[NSMutableArray alloc] init];
        for (int i=0; i<NUMBER_OF_POINTS; i++)
        {
            NSNumber *NX = [NSNumber numberWithInt:0];
            NSNumber *NY = [NSNumber numberWithInt:0];
            NSNumber *NXScld = [NSNumber numberWithDouble:0.];
            NSNumber *NYScld = [NSNumber numberWithDouble:0.];
            NSMutableDictionary *SPDRow =
                [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    NX, @"X", NY, @"Y", NXScld, @"XScld", NYScld, @"YScld", nil];
            [SPDisplay addObject:SPDRow];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)windowDidLoad
{
    // Get it in, of course
    [self LoadScalingParameters];
}


- (void)MeasurementsAltered:(NSNotification *)Notification
{
    // Update all the data management
    [MeasController setContent:self.Measurements];
    [self LoadScalingParameters];
}


- (void)LoadScalingParameters
{
    // Just in case
    if (SPs == NULL) return;
    
    [ScalingType selectItemAtIndex:SPs->Type];
    
    for (int i=0; i<NUMBER_OF_POINTS; i++)
    {
        NSMutableDictionary *Row = (NSMutableDictionary *)[SPDisplay objectAtIndex:i];
        
        NSNumber *NX = [NSNumber numberWithDouble:SPs->Points[i][0][0]];
        NSNumber *NY = [NSNumber numberWithDouble:SPs->Points[i][1][0]];
        NSNumber *NXScld = [NSNumber numberWithDouble:SPs->Points[i][0][1]];
        NSNumber *NYScld = [NSNumber numberWithDouble:SPs->Points[i][1][1]];
        
        [Row setObject:NX forKey:@"X"];
        [Row setObject:NY forKey:@"Y"];
        [Row setObject:NXScld forKey:@"XScld"];
        [Row setObject:NYScld forKey:@"YScld"];
    }
    
    [UseExplicitLength setIntValue:(SPs->UseExplicitLength != 0 ? NSOnState : NSOffState)];
    [ExplicitLength setDoubleValue:(SPs->ExplicitLength)];
}

- (void)SaveScalingParameters
{
    // Just in case
    if (SPs == NULL) return;
    
    SPs->Type = (enum ScalingTypes)([ScalingType indexOfSelectedItem]);
    
    for (int i=0; i<NUMBER_OF_POINTS; i++)
    {
        NSMutableDictionary *Row = (NSMutableDictionary *)[SPDisplay objectAtIndex:i];
        
        NSNumber *NX = (NSNumber *)[Row objectForKey:@"X"];
        NSNumber *NY = (NSNumber *)[Row objectForKey:@"Y"];
        NSNumber *NXScld = (NSNumber *)[Row objectForKey:@"XScld"];
        NSNumber *NYScld = (NSNumber *)[Row objectForKey:@"YScld"];
        
        SPs->Points[i][0][0] = [NX doubleValue];
        SPs->Points[i][1][0] = [NY doubleValue];
        SPs->Points[i][0][1] = [NXScld doubleValue];
        SPs->Points[i][1][1] = [NYScld doubleValue];
    }
    
    SPs->UseExplicitLength = ([UseExplicitLength intValue] != NSOffState) ? 1 : 0;
    SPs->ExplicitLength = [ExplicitLength doubleValue];
    
    ScalingParametersUpdate(SPs);
}


- (IBAction)UseScalingType: (id)sender
{
    SPs->Type = (enum ScalingTypes)([ScalingType indexOfSelectedItem]);
    
    ScalingParametersUpdate(SPs);
}

- (IBAction)UseSelectionInSPs: (id)sender
{
    NSUInteger SrcSel = [MeasController selectionIndex];
    if (SrcSel == NSNotFound) return;
    
    NSUInteger DstSel = [SPDController selectionIndex];
    if (DstSel == NSNotFound) return;
    
    NSMutableDictionary *SrcRow = (NSMutableDictionary *)[Measurements objectAtIndex:SrcSel];
    NSMutableDictionary *DstRow = (NSMutableDictionary *)[SPDisplay objectAtIndex:DstSel];
    
    NSNumber *NX = (NSNumber *)[SrcRow objectForKey:@"X"];
    NSNumber *NY = (NSNumber *)[SrcRow objectForKey:@"Y"];
    
    [DstRow setObject:[NX copy] forKey:@"X"];
    [DstRow setObject:[NY copy] forKey:@"Y"];
    
    // Update the scaling matrix from the data
    [self SaveScalingParameters];
}

- (IBAction)Rescale: (id)sender
{
    // Update the scaling matrix from the data
    [self SaveScalingParameters];
    
    // All that one needs to do
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Measurements Altered" object:self];
}


- (IBAction)copy: (id)sender
{
    ExportToClipboard(Measurements);
}

- (IBAction)ExportMeasurements: (id)sender
{
    ExportToFile(Measurements);
}

- (IBAction)DeleteSelection: (id)sender
{
    NSAlert *ReallyWantToDelete = [[NSAlert alloc] init];
    [ReallyWantToDelete addButtonWithTitle:@"Proceed"];
    [ReallyWantToDelete addButtonWithTitle:@"Cancel"];
    [ReallyWantToDelete setMessageText:@"Delete the selection?"];
    [ReallyWantToDelete setInformativeText:@"A deleted selection cannot be restored."];
    [ReallyWantToDelete setAlertStyle:NSCriticalAlertStyle];
    
    if ([ReallyWantToDelete runModal] != NSAlertFirstButtonReturn) return;
    
    // Do the deleting
    NSIndexSet *SelIxs = [MeasController selectionIndexes];
    [Measurements removeObjectsAtIndexes: SelIxs];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Measurements Altered" object:self];
}


@end
