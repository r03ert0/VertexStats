#import "MyBrainView.h"
#include "colourmap.h"
@implementation MyBrainView

float3D sca3D(float3D a, float t)
{
	return (float3D){a.x*t,a.y*t,a.z*t};
}
float norm3D(float3D a)
{
	return sqrt(a.x*a.x+a.y*a.y+a.z*a.z);
}
float3D add3D(float3D a, float3D b)
{
	return (float3D){a.x+b.x,a.y+b.y,a.z+b.z};
}
float3D sub3D(float3D a, float3D b)
{
	return (float3D){a.x-b.x,a.y-b.y,a.z-b.z};
}
float3D cross3D(float3D a, float3D b)
{
    float3D	xx;
    
    xx.x = a.y*b.z - a.z*b.y;
    xx.y = a.z*b.x - a.x*b.z;
    xx.z = a.x*b.y - a.y*b.x;
    return(xx);
}
double dot3D(float3D a, float3D b)
{
    return a.x*b.x + a.y*b.y + a.z*b.z;
}
float3D triPlane(float3D a, float3D b, float3D c)
{
    float3D	p,zero={0,0,0};
    
    p= cross3D( sub3D(b,a), sub3D(c,a) );
    if(norm3D(p))
            return(sca3D(p,1.0/norm3D(p)));
    return(zero);		
}
#pragma mark -
-(void)setSettings:(NSObjectController*)theSettings
{
	settings=theSettings;
}
-(void)setSulcalDepth
{
	int			i;
    float		n,max;
	float3D		ce={0,0,0},ide,siz;
	
	// compute sulcal depth: left hemisphere
	for(i=0;i<np;i++)
	{
		ce=(float3D){ce.x+lp[i].x,ce.y+lp[i].y,ce.z+lp[i].z};
		if(i==0) ide=siz=lp[i];
		if(ide.x<lp[i].x) ide.x=lp[i].x;
		if(ide.y<lp[i].y) ide.y=lp[i].y;
		if(ide.z<lp[i].z) ide.z=lp[i].z;
		if(siz.x>lp[i].x) siz.x=lp[i].x;
		if(siz.y>lp[i].y) siz.y=lp[i].y;
		if(siz.z>lp[i].z) siz.z=lp[i].z;
	}
	ce=(float3D){ce.x/(float)np,ce.y/(float)np,ce.z/(float)np};
	if(lsdepth!=nil)
		free(lsdepth);
	lsdepth=(float*)calloc(np,sizeof(float));
	max=0;
    for(i=0;i<np;i++)
    {
        n=	pow(2*(lp[i].x-ce.x)/(ide.x-siz.x),2) +
			pow(2*(lp[i].y-ce.y)/(ide.y-siz.y),2) +
			pow(2*(lp[i].z-ce.z)/(ide.z-siz.z),2);
        lsdepth[i] = sqrt(n);
        if(lsdepth[i]>max)	max=lsdepth[i];
    }
    max*=0.9;	// pure white is not nice...
    for(i=0;i<np;i++)
        lsdepth[i]=pow(lsdepth[i]/max,3);

	// compute sulcal depth: right hemisphere
	for(i=0;i<np;i++)
	{
		ce=(float3D){ce.x+rp[i].x,ce.y+rp[i].y,ce.z+rp[i].z};
		if(i==0) ide=siz=lp[i];
		if(ide.x<rp[i].x) ide.x=rp[i].x;
		if(ide.y<rp[i].y) ide.y=rp[i].y;
		if(ide.z<rp[i].z) ide.z=rp[i].z;
		if(siz.x>rp[i].x) siz.x=rp[i].x;
		if(siz.y>rp[i].y) siz.y=rp[i].y;
		if(siz.z>rp[i].z) siz.z=rp[i].z;
	}
	ce=(float3D){ce.x/(float)np,ce.y/(float)np,ce.z/(float)np};
	if(rsdepth!=nil)
		free(rsdepth);
	rsdepth=(float*)calloc(np,sizeof(float));
	max=0;
    for(i=0;i<np;i++)
    {
        n=	pow(2*(rp[i].x-ce.x)/(ide.x-siz.x),2) +
		pow(2*(rp[i].y-ce.y)/(ide.y-siz.y),2) +
		pow(2*(rp[i].z-ce.z)/(ide.z-siz.z),2);
        rsdepth[i] = sqrt(n);
        if(rsdepth[i]>max)	max=rsdepth[i];
    }
    max*=0.9;	// pure white is not nice...
    for(i=0;i<np;i++)
        rsdepth[i]=pow(rsdepth[i]/max,3);
}
-(void)configureDefaultVerticesColour
{
	if(lvcolour)
	{
		free(lvcolour);
		lvcolour=nil;
	}
	lvcolour=(float3D*)calloc(np,sizeof(float3D));
	int	i;
	for(i=0;i<np;i++)
		lvcolour[i]=(float3D){lsdepth[i]*145/255.0*1.5,lsdepth[i]*135/255.0*1.5,lsdepth[i]*125/255.0*1.5};

	if(rvcolour)
	{
		free(rvcolour);
		rvcolour=nil;
	}
	rvcolour=(float3D*)calloc(np,sizeof(float3D));
	for(i=0;i<np;i++)
		rvcolour[i]=(float3D){rsdepth[i]*145/255.0*1.5,rsdepth[i]*135/255.0*1.5,rsdepth[i]*125/255.0*1.5};
}
-(void)setVerticesColour:(float*)data hemisphere:(int)h
{
    int i;
    unsigned char	px[4];
	switch(h)
	{
		case kLeft:
		{
			if(lvcolour==nil)
				lvcolour=(float3D*)calloc(np,sizeof(float3D));
			for(i=0;i<np;i=i+1)
			{
				colourmap(data[i], px, JET);
				lvcolour[i]=(float3D){lsdepth[i]*px[0]/255.0,lsdepth[i]*px[1]/255.0,lsdepth[i]*px[2]/255.0};
			}
			break;
		}
		case kRight:
		{
			if(rvcolour==nil)
				rvcolour=(float3D*)calloc(np,sizeof(float3D));
			for(i=0;i<np;i=i+1)
			{
				colourmap(data[i], px, JET);
				rvcolour[i]=(float3D){rsdepth[i]*px[0]/255.0,rsdepth[i]*px[1]/255.0,rsdepth[i]*px[2]/255.0};
			}
			break;
		}
	}
}
#pragma mark -
- (id) initWithFrame: (NSRect) frame
{
    GLuint attribs[] = 
    {
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAWindow,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAStencilSize, 8,
            NSOpenGLPFAAccumSize, 0,
            0
    };

    NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs];
    
    self = [super initWithFrame:frame pixelFormat:[fmt autorelease]];
    if (!fmt)	NSLog(@"No OpenGL pixel format");
    [[self openGLContext] makeCurrentContext];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_SMOOTH);
	
    // initialize the trackball
    m_trackball = [[Trackball alloc] init];
    m_rotation[0] = m_tbRot[0] = 0.0;
    m_rotation[1] = m_tbRot[1] = 1.0;
    m_rotation[2] = m_tbRot[2] = 0.0;
    m_rotation[3] = m_tbRot[3] = 0.0;
	[self setStandardRotation:7];
	
	zoom=75;
	FRS=0;
	nvertices=163842;
	lp=nil;
	lt=nil;
	rp=nil;
	rt=nil;

	lsdepth=nil;
	lvcolour=nil;
	rsdepth=nil;
	rvcolour=nil;
	
    lrsqr=(float*)calloc(nvertices,sizeof(float));
	lfratio=(float*)calloc(nvertices,sizeof(float));
	leslope=(float*)calloc(nvertices,sizeof(float));
	laverage=(float*)calloc(nvertices,sizeof(float));
	rrsqr=(float*)calloc(nvertices,sizeof(float));
	rfratio=(float*)calloc(nvertices,sizeof(float));
	reslope=(float*)calloc(nvertices,sizeof(float));
	raverage=(float*)calloc(nvertices,sizeof(float));
	
    showLeft=YES;
	showRight=YES;
	
	[self loadMesh:"lh.orig" p:&lp t:&lt];
	[self loadMesh:"rh.orig" p:&rp t:&rt];
	
	// translate the brain to the origin
	int	i;
	float3D	o={0,0,0};
	for(i=0;i<nvertices;i++) o=add3D(o,add3D(lp[i],rp[i]));
	o=sca3D(o,1/(float)(2*nvertices));
	for(i=0;i<nvertices;i++)
	{
		lp[i]=sub3D(lp[i],o);
		rp[i]=sub3D(rp[i],o);
	}
		
	[self setSulcalDepth];
	[self configureDefaultVerticesColour];
	
    return self;
}
-(void)loadMesh:(char*)name p:(float3D**)p t:(int3D**)t
//int msh_importFSMeshData(MeshRec *mesh, char *path)
{
    char	path[512];
	FILE	*f;
	int		i,j;
    int		iden,a,b,c,d;
    char	date[256],info[256];
	char	byte12[12];

	sprintf(path,"%s/Contents/Resources/%s",[[[NSBundle mainBundle] bundlePath] UTF8String],name);
    f=fopen(path,"r");

	// read triangle/quad identifier: 3 bytes
    a=((int)(u_int8_t)fgetc(f))<<16;
    b=((int)(u_int8_t)fgetc(f))<<8;
    c=(u_int8_t)fgetc(f);
    iden=a+b+c;
    
    if(iden==16777214)	// triangle mesh
    {
		printf("FS id (16777214 triangle) %i\n",iden);
        // get creation date text line
        j=0;
		do
		{
			date[j]=fgetc(f);
		}
        while(date[j++]!=(char)10);
        date[j-1]=(char)0;
		printf("FS date %s\n",date);
        // get info text line
        j=0;
		do
		{
			info[j]=fgetc(f);
		}
        while(info[j++]!=(char)10);
		info[j-1]=(char)0;
		printf("FS info %s\n",info);
        
        // get number of vertices
        a=((int)(u_int8_t)fgetc(f))<<24;
        b=((int)(u_int8_t)fgetc(f))<<16;
        c=((int)(u_int8_t)fgetc(f))<<8;
        d=(u_int8_t)fgetc(f);
        np=a+b+c+d;
		printf("FS #points %i\n",np);
		if(*p) free(*p);
		*p=(float3D*)calloc(np,sizeof(float3D));
        	
        // get number of triangles
        a=((int)(u_int8_t)fgetc(f))<<24;
        b=((int)(u_int8_t)fgetc(f))<<16;
        c=((int)(u_int8_t)fgetc(f))<<8;
        d=(u_int8_t)fgetc(f);
        nt=a+b+c+d;
		printf("FS #triangles %i\n",nt);
		if(*t) free(*t);
		*t=(int3D*)calloc(nt,sizeof(int3D));
	
        // read vertices
        for(j=0;j<np;j++)
		{
            for(i=0;i<12;i++) byte12[i/4*4+3-i%4]=fgetc(f);
            (*p)[j] = *(float3D*)byte12;
		}
        
        // read triangles
        for(j=0;j<nt;j++)
		{
            for(i=0;i<12;i++) byte12[i/4*4+3-i%4]=fgetc(f);
            (*t)[j] = *(int3D*)byte12;
			(*t)[j]=(int3D){(*t)[j].a,(*t)[j].c,(*t)[j].b}; // flip triangle
		}
    }
	printf("FSSurf finished\n");
}
- (void) drawRect: (NSRect) rect
{
	float	aspectRatio=(float)rect.size.width/(float)rect.size.height;
    
    [self update];

    // init projection
        glViewport(0, 0, (GLsizei) rect.size.width, (GLsizei) rect.size.height);
        glClearColor(1,1,1, 1);
    //glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT+GL_STENCIL_BUFFER_BIT);
    glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(-aspectRatio*zoom, aspectRatio*zoom, -zoom, zoom, -1000.0, 1000.0);

    // prepare drawing
        glMatrixMode (GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt (0,0,-10, 0,0,0, 0,1,0); // eye,center,updir
        glRotatef(m_tbRot[0],m_tbRot[1], m_tbRot[2], m_tbRot[3]);
        glRotatef(m_rotation[0],m_rotation[1],m_rotation[2],m_rotation[3]);

    // draw
        glEnableClientState(GL_VERTEX_ARRAY);

		if(showLeft)
		{
			glVertexPointer(3,GL_FLOAT,0,(GLfloat*)lp);
			glEnableClientState(GL_COLOR_ARRAY);
			glColorPointer(3,GL_FLOAT,0,(GLfloat*)lvcolour);
			glDrawElements(GL_TRIANGLES,nt*3,GL_UNSIGNED_INT,(GLuint*)lt);
		}
		if(showRight)
		{
			glVertexPointer(3,GL_FLOAT,0,(GLfloat*)rp);
			glEnableClientState(GL_COLOR_ARRAY);
			glColorPointer(3,GL_FLOAT,0,(GLfloat*)rvcolour);
			glDrawElements(GL_TRIANGLES,nt*3,GL_UNSIGNED_INT,(GLuint*)rt);
		}
	glEnd();

    [[self openGLContext] flushBuffer];
}
- (void)dealloc
{
	free(lrsqr);
	free(lfratio);
	free(leslope);
	free(laverage);
	free(rrsqr);
	free(rfratio);
	free(reslope);
	free(raverage);
	free(lp);
	free(rp);
	free(lt);
	free(rt);
	free(lsdepth);
	free(rsdepth);
	free(lvcolour);
	free(rvcolour);
	
	[super dealloc];
}
#pragma mark -
- (void)rotateBy:(float *)r
{
    m_tbRot[0] = r[0];
    m_tbRot[1] = r[1];
    m_tbRot[2] = r[2];
    m_tbRot[3] = r[3];
}
- (void)mouseDown:(NSEvent *)theEvent
{
    [m_trackball start:[theEvent locationInWindow] sender:self];
}
- (void)mouseUp:(NSEvent *)theEvent
{
    // Accumulate the trackball rotation
    // into the current rotation.
    [m_trackball add:m_tbRot toRotation:m_rotation];

    m_tbRot[0]=0;
    m_tbRot[1]=1;
    m_tbRot[2]=0;
    m_tbRot[3]=0;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [self lockFocus];
    [m_trackball rollTo:[theEvent locationInWindow] sender:self];
    [self unlockFocus];
    [self setNeedsDisplay:YES];
}
-(void)setStandardRotation:(int)indx
{
    m_rotation[0] = m_tbRot[0] = 0.0;
    m_rotation[1] = m_tbRot[1] = 0.0;
    m_rotation[2] = m_tbRot[2] = 1.0;
    m_rotation[3] = m_tbRot[3] = 0.0;
    
    switch(indx)
    {
        case 1:m_rotation[0]=270;	m_rotation[1]=1;m_rotation[2]=0; break; //sup
        case 4:m_rotation[0]= 90;	break; //frn
        case 5:m_rotation[0]=  0;	break; //tmp
        case 6:m_rotation[0]=270;	break; //occ
        case 7:m_rotation[0]=180;	break; //med
        case 9:m_rotation[0]= 90;	m_rotation[1]=1;m_rotation[2]=0; break; //cau
    }
    [self setNeedsDisplay:YES];
}
-(void)setZoom:(float)z
{
	zoom=pow(2,-z);
	[self setNeedsDisplay:YES];
}
-(void)changeFRS:(int)frs
{
	float	*lptr,*rptr;
	float	*ldata=(float*)calloc(nvertices,sizeof(float));
	float	*rdata=(float*)calloc(nvertices,sizeof(float));
	float	min,max;
	int		i;
	
	FRS=frs;
    
    printf("FRS:%i\n",frs);
	
	if(frs==0)	// F-ratio
	{
		lptr=lfratio;
		rptr=rfratio;
	}
	else
	if(frs==1)	// R-squared
	{
		lptr=lrsqr;
		rptr=rrsqr;
	}
	else
    if(frs==2)  // Effect-slope
	{
		lptr=leslope;
		rptr=reslope;
	}
    else
    if(frs==3)  // Average
    {
        lptr=laverage;
        rptr=raverage;
    }
	
	min=max=ldata[0];
	for(i=0;i<nvertices;i++)
	{
		if(lptr[i]>max) max=lptr[i];
		if(lptr[i]<min) min=lptr[i];
		if(rptr[i]>max) max=rptr[i];
		if(rptr[i]<min) min=rptr[i];
	}
	printf("min:%g, max:%g\n",min,max);
	[[settings content] setValue:[NSString stringWithFormat:@"%g,%g",min,max] forKey:@"minmax"];
	
	if(max>min)
	for(i=0;i<nvertices;i++)
	{
		ldata[i]=(lptr[i]-min)/(max-min);
		rdata[i]=(rptr[i]-min)/(max-min);
	}
	[self setVerticesColour:ldata hemisphere:kLeft];
	[self setVerticesColour:rdata hemisphere:kRight];
	free(ldata);
	free(rdata);
	
	[self setNeedsDisplay:YES];
}
-(int)nvertices
{
	return nvertices;
}
-(float*)lrsqr
{
	return lrsqr;
}
-(float*)lfratio
{
	return lfratio;
}
-(float*)leslope
{
	return leslope;
}
-(float*)laverage
{
	return laverage;
}
-(float*)rrsqr
{
	return rrsqr;
}
-(float*)rfratio
{
	return rfratio;
}
-(float*)reslope
{
	return reslope;
}
-(float*)raverage
{
	return raverage;
}
-(void)setShowLeft:(int)flag
{
	showLeft=flag;
	[self setNeedsDisplay:YES];
}
-(void)setShowRight:(int)flag
{
	showRight=flag;
	[self setNeedsDisplay:YES];
}

@end
