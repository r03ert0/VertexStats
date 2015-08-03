//
//  MyDocument.m
//  VertexStats
//
//  Created by rOBERTO tORO on 28/11/2007.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self)
	{
		modelVariables=[NSMutableArray new];
		tmpdic=NULL;
        changeEndianness=NO;
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	if(tmpdic)
	{
		id	obj;
		obj=[tmpdic valueForKey:@"pathLeftData"];
		if(obj) [[settings content] setValue:obj forKey:@"pathLeftData"];
		obj=[tmpdic valueForKey:@"pathRightData"];
		if(obj) [[settings content] setValue:obj forKey:@"pathRightData"];
		obj=[tmpdic valueForKey:@"pathSubjectsData"];
		if(obj)
		{
			[[settings content] setValue:obj forKey:@"pathSubjectsData"];
			[self parseSubjects];
		}
	}
	[view setSettings:settings];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	if([aType isEqual:@"DocumentType"])
	{
		NSMutableDictionary	*dic=[[NSMutableDictionary new] autorelease];
		id	obj;
		obj=[[settings content] valueForKey:@"pathLeftData"];
		if(obj) [dic setObject:obj forKey:@"pathLeftData"];
		obj=[[settings content] valueForKey:@"pathRightData"];
		if(obj) [dic setObject:obj forKey:@"pathRightData"];
		obj=[[settings content] valueForKey:@"pathSubjectsData"];
		if(obj) [dic setObject:obj forKey:@"pathSubjectsData"];
		
		return [[dic description] dataUsingEncoding:NSUnicodeStringEncoding];
	}
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	if([aType isEqual:@"DocumentType"])
   {
	   NSString	*str=[[[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding] autorelease];
	   tmpdic=[str propertyList];
   }
    return YES;
}
#pragma mark -
-(void)parseSubjects
{
	NSString			*file=[[settings content] objectForKey:@"pathSubjectsData"];
	FILE				*f=fopen([file UTF8String],"r");
	char				str[1024],*pch;
	int					i,j;
	NSMutableDictionary	*data;
	NSTableColumn		*col;
	id					obj;
	
	// get variables
	variables=[NSMutableArray new];
	fgets(str,1024,f);
	pch=strtok(str," \t\n\r");
	while(pch!=NULL)
	{
		[variables addObject:[NSString stringWithUTF8String:pch]];
		pch=strtok (NULL," \t\n\r");
	}
	for(i=0;i<[variables count];i++)
	{
		// add variables as columns to the subjects tableview
		col=[[NSTableColumn alloc] initWithIdentifier:[variables objectAtIndex:i]];
		[[col headerCell] setStringValue:[variables objectAtIndex:i]];
		[tableSubjects addTableColumn:col];
		[col release];
	}
	
	// get row values
	dataSubjects=[NSMutableArray new];
	while(!feof(f))
	{
		data=[NSMutableDictionary new];
		[data autorelease];
		if(fgets(str,1024,f)==NULL)
			continue;
		pch=strtok(str," \t\n\r");
		i=0;
		while(pch!=NULL)
		{
			[data	setObject:[NSString stringWithUTF8String:pch]
					forKey:[variables objectAtIndex:i++]];
			pch=strtok (NULL," \t\n\r");
		}
		[dataSubjects addObject:data];
	}
	fclose(f);
	[tableSubjects reloadData];
	
	// get range of variables
	if(variablesRange)
		[variablesRange release];
	variablesRange=[NSMutableDictionary new];
	for(j=0;j<[variables count];j++)
	{
		NSMutableArray	*range=[NSMutableArray new];
		for(i=0;i<[dataSubjects count];i++)
		{
			obj=[[dataSubjects objectAtIndex:i] objectForKey:[variables objectAtIndex:j]];
			if(obj==nil)
				continue;
			if([range containsObject:obj]==FALSE)
				[range addObject:obj];
		}
        [range sortUsingComparator:^(id obj1, id obj2){return [obj1 compare:obj2];}];
        
		[variablesRange setObject:range forKey:[variables objectAtIndex:j]];
		[range release];
	}
}
- (IBAction)choosePath:(id)sender
{
    NSOpenPanel *op=[NSOpenPanel openPanel];
	NSString	*filename;
    int			result;
	int			tag;
    
    result=[op runModal];
    if (result!=NSOKButton)
		return;

	filename=[[[op URLs] objectAtIndex:0] path];
	tag=[sender tag];
	switch(tag)
	{
		case 1: // left
			[[settings content] setValue:filename forKey:@"pathLeftData"];
			[self updateChangeCount:NSChangeDone];
			break;
		case 2: // right
			[[settings content] setValue:filename forKey:@"pathRightData"];
			[self updateChangeCount:NSChangeDone];
			break;
		case 3: // average brain
			[[settings content] setValue:filename forKey:@"pathAverageBrain"];
			[self updateChangeCount:NSChangeDone];
			break;
		case 10: // subjects
			[[settings content] setValue:filename forKey:@"pathSubjectsData"];
			[self updateChangeCount:NSChangeDone];
			[self parseSubjects];
			break;
	}
	
}
-(IBAction)changeEndianness:(id)sender
{
    changeEndianness=[sender intValue];
}
-(float)meanVariable:(int)indx
{
	int		i;
	float	mean=0;
	NSString	*var=[variables objectAtIndex:indx];
	for(i=0;i<[dataSubjects count];i++)
		mean+=[[[dataSubjects objectAtIndex:i] objectForKey:var] floatValue];
	mean=mean/(double)[dataSubjects count];
	return mean;
}
-(void)encodeVariable:(NSString*)var inEffect:(Effect*)e
{
	NSString	*var1,*var2;
	int			i1,i2,isInteraction=0;
	
	
	NSRange	r=[var rangeOfString:@"*"];
	if(r.length==1) // if variable is an interaction
	{
		isInteraction=1;
		var1=[var substringWithRange:(NSRange){0,r.location}];
		var2=[var substringWithRange:(NSRange){r.location+1,[var length]-r.location-1}];
		i1=[variables indexOfObject:var1];
		i2=[variables indexOfObject:var2];
	}
	else
	{
		var1=var;
		i1=[variables indexOfObject:var];
	}
	
	if(isInteraction)
	{
		if([[variablesRange objectForKey:var1] count]==2 && [[variablesRange objectForKey:var2] count]==2)
		{
			e->type=kCC;
			e->e1=i1-1;
			e->e2=i2-1;
			e->m1=[self meanVariable:i1];
			e->m2=[self meanVariable:i2];
		}
		else
		if([[variablesRange objectForKey:var1] count]==2 && [[variablesRange objectForKey:var2] count]>2)
		{
			e->type=kCQ;
			e->e1=i1-1;
			e->e2=i2-1;
			e->m1=[self meanVariable:i1];
			e->m2=[self meanVariable:i2];
		}
		else
		if([[variablesRange objectForKey:var1] count]>2 && [[variablesRange objectForKey:var2] count]==2)
		{
			e->type=kCQ;
			e->e1=i2-1;
			e->e2=i1-1;
			e->m1=[self meanVariable:i2];
			e->m2=[self meanVariable:i1];
		}
		else
		if([[variablesRange objectForKey:var1] count]>2 && [[variablesRange objectForKey:var2] count]>2)
		{
			e->type=kQQ;
			e->e1=i1-1;
			e->e2=i2-1;
			e->m1=[self meanVariable:i1];
			e->m2=[self meanVariable:i2];
		}
	}
	else
	{
		if([[variablesRange objectForKey:var1] count]==2)
		{
			e->type=kC;
			e->e1=i1-1;
			e->m1=[self meanVariable:i1];
		}
		else
		{
			e->type=kQ;
			e->e1=i1-1;
			e->m1=[self meanVariable:i1];
		}
	}
}
-(NSString*)encodeForDisplayVariable:(NSString*)var
{
	NSString	*var0,*var1,*encoded;
	int			isInteraction=0;
	
	
	NSRange	r=[var rangeOfString:@"*"];
	if(r.length==1) // if variable is an interaction
	{
		isInteraction=1;
		var0=[var substringWithRange:(NSRange){0,r.location}];
		var1=[var substringWithRange:(NSRange){r.location+1,[var length]-r.location-1}];
	}
	else
		var0=var;
	
	if(isInteraction)
	{
		if([[variablesRange objectForKey:var0] count]==2)					// var is binary
			var0=[NSString stringWithFormat:@"(1-2*%@)",var0];
		else
			var0=[NSString stringWithFormat:@"(%@-Mean(%@))",var0,var0];
		if([[variablesRange objectForKey:var1] count]==2)					// var is binary
			var1=[NSString stringWithFormat:@"(1-2*%@)",var1];
		else
			var1=[NSString stringWithFormat:@"(%@-Mean(%@))",var1,var1];
		encoded=[NSString stringWithFormat:@"%@*%@",var0,var1];
	}
	else
	{
		if([[variablesRange objectForKey:var0] count]==2)					// var is binary
			var0=[NSString stringWithFormat:@"(1-2*%@)",var0];
		encoded=var0;
	}

	return encoded;
}
-(void)updateModel
{
	int				i,ieffect=[[tableModel selectedRowIndexes] firstIndex];
	NSMutableString	*modelFull=[NSMutableString stringWithString:@"1*b0"];
	NSMutableString	*modelPartial=[NSMutableString stringWithString:@"1*b0"];
	NSString		*var,*effect;
	
	for(i=0;i<[modelVariables count];i++)
	{
		var=[modelVariables objectAtIndex:i];
		effect=[NSString stringWithFormat:@" + %@*b%i",[self encodeForDisplayVariable:var],i+1];

		[modelFull appendString:effect];
		if(i!=ieffect)
			[modelPartial appendString:effect];
	}
	
	[[settings content] setValue:[modelVariables objectAtIndex:ieffect] forKey:@"modelEffect"];
	[[settings content] setValue:modelFull forKey:@"modelFull"];
	[[settings content] setValue:modelPartial forKey:@"modelPartial"];
}
-(IBAction)modelAdd:(id)sender
{
	NSIndexSet	*is=[tableIndep selectedRowIndexes];
	id			var;
	int			i;
	
	for(i=0;i<[variables count];i++)
		if([is containsIndex:i])
		{
			var=[variables objectAtIndex:i];
			if([modelVariables containsObject:var]==NO)
				[modelVariables addObject:var];
		}
	[tableModel reloadData];
	[self updateModel];
}
-(IBAction)modelCross:(id)sender
{
	NSIndexSet	*is=[tableIndep selectedRowIndexes];
	id			var;
	
	if([is count]!=2)
	{
		printf("Only 2 variable interactions are handled.\n");
		return;
	}

	var=[NSString stringWithFormat:@"%@*%@",[variables objectAtIndex:[is firstIndex]],[variables objectAtIndex:[is lastIndex]]];
	if([modelVariables containsObject:var]==NO)
		[modelVariables addObject:var];

	[tableModel reloadData];
	[self updateModel];
}
-(IBAction)modelRemove:(id)sender
{
	NSIndexSet	*is=[tableModel selectedRowIndexes];
	[modelVariables removeObjectAtIndex:[is firstIndex]];
	[tableModel reloadData];
	[self updateModel];
}
-(void)fitModelNSubjects:(int)nsubjects nVariables:(int)nvariables nEffects:(int)neffects
				pathIndep:(char *)path_in_indep pathDep:(char *)path_in_dep
				hemisphere:(int)h model:(Model *)m
                RSqr:(float *)rsqr FRatio:(float *)fratio eslope:(float *)eslope average:(float *)average
{
	// data
	FILE	*f;
	float	*alldep;
	double	*dep;
	double	*sig;
	char	str[1024],tmp[4];
	// results
	int		ma;
	double	*a;
	double	**u,**v,*w,wchisq,pchisq;
	double	**cvm;
	int		i,j;
	double	mean,totalError;
	
	int		nvertices=163842;
	int		testmode=kTESTEFFECT;
	Model	mpartial=*m;
	
	mpartial.n--;
	
	int sup=100;
    
	ma=neffects;
	u=(double**)calloc(nsubjects+1+sup,sizeof(double*));
	for(i=1;i<=nsubjects;i++)
		u[i]=(double*)calloc(ma+1+sup,sizeof(double));
	v=(double**)calloc(ma+1+sup,sizeof(double*));
	for(i=1;i<=ma;i++)
		v[i]=(double*)calloc(ma+1+sup,sizeof(double));
	cvm=(double**)calloc(ma+1+sup,sizeof(double*));
	for(i=1;i<=ma;i++)
		cvm[i]=(double*)calloc(ma+1+sup,sizeof(double));
	w=(double*)calloc(ma+1+sup,sizeof(double));
	a=(double*)calloc(ma+1+sup,sizeof(double));
	
	alldep=(float*)calloc(nsubjects*nvertices+sup,sizeof(float));
	dep=(double*)calloc(nsubjects+1+sup,sizeof(double));
	indep=(double**)calloc(nvariables-1+sup,sizeof(double*));
	for(i=0;i<nvariables-1;i++)
		indep[i]=(double*)calloc(nsubjects+1+sup,sizeof(double));
	sig=(double*)calloc(nsubjects+1+sup,sizeof(double));
	
	// 1. Load independent variables
	printf("[1] Loading independent variables\n");
	f=fopen(path_in_indep,"r");
	fgets(str,1024,f);
	for(i=1;i<=nsubjects;i++)
	{
		
		fscanf(f," %*s ");
		for(j=1;j<nvariables;j++)
        {
			fscanf(f," %s ",str);
            NSString    *var=[variables objectAtIndex:j];
            if([[variablesRange objectForKey:var] count]==2)
            {
                NSArray *arr=[variablesRange objectForKey:var];
                int ind=[arr indexOfObject:[NSString stringWithUTF8String:str]];
                indep[j-1][i]=ind;
            }
            else
                sscanf(str," %le ",&(indep[j-1][i]));
        }
		sig[i]=1;
        
        /*
        printf("%3i. ",i);
        for(j=1;j<nvariables;j++)
            printf("\t%g",indep[j-1][i]);
        printf("\n");
         */

	}
	fclose(f);
	
	// 2. Load dependent variables for hemisphere h
	printf("[2] Loading dependent variables\n");
	f=fopen(path_in_dep,"r");
	fread(alldep,nsubjects*nvertices,sizeof(float),f);
	fclose(f);
    
    /* TEST */
    changeEndianness=1;
    /*------*/
    if(changeEndianness)
    {
        printf("changing endianness\n");
        for(i=0;i<nsubjects*nvertices;i++)
        {
            tmp[3]=((char*)&(alldep[i]))[0]; 
            tmp[2]=((char*)&(alldep[i]))[1]; 
            tmp[1]=((char*)&(alldep[i]))[2]; 
            tmp[0]=((char*)&(alldep[i]))[3]; 
            alldep[i]=*(float*)tmp;
        }
    }
    
    /**/
    float test1=0;
    for(i=0;i<10;i++)
        printf("TEST2: %f\n",alldep[i]);
    for(i=0;i<nsubjects*nvertices;i++)
        test1+=alldep[i];
    printf("TEST1: %f\n",test1);
     /**/
	
	// 3. Fit whole model for hemisphere h, then test the last effect
	printf("[3] Fitting model\n");
    for(i=0;i<nvertices;i++)
	{
		if(i%(nvertices/200)==0)
		{
			[progressMsg setStringValue:[NSString stringWithFormat:@"%i%%",100*i/nvertices]];
			[progressMsg displayIfNeeded];
		}
		
		// prepare dependent variables vector for vertex i
		for(j=1;j<=nsubjects;j++)
			dep[j]=alldep[(j-1)*nvertices+i];
		
		// fit whole model
		ma=neffects;
		svdfit(dep,sig,nsubjects, a,ma,fmodel,m, u,v,w,&wchisq);
		
		// estimate size (R^2) and significativity (F-ratio) of the fitting...
		mean=0; for(j=1;j<=nsubjects;j++) mean+=dep[j]; mean/=(double)nsubjects;
		totalError=0; for(j=1;j<=nsubjects;j++) totalError+=pow(dep[j]-mean,2);
        average[i]=mean;
        eslope[i]=a[ma];
		
		if(testmode==kTESTWHOLE)
		{
			// ...for the complete model
			ma=neffects;
			rsqr[i]=1-wchisq/totalError;
			fratio[i]=((totalError-wchisq)/wchisq)*((nsubjects-ma)/(double)(ma-1));
		}
		
		if(testmode==kTESTEFFECT)
		{
			// ...only for the last effect
			
			// fit partial model
			ma=neffects-1;
			svdfit(dep,sig,nsubjects, a,ma,fmodel,m, u,v,w,&pchisq);
			//svdvar(v,ma,w,cvm);	
			
			rsqr[i]=(pchisq-wchisq)/totalError;
            if(rsqr[i]<0)
            {
                printf("NEGATIVE R^2 at vertex %i\n",i);
                int ii,jj;
                for(ii=1;ii<=nsubjects;ii++)
                {
                    printf("%g",dep[ii]);
                    for(jj=1;jj<=m->n;jj++)
                        printf("\t%g",indep[m->e[jj].e1][ii]);
                    printf("\n");
                }
            }
			fratio[i]=((pchisq-wchisq)/wchisq)*((nsubjects-ma)/1.0);
		}
	}
	
	// 4. Clean
	printf("[4] Cleaning\n");
	free(alldep);
	free(dep);
	for(i=0;i<nvariables-1;i++)
		free(indep[i]);
	free(indep);
	free(sig);
	for(i=1;i<=nsubjects;i++) free(u[i]); free(u);
	ma=neffects;
	for(i=1;i<=ma;i++) free(v[i]); free(v);
	for(i=1;i<=ma;i++) free(cvm[i]); free(cvm);
	free(w);
	free(a);
    
    /*
    for(i=0;i<10;i++)
        printf("TEST2: %g\t%g\t%g\n",fratio[i],rsqr[i],average[i]);
    test1=0;
    for(i=0;i<nvertices;i++)
        test1+=fratio[i];
    printf("TEST1: %f\n",test1);
    */
	
	printf("Finished.\n");
}
-(IBAction)fitModel:(id)sender
{
	Model   model;
	int		i,j;
	
	int	sup=5;
    
	model.n=[modelVariables count]+1;
	model.e=(Effect*)calloc(model.n+sup,sizeof(Effect));
	
	// add intercept
	model.e[1]=(Effect){kI,0,0,0,0};
	j=2;
	for(i=0;i<[modelVariables count];i++)
	{
		if(i!=[modelVariables indexOfObject:[[settings content] objectForKey:@"modelEffect"]])
			[self encodeVariable:[modelVariables objectAtIndex:i] inEffect:&(model.e[j++])];
	}
	i=[modelVariables indexOfObject:[[settings content] objectForKey:@"modelEffect"]];
	[self encodeVariable:[modelVariables objectAtIndex:i] inEffect:&(model.e[j++])];
		
	[progressMsg setStringValue:@"Fitting Left Hemisphere..."];
	[progressMsg displayIfNeeded];
	[self fitModelNSubjects:[dataSubjects count] nVariables:[variables count] nEffects:[modelVariables count]+1
				  pathIndep:(char*)[[[settings content] objectForKey:@"pathSubjectsData"] UTF8String]
					pathDep:(char*)[[[settings content] objectForKey:@"pathLeftData"] UTF8String]
				 hemisphere:0 model:&model
					   RSqr:[view lrsqr] FRatio:[view lfratio] eslope:[view leslope] average:[view laverage]];
	[progressMsg setStringValue:@"Fitting Right Hemisphere..."];
	[progressMsg displayIfNeeded];
	[self fitModelNSubjects:[dataSubjects count] nVariables:[variables count] nEffects:[modelVariables count]+1
				  pathIndep:(char*)[[[settings content] objectForKey:@"pathSubjectsData"] UTF8String]
					pathDep:(char*)[[[settings content] objectForKey:@"pathRightData"] UTF8String]
				 hemisphere:1 model:&model
					   RSqr:[view rrsqr] FRatio:[view rfratio] eslope:[view reslope] average:[view raverage]];
    [view changeFRS:0];
	[progressMsg setStringValue:@" "];
}
-(IBAction)showLeft:(id)sender
{
	[view setShowLeft:[sender intValue]];
}
-(IBAction)showRight:(id)sender
{
	[view setShowRight:[sender intValue]];
}
-(IBAction)setFDR:(id)sender
{
	float	q=[sender floatValue];
	float   fthr=fdr2f([view lfratio], [view nvertices], [modelVariables count], [dataSubjects count], q);

    printf("FDR:%f, F-Threshold:%f\n",[sender floatValue],fthr);
 
	//[[settings content] setValue:[NSNumber numberWithFloat:thr] forKey:@"thresh"];
	[view setNeedsDisplay:YES];
}
#pragma mark -
-(IBAction)rotate:(id)sender
{
}
-(IBAction)viewChangeFRS:(id)sender
{
	int	frs=[[[settings content] valueForKey:@"displayFRS"] intValue];
	printf("displayFRS=%i\n",frs);
	[view changeFRS:frs];
}
-(IBAction)saveImage:(id)sender
{
}
-(IBAction)saveData:(id)sender
{
    NSSavePanel *savePanel=[NSSavePanel savePanel];
    int		result;
	FILE	*f;
    
    result=[savePanel runModal];
    if (result==NSOKButton)
    {
		char	str[512],*name=(char*)[[[savePanel URL] path] UTF8String];

		// Left hemisphere
        // save R^2
		sprintf(str,"%s.lh.rsquare.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view lrsqr],[view nvertices],sizeof(float),f);
		fclose(f);
		// save F-ratio
		sprintf(str,"%s.lh.fratio.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view lfratio],[view nvertices],sizeof(float),f);
		fclose(f);
		// save Effect slope
		sprintf(str,"%s.lh.eslope.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view leslope],[view nvertices],sizeof(float),f);
		fclose(f);
		// save Average
		sprintf(str,"%s.lh.average.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view laverage],[view nvertices],sizeof(float),f);
		fclose(f);

        // Right hemisphere
        // save R^2
		sprintf(str,"%s.rh.rsquare.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view rrsqr],[view nvertices],sizeof(float),f);
		fclose(f);
		// save F-ratio
		sprintf(str,"%s.rh.fratio.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view rfratio],[view nvertices],sizeof(float),f);
		fclose(f);
		// save Effect slope
		sprintf(str,"%s.rh.eslope.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view reslope],[view nvertices],sizeof(float),f);
		fclose(f);
		// save Average
		sprintf(str,"%s.rh.average.float",name);
		f=fopen(str,"w");
		fprintf(f,"%i 1 3\n",[view nvertices]);
		fwrite([view raverage],[view nvertices],sizeof(float),f);
		fclose(f);
}

}
#pragma mark -
-(id)tableView:(NSTableView *)t objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    id rec, val=nil;
    int	nrows;
	
	if(t==tableSubjects && dataSubjects!=nil)
	{
		nrows=[dataSubjects count];
	
		if(rowIndex>=0 && rowIndex < nrows)
		{
			rec = [dataSubjects objectAtIndex:rowIndex];
			val = [rec objectForKey:[aTableColumn identifier]];
			return val;
		}
	}	
	if(t==tableIndep && variables!=nil)
	{
		nrows=[variables count];
		if(rowIndex>=0 && rowIndex < nrows)
        {
            return [variables objectAtIndex:rowIndex];
        }
	}	
	if(t==tableModel && modelVariables!=nil)
	{
		nrows=[modelVariables count];
		if(rowIndex>=0 && rowIndex < nrows)
			return [modelVariables objectAtIndex:rowIndex];
	}	
	return val;
}
-(int)numberOfRowsInTableView:(NSTableView *)t
{
	int		n=0;
	
	if(t==tableSubjects && dataSubjects!=nil)
		n=[dataSubjects count];
	if(t==tableIndep && variables!=nil)
		n=[variables count];
	if(t==tableModel && modelVariables!=nil)
		n=[modelVariables count];
	return n;
}
- (void)tableViewSelectionDidChange:(NSNotification *)n
{
	NSTableView	*table=[n object];
	
	if(table==tableModel)
		[self updateModel];

}
@end
