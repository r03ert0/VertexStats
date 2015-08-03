#include "fitmodel.h"

void new_dmatrix(double ***x, int m, int n)
{
	// matrix is 1-based
	int	i;
	(*x)=(double**)calloc(m+1,sizeof(double*));
	for(i=1;i<=m;i++)
		(*x)[i]=(double*)calloc(n+1,sizeof(double));
}
void free_dmatrix(double **x, int m)
{
	// matrix is 1-based
	int	i;
	for(i=1;i<=m;i++)
		free(x[i]);
	free(x);
}

#pragma mark -
#pragma mark [   Singular Value Decomposition   ]

#define TOL 1.0e-12

static double maxarg1,maxarg2; 
#define FMAX(a,b) (maxarg1=(a),maxarg2=(b),(maxarg1)>(maxarg2)?(maxarg1):(maxarg2)) 

static double sqrarg; 
#define SQR(a) ((sqrarg=(a))==0.0?0.0:sqrarg*sqrarg)

static int iminarg1,iminarg2; 
#define IMIN(a,b) (iminarg1=(a),iminarg2=(b),(iminarg1)<(iminarg2)?(iminarg1):(iminarg2))

#define SIGN(a,b) ((b)>=0.0? fabs(a):-fabs(a))

/*
Computes (a2+b2)1/2 without destructive underflow or overflow. 
*/
double pythag(double a,double b) 
{ 
	double	absa,absb; 
	absa=fabs(a); 
	absb=fabs(b); 
	if(absa>absb)
		return absa*sqrt(1.0+SQR(absb/absa)); 
	else
		return(absb==0.0? 0.0: absb*sqrt(1.0+SQR(absa/absb))); 
} 

/*
Given a matrix a[1..m][1..n], this routine computes its singular value decomposition, A=U*W*V^T 
The matrix U replaces a on output. The diagonal matrix of singular values W is out- 
put as a vector w[1..n].
The matrix V (not the transpose V^T) is output as v[1..n][1..n].
*/
void svdcmp(double **a,int m,int n,double w[],double **v)
{
	int		flag,i,its,j,jj,k,l,nm; 
	double	anorm,c,f,g,h,s,scale,x,y,z,*rv1; 

	rv1=(double*)calloc(n+1,sizeof(double)); 
	g=scale=anorm=0.0; // House holder reduction to bidiagonal form. 
	for(i=1;i<=n;i++)
	{ 
		l=i+1; 
		rv1[i]=scale*g; 
		g=s=scale=0.0; 
		if(i<=m)
		{ 
			for(k=i;k<=m;k++)scale+=fabs(a[k][i]); 
			if(scale)
			{ 
				for(k=i;k<=m;k++)
				{ 
					a[k][i]/=scale; 
					s+=a[k][i]*a[k][i]; 
				} 
				f=a[i][i]; 
				g=-SIGN(sqrt(s),f); 
				h=f*g-s; 
				a[i][i]=f-g; 
				for(j=l;j<=n;j++)
				{ 
					for(s=0.0,k=i;k<=m;k++) s+=a[k][i]*a[k][j]; 
					f=s/h; 
					for(k=i;k<=m;k++) a[k][j]+=f*a[k][i]; 
				} 
				for(k=i;k<=m;k++) a[k][i]*=scale; 
			} 
		} 
		w[i]=scale*g; 
		g=s=scale=0.0; 
		if(i<=m&&i!=n)
		{ 
			for(k=l;k<=n;k++) scale+=fabs(a[i][k]); 
			if(scale)
			{
				for(k=l;k<=n;k++)
				{ 
					a[i][k]/=scale; 
					s+=a[i][k]*a[i][k]; 
				} 
				f=a[i][l]; 
				g=-SIGN(sqrt(s),f); 
				h=f*g-s; 
				a[i][l]=f-g; 
				for(k=l;k<=n;k++) rv1[k]=a[i][k]/h; 
				for(j=l;j<=m;j++)
				{ 
					for(s=0.0,k=l;k<=n;k++) s+=a[j][k]*a[i][k]; 
					for(k=l;k<=n;k++) a[j][k]+=s*rv1[k]; 
				} 
				for(k=l;k<=n;k++) a[i][k]*=scale; 
			} 
		} 
		anorm=FMAX(anorm,(fabs(w[i])+fabs(rv1[i]))); 
	} 
	for(i=n;i>=1;i--)
	{ //Accumulation of right-hand transformations. 
		if(i<n)
		{ 
			if(g)
			{ 
				for(j=l;j<=n;j++) // Double division to avoid possible underflow. 
					v[j][i]=(a[i][j]/a[i][l])/g; 
				for(j=l;j<=n;j++)
				{ 
					for(s=0.0,k=l;k<=n;k++) s+=a[i][k]*v[k][j]; 
					for(k=l;k<=n;k++) v[k][j]+=s*v[k][i]; 
				} 
			} 
			for(j=l;j<=n;j++) v[i][j]=v[j][i]=0.0; 
		} 
		v[i][i]=1.0; 
		g=rv1[i]; 
		l=i; 
	} 
	for(i=IMIN(m,n);i>=1;i--)
	{ //Accumulation of left-hand transformations. 
		l=i+1; 
		g=w[i]; 
		for(j=l;j<=n;j++) a[i][j]=0.0; 
		if(g)
		{ 
			g=1.0/g; 
			for(j=l;j<=n;j++)
			{ 
				for(s=0.0,k=l;k<=m;k++) s+=a[k][i]*a[k][j]; 
				f=(s/a[i][i])*g; 
				for(k=i;k<=m;k++) a[k][j]+=f*a[k][i]; 
			} 
			for(j=i;j<=m;j++) a[j][i]*=g; 
		}
		else
			for(j=i;j<=m;j++) a[j][i]=0.0; 
		++a[i][i]; 
	} 
	for(k=n;k>=1;k--)
	{	// Diagonalization of the bidiagonal form: Loop over 
		// singular values, and over allowed iterations.
		for(its=1;its<=30;its++)
		{ 
			flag=1; 
			for(l=k;l>=1;l--)
			{ // Test for splitting. 
				nm=l-1; // Note that rv1[1] is always zero. 
				if((double)(fabs(rv1[l])+anorm)==anorm)
				{ 
					flag=0; 
					break; 
				} 
				if((double)(fabs(w[nm])+anorm)==anorm)
					break; 
			} 
			if(flag)
			{ 
				c=0.0; // Cancellation	of rv1[l], if l>1. 
				s=1.0; 
				for(i=l;i<=k;i++)
				{
					f=s*rv1[i]; 
					rv1[i]=c*rv1[i]; 
					if((double)(fabs(f)+anorm)==anorm)
						break; 
					g=w[i]; 
					h=pythag(f,g); 
					w[i]=h; 
					h=1.0/h; 
					c=g*h; 
					s= -f*h; 
					for(j=1;j<=m;j++)
					{ 
						y=a[j][nm]; 
						z=a[j][i]; 
						a[j][nm]=y*c+z*s; 
						a[j][i]=z*c-y*s; 
					} 
				} 
			} 
			z=w[k]; 
			if(l==k)
			{ // Convergence. 
				if(z<0.0)
				{ // Singular valueismadenonnegative. 
					w[k]= -z; 
					for(j=1;j<=n;j++) v[j][k]= -v[j][k]; 
				} 
				break; 
			} 
			if(its==30)
				printf("no convergence in 30 svdcmp iterations\n"); 
			x=w[l]; // Shift frombottom2-by-2minor. 
			nm=k-1; 
			y=w[nm]; 
			g=rv1[nm]; 
			h=rv1[k]; 
			f=((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y); 
			g=pythag(f,1.0); 
			f=((x-z)*(x+z)+h*((y/(f+SIGN(g,f)))-h))/x; 
			c=s=1.0; // Next QR transformation: 
			for(j=l;j<=nm;j++)
			{ 
				i=j+1; 
				g=rv1[i]; 
				y=w[i]; 
				h=s*g; 
				g=c*g; 
				z=pythag(f,h); 
				rv1[j]=z; 
				c=f/z; 
				s=h/z; 
				f=x*c+g*s; 
				g=g*c-x*s; 
				h=y*s; 
				y*=c; 
				for(jj=1;jj<=n;jj++)
				{ 
					x=v[jj][j]; 
					z=v[jj][i]; 
					v[jj][j]=x*c+z*s; 
					v[jj][i]=z*c-x*s; 
				} 
				z=pythag(f,h); 
				w[j]=z; // Rotation can be arbitrary if z=0. 
				if(z)
				{ 
					z=1.0/z; 
					c=f*z; 
					s=h*z; 
				} 
				f=c*g+s*y; 
				x=c*y-s*g;
				for(jj=1;jj<=m;jj++)
				{ 
					y=a[jj][j]; 
					z=a[jj][i]; 
					a[jj][j]=y*c+z*s; 
					a[jj][i]=z*c-y*s; 
				} 
			} 
			rv1[l]=0.0; 
			rv1[k]=f; 
			w[k]=x; 
		} 
	} 
	free(rv1); 
} 

#pragma mark -
#pragma mark [   Fit model using SVD   ]
/*
Solves A*X=B for a vector X, where A is specified by the arrays u[1..m][1..n], w[1..n], 
v[1..n][1..n] as returned by svdcmp. m and n are the dimensions of a, and will be equal for 
square matrices. b[1..m] is the input right-hand side. x[1..n] is the output solution vector. 
No input quantities are destroyed, so the routine may becalled sequentially with different b’s.
*/
void svbksb(double **u,double w[],double **v,int m,int n,double b[],double x[]) 
{ 
	int		jj,j,i; 
	double	s,*tmp; 
	
	tmp=(double*)calloc(n+1,sizeof(double));
	for(j=1;j<=n;j++)			// Calculate U^T*B.
	{
		s=0.0;
		if(w[j])					// Non zero result only if w_j is non zero.
		{
			for(i=1;i<=m;i++)
				s +=u[i][j]*b[i]; 
			s /=w[j];				// This is the divide by w_j. 
		} 
		tmp[j]=s; 
	} 
	for(j=1;j<=n;j++)			// Matrix multiply by V to get answer.
	{
		s=0.0; 
		for(jj=1;jj<=n;jj++)
			s+=v[j][jj]*tmp[jj]; 
		x[j]=s; 
	} 
	free(tmp); 
} 

/*
Given a set of data points x[1..ndata], y[1..ndata] with individual standard deviations 
sig[1..ndata], use X^2 minimization to determine the coefficients a[1..ma] of the fit- 
ting function y = Sum_i(a_i*func_i(x)). Here we solve the fitting equations using singular 
value decomposition of the ndata by ma matrix, as in 2.6. Arrays u[1..ndata][1..ma], 
v[1..ma][1..ma], and w[1..ma] provide workspace on input; on output they define the 
singular value decomposition, and can be used to obtain the covariance matrix. The pro- 
gram returns values for the ma fit parameters a, and X^2, chisq. The user supplies a routine 
funcs(i,afunc,ma) that returns the ma basis functions evaluated at x=\bold{x} in the array 
afunc[1..ma].
*/
void svdfit(double y[],double sig[],int ndata,
			double a[],int ma, void(*funcs)(int,double[],Model*,int), Model *m,
			double **u,double **v,double w[],double *chisq) 
{ 
	int		j,i; 
	double	wmax,tmp,thresh,sum,*b,*afunc; 
	
	b=(double*)calloc(ndata+1,sizeof(double));
	afunc=(double*)calloc(ma+1,sizeof(double));
	for(i=1;i<=ndata;i++)			// Accumulate coefficients of the fitting ma- 
	{								// trix.
		(*funcs)(i,afunc,m,ma); 
		tmp=1.0/sig[i]; 
		for(j=1;j<=ma;j++) u[i][j]=afunc[j]*tmp; 
		b[i]=y[i]*tmp; 
	}
	
	svdcmp(u,ndata,ma,w,v);			// Singular value decomposition.
	
	wmax=0.0;						// Edit the singular values, given TOL from the 
	for(j=1;j<=ma;j++)				// #define statement, between here...
		if(w[j]>wmax) wmax=w[j]; 
	thresh=0;//TOL*wmax; 
	for(j=1;j<=ma;j++) 
		if(w[j]<thresh) w[j]=0.0;	// ...and here. 
	svbksb(u,w,v,ndata,ma,b,a); 
	*chisq=0.0;						// Evaluate chi-square. 
	for(i=1;i<=ndata;i++)
	{ 
		(*funcs)(i,afunc,m,ma); 
		for(sum=0.0,j=1;j<=ma;j++) sum+=a[j]*afunc[j]; 
		*chisq+=(tmp=(y[i]-sum)/sig[i],tmp*tmp); 
	} 
	free(afunc); 
	free(b); 
}

/*
To evaluate the covariance matrix cvm[1..ma][1..ma] of the fit for ma parameters obtained 
by svdfit, call this routine with matrices v[1..ma][1..ma], w[1..ma] as returned from 
svdfit. 
*/
void svdvar(double **v,int ma,double w[],double **cvm) 
{ 
	int		k,j,i; 
	double	sum,*wti; 
	
	wti=(double*)calloc(ma+1,sizeof(double));
	for(i=1;i<=ma;i++)
	{ 
		wti[i]=0.0; 
		if(w[i]) wti[i]=1.0/(w[i]*w[i]); 
	} 
	for(i=1;i<=ma;i++)				// Sum contributions to covariance matrix (15.4.20).
	{ 
		for(j=1;j<=i;j++)
		{ 
			for(sum=0.0,k=1;k<=ma;k++) sum+=v[i][k]*v[j][k]*wti[k]; 
			cvm[j][i]=cvm[i][j]=sum; 
		} 
	} 
	free(wti); 
}
#pragma mark -
#pragma mark [   Perform F-test and single effect test for a specific model  ]
void fmodel(int i, double p[], Model *m, int ma)
{				
	int	j;
	
	for(j=1;j<=ma;j++)
	{
		switch((m->e[j]).type)
		{
			case kI:
				p[j]=1;
				break;
			case kC:
				p[j]=(1-2*indep[(m->e[j]).e1][i]);
				break;
			case kQ:
				p[j]=indep[(m->e[j]).e1][i] - (m->e[j]).m1;
				break;
			case kCC:
				p[j]=(1-2*indep[(m->e[j]).e1][i])*(1-2*indep[(m->e[j]).e2][i]);
				break;
			case kQQ:
				p[j]=(indep[(m->e[j]).e1][i]-(m->e[j]).m1)*(indep[(m->e[j]).e2][i]-(m->e[j]).m2);
				break;
			case kCQ:
				p[j]=(1-2*indep[(m->e[j]).e1][i])*(indep[(m->e[j]).e2][i]-(m->e[j]).m2);
				break;
		}
	}
}