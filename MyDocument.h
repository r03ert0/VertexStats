//
//  MyDocument.h
//  VertexStats
//
//  Created by rOBERTO tORO on 28/11/2007.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MyBrainView.h"
#include "fitmodel.h"
#include "fdr.h"

@interface MyDocument : NSDocument
{
	IBOutlet NSObjectController		*settings;
	IBOutlet NSTableView			*tableSubjects;
	IBOutlet NSTableView			*tableIndep;
	IBOutlet NSTableView			*tableModel;
	IBOutlet MyBrainView			*view;

	IBOutlet NSTextField			*progressMsg;
	IBOutlet NSTextField			*fdrValue;
	
	NSMutableArray		*dataSubjects;
	NSMutableArray		*variables;
	NSMutableArray		*modelVariables;
	NSMutableDictionary	*variablesRange;
	
	NSDictionary		*tmpdic;
    
    int changeEndianness;
}
-(void)parseSubjects;
-(void)fitModelNSubjects:(int)nsubjects nVariables:(int)nvariables nEffects:(int)neffects
			   pathIndep:(char *)path_in_indep pathDep:(char *)path_in_dep
			  hemisphere:(int)h model:(Model *)m
RSqr:(float *)rsqr FRatio:(float *)fratio eslope:(float *)eslope average:(float *)average;
-(IBAction)choosePath:(id)sender;
-(IBAction)changeEndianness:(id)sender;
-(IBAction)modelAdd:(id)sender;
-(IBAction)modelCross:(id)sender;
-(IBAction)modelRemove:(id)sender;
-(IBAction)fitModel:(id)sender;
-(IBAction)rotate:(id)sender;
-(IBAction)saveImage:(id)sender;
-(IBAction)saveData:(id)sender;
-(IBAction)showLeft:(id)sender;
-(IBAction)showRight:(id)sender;
-(IBAction)setFDR:(id)sender;
@end
