/* MyBrainView */

#import <Cocoa/Cocoa.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#import "Trackball.h"

#define SIZESTACK	64

#define kLeft	1
#define kRight	2

// Structures
typedef struct
{
	float	x,y,z;
}float3D;
typedef struct
{
	int	a,b,c;
}int3D;
typedef struct {
	int		n;
	int		t[SIZESTACK];
}NTriRec, *NtriPtr;

@interface MyBrainView : NSOpenGLView
{
	NSObjectController	*settings;
	float3D		*lp,*rp;
	int3D		*lt,*rt;
	float		*lsdepth,*rsdepth;
	int			np;
	int			nt;
	float3D		*lvcolour,*rvcolour;
	
	Trackball	*m_trackball;
	float		m_rotation[4];	// The main rotation
	float		m_tbRot[4];		// The trackball rotation
	float		rot[3];
	
	float		zoom;
	
	int			FRS;
	int			showLeft;
	int			showRight;
	
	int			nvertices;

	float	*lrsqr;			// left hemisphere: R^2
	float	*lfratio;		// left hemisphere: Fratio
	float	*leslope;		// left hemisphere: Effect slope
    float   *laverage;      // left hemisphere: Average
	float	*rrsqr;
	float	*rfratio;
	float	*reslope;
    float   *raverage;
}
-(void)setSettings:(NSObjectController*)theSettings;
-(void)loadMesh:(char*)name p:(float3D**)p t:(int3D**)t;
-(void)configureDefaultVerticesColour;
-(void)setVerticesColour:(float*)data hemisphere:(int)h;

- (void)rotateBy:(float *)r;		// trackball method

-(void)changeFRS:(int)frs;

-(void)setStandardRotation:(int)indx;
-(void)setZoom:(float)z;

-(void)setShowLeft:(int)flag;
-(void)setShowRight:(int)flag;

-(int)nvertices;
-(float*)lrsqr;
-(float*)lfratio;
-(float*)leslope;
-(float*)laverage;
-(float*)rrsqr;
-(float*)rfratio;
-(float*)reslope;
-(float*)raverage;
@end
