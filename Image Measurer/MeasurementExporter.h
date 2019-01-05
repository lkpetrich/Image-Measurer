//
//  MeasurementExporter.h
//  Image Measurer
//
//  Created by Loren Petrich on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSString *Export(NSArray<NSMutableDictionary *> *Measurements);

void ExportToClipboard(NSArray<NSMutableDictionary *> *Measurements);
void ExportToFile(NSArray<NSMutableDictionary *> *Measurements);
