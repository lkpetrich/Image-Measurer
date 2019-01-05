//
//  ImageMeasurer.m
//  Image Measurer
//
//  Created by Loren Petrich on 5/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageMeasurer.h"
#import "MeasurementDisplayer.h"
#import "MeasurementExporter.h"

// Zoom limits
const int ZoomMin = -4;
const int ZoomMax = 4;

// Scale value from zoom value
static CGFloat ZoomToScale(int Zoom)
{
    CGFloat Scale = 1;
    if (Zoom > 0)
    {
        for (int z=0; z<Zoom; z++)
            Scale *= 2;
    }
    else if (Zoom < 0)
    {
        for (int z=0; z<(-Zoom); z++)
            Scale *= 0.5;
    }
    // Zoom = 0: no change
    return Scale;
}


// Color-channel values: 0 - 1 to 0 - 255 over entire range
int ChanFI(CGFloat chan)
{
    int ichn = (int)(256*chan);
    ichn = MAX(ichn,0);
    ichn = MIN(ichn,255);
    return ichn;
}


@implementation ImageMeasurer

- (id)init
{
    self = [super init];
    if (self) {
        // Init
        Zoom = 0;
        Image = nil;
        Measurements = [NSMutableArray arrayWithCapacity:16];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MeasurementsAltered:) name:@"Measurements Altered" object:nil];
        ScalingParametersInit(&SPs);
    }
    return self;
}


- (NSString *)windowNibName
{
    // Safest place to try to read from the clipboard -- before the nib is loaded
    
    // If an image has not already been loaded, then try to read the clipboard
    if (Image == nil)
    {
        Image = [ImageMeasurer GetClipboardImage];
        if (Image == nil) goto NoImage;
        BeepWhenMeasured = NO;
    }
    
    // For loading the nib
    return @"ImageMeasurer";
    
NoImage:
    // Clear it out
    [self close];
    return nil;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    // Set up for getting mouse clicks
    [ImageDisplay SetPositionReceiver:self];
    
    // Show everything
    ImageDisplay.Measurements = Measurements;
    [ImageDisplay SetShowMeas:[self GetShowPoints]];
    [ImageDisplay setImage:Image];
    NSSize Size = [Image size];
    [ImageDisplay setFrameSize:Size];
    [ImageDisplay SetZoom:Zoom];
    [ImageScroller setDocumentView:ImageDisplay];
    [ImageWidth setIntValue:(int)Size.width];
    [ImageHeight setIntValue:(int)Size.height];
    
    // Set up zoom popup menu
    // Items are tagged with their zoom values
    [ZoomPopup removeAllItems];
    for (int z=ZoomMin; z<=ZoomMax; z++)
    {
        NSString *Title;
        if (z < 0)
            Title = [NSString stringWithFormat:@"1/%d", (1 << (-z))];
        else if (z > 0)
            Title = [NSString stringWithFormat:@"%d", (1 << z)];
        else
            Title = @"1";
        [ZoomPopup addItemWithTitle:Title];
        [[ZoomPopup itemAtIndex:([ZoomPopup numberOfItems]-1)] setTag:z];
    }
    
    [ZoomPopup selectItemWithTag:Zoom];
    
    // Center the displayed image
    NSRect ClipBounds = [[ImageScroller documentView] frame];
    NSRect ContentBounds = [[ImageScroller contentView] bounds];
    NSInteger Width = NSMaxX(ClipBounds) - NSWidth(ContentBounds);
    NSInteger Height = NSMaxY(ClipBounds)- NSHeight(ContentBounds);
    
    NSPoint ScrollPoint = NSMakePoint(0.5*Width,0.5*Height);
    [[ImageScroller documentView] scrollPoint:ScrollPoint];
    
    NSString *CursorPath = [[NSBundle mainBundle] pathForResource:@"Pointer Crosshair" ofType:@"png"];
    if (CursorPath == nil)
    {
        [ImageScroller setDocumentCursor:[NSCursor crosshairCursor]];
        return;
    }
    
    NSImage *CursorImage = [[NSImage alloc] initWithContentsOfFile:CursorPath];
    if (CursorImage == nil)
    {
        [ImageScroller setDocumentCursor:[NSCursor crosshairCursor]];
        return;
    }
    
    NSSize CursorSize = [CursorImage size];
    NSPoint CursorPoint = NSMakePoint(0.5*(CursorSize.width-1),0.5*(CursorSize.height-1));
    NSCursor *Cursor = [[NSCursor alloc] initWithImage:CursorImage hotSpot:CursorPoint];
    [ImageScroller setDocumentCursor:Cursor];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    Image = [[NSImage alloc]initWithData:data];
    return (Image != nil);
}


+ (NSImage *)GetClipboardImage
{
    // The version from the clipboard won't be our final image
    NSPasteboard *Clipboard = [NSPasteboard generalPasteboard];
    NSImage *Image = [[NSImage alloc] initWithPasteboard:Clipboard];
    if (Image == nil) return nil;
    
    // Render the image so we'll have a bitmap version of it available
    NSBitmapImageRep *RenderedImage = [NSBitmapImageRep imageRepWithData: [Image TIFFRepresentation]];
    if (RenderedImage == nil) return nil;
    
    // Get the image size and create a new version of our image object with the right size
    NSInteger Width = [RenderedImage pixelsWide];
    NSInteger Height = [RenderedImage pixelsHigh];
    NSSize ImageSize = NSMakeSize(Width,Height);
    [RenderedImage setSize:ImageSize];
    Image = [[NSImage alloc] initWithSize:ImageSize];
    [Image addRepresentation:RenderedImage];
    
    return Image;
}


- (void)ReceivePosition:(NSPoint)Point Tag:(NSString *)Tag
{
    // Received point is in window coordinates
    // Need them in scroll-pane coordinates
    NSPoint CvtPoint = [ImageScroller convertPoint:Point fromView:nil];
    
    // Find the visible rectangle's origin point
    // The image displayer is in flipped coordinates, which makes this code work properly
    NSRect ImageViewport = [ImageScroller documentVisibleRect];
    NSPoint ImvpOrigin = ImageViewport.origin;
    
    // The point!
    // Convert from 1-based to 0-based
    int X = (int)(ImvpOrigin.x + CvtPoint.x) - 1;
    int Y = (int)(ImvpOrigin.y + CvtPoint.y) - 1;
    
    if (Zoom > 0)
    {
        X >>= Zoom;
        Y >>= Zoom;
    }
    else if (Zoom < 0)
    {
        X <<= (-Zoom);
        Y <<= (-Zoom);
    }
    
    // Scale the point position
    double XScld = [self GetScaledX:X and:Y];
    double YScld = [self GetScaledY:X and:Y];
    
    // Get the color
    int Range = (int)[[ColorAvgPopup selectedItem] tag];
    int NumValues = 0;
    CGFloat IndivColor[4], AvgColor[4] = {0, 0, 0, 0};
    
    [Image lockFocusFlipped:YES];
    for (int dx=-Range; dx<=Range; dx++)
        for (int dy=-Range; dy<=Range; dy++)
        {
            NSColor *PointColor = NSReadPixel(NSMakePoint(X+dx,Y+dy));
            if (PointColor == nil) continue;
            NumValues++;
            [PointColor getComponents:IndivColor];
            for (int ic=0; ic<4; ic++)
                AvgColor[ic] += IndivColor[ic];
        }
    [Image unlockFocus];
    
    if (NumValues > 0)
    {
        CGFloat NVRecip = ((CGFloat)1)/NumValues;
        for (int ic=0; ic<4; ic++)
            AvgColor[ic] *= NVRecip;
    }
    
    int R = ChanFI(AvgColor[0]);
    int G = ChanFI(AvgColor[1]);
    int B = ChanFI(AvgColor[2]);
    int A = ChanFI(AvgColor[3]);
    
    if ([Tag isEqualToString:@"Hover"])
    {
        [Hover_OutX setIntValue:X];
        [Hover_OutY setIntValue:Y];
        [Hover_OutXScld setDoubleValue:XScld];
        [Hover_OutYScld setDoubleValue:YScld];
        [Hover_OutR setIntValue:R];
        [Hover_OutG setIntValue:G];
        [Hover_OutB setIntValue:B];
        [Hover_OutA setIntValue:A];
    }
    else if ([Tag isEqualToString:@"Click"])
    {
        [Click_OutX setIntValue:X];
        [Click_OutY setIntValue:Y];
        [Click_OutXScld setDoubleValue:XScld];
        [Click_OutYScld setDoubleValue:YScld];
        [Click_OutR setIntValue:R];
        [Click_OutG setIntValue:G];
        [Click_OutB setIntValue:B];
        [Click_OutA setIntValue:A];
        
        // Put this measurement onto the list
        NSNumber *NX = [NSNumber numberWithInt:X];
        NSNumber *NY = [NSNumber numberWithInt:Y];
        NSNumber *NXScld = [NSNumber numberWithDouble:XScld];
        NSNumber *NYScld = [NSNumber numberWithDouble:YScld];
        NSNumber *NR = [NSNumber numberWithInt:R];
        NSNumber *NG = [NSNumber numberWithInt:G];
        NSNumber *NB = [NSNumber numberWithInt:B];
        NSNumber *NA = [NSNumber numberWithInt:A];
        NSString *Note = [NoteField stringValue];
        // It's mutable so one can edit the notes in the table
        NSMutableDictionary *Measurement =
            [NSMutableDictionary dictionaryWithObjectsAndKeys:
             NX, @"X", NY, @"Y", NXScld, @"XScld", NYScld, @"YScld",
                NR, @"R", NG, @"G", NB, @"B", NA, @"A",
                    Note, @"Note", nil];
        [Measurements addObject:Measurement];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Measurements Altered" object:self];
        
        // Audio feedback
        if (BeepWhenMeasured) NSBeep();
   }
}


- (double)GetScaledX: (double)OrigX and:(double)OrigY
{
    const int SI = 0;
    return SPs.Matrix[SI][0]*OrigX + SPs.Matrix[SI][1]*OrigY + SPs.Matrix[SI][2];
}

- (double)GetScaledY: (double)OrigX and:(double)OrigY
{
    const int SI = 1;
    return SPs.Matrix[SI][0]*OrigX + SPs.Matrix[SI][1]*OrigY + SPs.Matrix[SI][2];
}

- (void)MeasurementsAltered:(NSNotification *)Notification
{
    for (NSMutableDictionary *Measurement in Measurements)
    {
        NSNumber *NX = [Measurement objectForKey:@"X"];
        NSNumber *NY = [Measurement objectForKey:@"Y"];
        double X = [NX doubleValue];
        double Y = [NY doubleValue];
        double XScld = [self GetScaledX:X and:Y];
        double YScld = [self GetScaledY:X and:Y];
        NSNumber *NXScld = [NSNumber numberWithDouble:XScld];
        NSNumber *NYScld = [NSNumber numberWithDouble:YScld];
        [Measurement setObject:NXScld forKey:@"XScld"];
        [Measurement setObject:NYScld forKey:@"YScld"];
    }
    
    if ([self GetShowPoints]) [self UpdateImage];
}


- (IBAction)ZoomReset: (id)sender
{
    [self ZoomNewValue:0];
}

- (IBAction)ZoomIn: (id)sender
{
    [self ZoomNewValue:Zoom+1];
}

- (IBAction)ZoomOut: (id)sender
{
    [self ZoomNewValue:Zoom-1];
}

- (IBAction)ZoomSelected: (id)sender
{
    [self ZoomNewValue:((int)[[ZoomPopup selectedItem] tag])];
}

- (void)ZoomNewValue: (int)NewZoom
{
    // Clamp the new zoom value
    int ClampedNewZoom = NewZoom;
    ClampedNewZoom = MIN(ClampedNewZoom,ZoomMax);
    ClampedNewZoom = MAX(ClampedNewZoom,ZoomMin);
    
    // No change: don't do anything
    if (ClampedNewZoom == Zoom) return;
    
    // Changed
    Zoom = NewZoom;
    [ZoomPopup selectItemWithTag:Zoom];
    
    [self UpdateImage];
}

- (void)UpdateImage
{
    // Get the unscaled center point before continuing
    CGFloat Scale = ZoomToScale(Zoom);
    NSRect ImageViewport = [ImageScroller documentVisibleRect];
    NSPoint ImvpOrigin = ImageViewport.origin;
    NSSize ImvpSize = ImageViewport.size;
    CGFloat CenX = (ImvpOrigin.x + 0.5*ImvpSize.width)/Scale;
    CGFloat CenY = (ImvpOrigin.y + 0.5*ImvpSize.height)/Scale;
    
    
    // Find the zoomed size
    NSSize Size = [Image size];
    Scale = ZoomToScale(Zoom);
    NSSize NewSize = NSMakeSize(Scale*Size.width, Scale*Size.height);
    
    // Put in the zoomed image
    NSArray *Reps = [Image representations];
    NSImage *ZoomedImage = [[NSImage alloc] initWithSize:NewSize];
    [ZoomedImage addRepresentations:Reps];
    [ImageDisplay setImage:ZoomedImage];
    [ImageDisplay setFrameSize:NewSize];
    [ImageDisplay SetZoom:Zoom];
    
    // Scroll it so that it stays centered on the previous center
    ImageViewport = [ImageScroller documentVisibleRect];
    ImvpSize = ImageViewport.size;
    CGFloat OrgX = Scale*CenX - 0.5*ImvpSize.width;
    CGFloat OrgY = Scale*CenY - 0.5*ImvpSize.height;
    
    NSPoint ScrollPoint = NSMakePoint(OrgX,OrgY);
    [[ImageScroller documentView] scrollPoint:ScrollPoint];
}


- (void)CopyImage: (id)sender
{
    NSPasteboard *Clipboard = [NSPasteboard generalPasteboard];
    [Clipboard clearContents];
    [Clipboard writeObjects:[NSArray arrayWithObjects:Image, nil]];
}

- (IBAction)CopyMeasurement: (id)sender
{
    int X = [Click_OutX intValue];
    int Y = [Click_OutY intValue];
    double XScld = [Click_OutXScld doubleValue];
    double YScld = [Click_OutYScld doubleValue];
    int R = [Click_OutR intValue];
    int G = [Click_OutG intValue];
    int B = [Click_OutB intValue];
    int A = [Click_OutA intValue];
    NSString *Note = [NoteField stringValue];
    NSString *Measurement =
        [NSString stringWithFormat:@"%d, %d, %lg, %lg, %d, %d, %d, %d, %@",
            X, Y, XScld, YScld, R, G, B, A, Note];
  
    NSPasteboard *Clipboard = [NSPasteboard generalPasteboard];
    [Clipboard clearContents];
    [Clipboard writeObjects:[NSArray arrayWithObjects:Measurement, nil]];
}

- (IBAction)ShowMeasurements: (id)sender
{
    // Create measurements displayer
    MeasurementDisplayer *Display =
        [[MeasurementDisplayer alloc] initWithWindowNibName:@"MeasurementDisplayer"];
    
    // Add the content stuff
    Display.Measurements = Measurements;
    Display->SPs = &SPs;
    
    // Treat this new window as a child window of the main one
    [self addWindowController:Display];
    
    // Retitle it
    NSWindow *Window = [Display window];
    [Window setTitle:[NSString stringWithFormat:@"%@ Measurements", [self displayName]]];
    
    // For alerting it to additional measurements
    [[NSNotificationCenter defaultCenter] addObserver:Display selector:@selector(MeasurementsAltered:) name:@"Measurements Altered" object:nil];
    
    // All done
    [Display showWindow:self];
}


- (void)windowWillClose:(NSNotification *)notification
{
    // Since the document's window is the main window,
    // closing it will close everything
    [self close];
}


- (IBAction)CopyMeasurements: (id)sender
{
    ExportToClipboard(Measurements);
}

- (IBAction)ExportMeasurements: (id)sender
{
    ExportToFile(Measurements);
}


- (IBAction)ToggleBeepWhenMeasured:(id)sender
{
    NSMenuItem *ToggleBeepItem = sender;
    NSInteger State = [ToggleBeepItem state];
    if (State == NSOnState)
    {
        BeepWhenMeasured = NO;
        [ToggleBeepItem setState:NSOffState];
    }
    else
    {
        BeepWhenMeasured = YES;
        [ToggleBeepItem setState:NSOnState];
    }
}

- (BOOL)GetShowPoints
{
    NSInteger State = [ShowPointsCheckbox state];
    return (State == NSOnState);
}

- (IBAction)ToggleShowPoints: (id) sender
{
    [ImageDisplay SetShowMeas:[self GetShowPoints]];
    
    [self UpdateImage];
}


@end
