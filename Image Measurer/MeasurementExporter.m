//
//  MeasurementExporter.m
//  Image Measurer
//
//  Created by Loren Petrich on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MeasurementExporter.h"


NSString *Export(NSArray<NSMutableDictionary *> *Measurements)
{
    NSMutableString *Line = [NSMutableString stringWithCapacity:64];
    NSMutableString *Text = [NSMutableString stringWithCapacity:1024];
    
    for (NSDictionary *Measurement in Measurements)
    {
        NSNumber *X = [Measurement objectForKey:@"X"];
        NSNumber *Y = [Measurement objectForKey:@"Y"];
        NSNumber *XScld = [Measurement objectForKey:@"XScld"];
        NSNumber *YScld = [Measurement objectForKey:@"YScld"];
        NSNumber *R = [Measurement objectForKey:@"R"];
        NSNumber *G = [Measurement objectForKey:@"G"];
        NSNumber *B = [Measurement objectForKey:@"B"];
        NSNumber *A = [Measurement objectForKey:@"A"];
        NSString *Note = [Measurement objectForKey:@"Note"];
        
        [Line setString:@""];
        [Line appendFormat:@"%d\t",[X intValue]];
        [Line appendFormat:@"%d\t",[Y intValue]];
        [Line appendFormat:@"%lg\t",[XScld doubleValue]];
        [Line appendFormat:@"%lg\t",[YScld doubleValue]];
        [Line appendFormat:@"%d\t",[R intValue]];
        [Line appendFormat:@"%d\t",[G intValue]];
        [Line appendFormat:@"%d\t",[B intValue]];
        [Line appendFormat:@"%d\t",[A intValue]];
        [Line appendFormat:@"%@",Note];
        
        [Text appendFormat:@"%@\n", Line];
    }
    
    return Text;
}


void ExportToClipboard(NSArray<NSMutableDictionary *> *Measurements)
{
    NSString *Text = Export(Measurements);
    NSPasteboard *Clipboard = [NSPasteboard generalPasteboard];
    [Clipboard clearContents];
    [Clipboard writeObjects:[NSArray arrayWithObjects:Text, nil]];
}


void ExportToFile(NSArray<NSMutableDictionary *> *Measurements)
{
    NSString *Text = Export(Measurements);
    
    NSSavePanel *Saver = [NSSavePanel savePanel];
    [Saver setTitle:@"Export Measurements"];
    [Saver setPrompt:@"Export"];
    if ([Saver runModal] != NSFileHandlingPanelOKButton) return;
    NSURL *FilePath = [Saver URL];
    
    [Text writeToURL:FilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];    
}