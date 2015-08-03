/*
 *  fdr.c
 *  ac_explorer
 *
 *  Created by rOBERTO tORO on 16/06/2007.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#include "fdr.h"

float gammln(float xx)
{
	double x,y,tmp,ser;
	static double cof[6]={76.18009172947146,-86.50532032941677,
		24.01409824083091,-1.231739572450155,
		0.1208650973866179e-2,-0.5395239384953e-5};
	int j;
    
	y=x=xx;
	tmp=x+5.5;
	tmp -= (x+0.5)*log(tmp);
	ser=1.000000000190015;
	for (j=0;j<=5;j++) ser += cof[j]/++y;
	return -tmp+log(2.5066282746310005*ser/x);
}
#define MAXIT	5000
#define EPS		3.0e-7
#define FPMIN	1.0e-30
float betacf(float a, float b, float x)
{
	void nrerror(char error_text[]);
	int m,m2;
	float aa,c,d,del,h,qab,qam,qap;
    
	qab=a+b;
	qap=a+1.0;
	qam=a-1.0;
	c=1.0;
	d=1.0-qab*x/qap;
	if (fabs(d) < FPMIN) d=FPMIN;
	d=1.0/d;
	h=d;
	for (m=1;m<=MAXIT;m++) {
		m2=2*m;
		aa=m*(b-m)*x/((qam+m2)*(a+m2));
		d=1.0+aa*d;
		if (fabs(d) < FPMIN) d=FPMIN;
		c=1.0+aa/c;
		if (fabs(c) < FPMIN) c=FPMIN;
		d=1.0/d;
		h *= d*c;
		aa = -(a+m)*(qab+m)*x/((a+m2)*(qap+m2));
		d=1.0+aa*d;
		if (fabs(d) < FPMIN) d=FPMIN;
		c=1.0+aa/c;
		if (fabs(c) < FPMIN) c=FPMIN;
		d=1.0/d;
		del=d*c;
		h *= del;
		if (fabs(del-1.0) < EPS) break;
	}
	if (m > MAXIT) printf("a or b too big, or MAXIT too small in betacf\n");
	return h;
}
float betai(float a, float b, float x)
{
	float bt;
    
	if (x < 0.0 || x > 1.0) printf("Bad x in routine betai {x=%f}\n",x);
	if (x == 0.0 || x == 1.0) bt=0.0;
	else
		bt=exp(gammln(a+b)-gammln(a)-gammln(b)+a*log(x)+b*log(1.0-x));
	if (x < (a+1.0)/(a+b+2.0))
		return bt*betacf(a,b,x)/a;
	else
		return 1.0-bt*betacf(b,a,1.0-x)/b;
}
#pragma mark -
void gser(double *gamser,double a,double x,double *gln)
// Returns the incomplete gamma function P(a,x) evaluated by its series representation as gamser.
// Also returns ln Gamma(a) as gln.
{
	int		n;
	float	sum,del,ap;
	
	*gln=gammln(a);
	if(x<=0.0)
	{
		if(x<0.0)
			printf("x less than 0 in routine gser\n");
		*gamser=0.0;
		return;
	}
	else
	{
		ap=a;
		del=sum=1.0/a;
		for(n=1;n<=MAXIT;n++)
		{
			++ap;
			del*=x/ap;
			sum+=del;
			if(fabs(del)< fabs(sum)*EPS)
			{
				*gamser=sum*exp(-x+a*log(x)-(*gln));
				return;
			}
		}
		printf("a too large,MAXIT too small in routine gser\n");
		return;
	}
}

void gcf(double *gammcf,double a,double x,double *gln)
// Returns the incomplete gamma function Q(a,x) evaluated by its continued fraction represen-
// tation as gammcf. Also returns ln Gamma(a) as gln.
{
	int		i;
	double	an,b,c,d,del,h;
	
	*gln=gammln(a);
	b=x+1.0-a; // Setup for evaluating continued fraction by modified Lentz’s method(5.2) with b0=0.
	c=1.0/FPMIN;
	d=1.0/b;
	h=d;
	for(i=1;i<=MAXIT;i++) // Iterate to convergence.
	{
		an=-i*(i-a);
		b+=2.0;
		d=an*d+b;
		if(fabs(d)<FPMIN)
			d=FPMIN;
		c=b+an/c;
		if(fabs(c)<FPMIN)
			c=FPMIN;
		d=1.0/d;
		del=d*c;
		h*=del;
		if(fabs(del-1.0)< EPS)
			break;
	}
	if(i> MAXIT)
		printf("a too large, MAXIT too small in gcf\n");
	*gammcf=exp(-x+a*log(x)-(*gln))*h; // Put factors in front.
}
#undef MAXIT
#undef EPS
#undef FPMIN
double gammp(double a,double x)
// Returns the incomplete gamma function P(a,x).
{
	double	gamser,gammcf,gln;
	
	if(x< 0.0||a<=0.0)
		printf("Invalid arguments in routine gammp\n");
	if(x< (a+1.0)) // Use the series representation.
	{
		gser(&gamser,a,x,&gln);
		return gamser;
	}
	else // Use the continued fraction representation
	{
		gcf(&gammcf,a,x,&gln);
		return 1.0-gammcf; // and take its complement.
	}
}
#pragma mark -
int compare(const void *a, const void *b)
{
    
	float x=*(float*)a;
	float y=*(float*)b;
	
	if(x>y)
		return 1;
	if(x<y)
		return -1;
	else
		return 0;
}
float fdr_id(float *p, int n, float q)
{
	float	coef=q/(float)n;
	int		i;
	
	for(i=n-1;i>=0;i--)
		if(p[i]<(i+1)*coef)
			break;
	
	return p[i];
}
float fdr_n(float *p, int n, float q)
{
	float	cVN,coef;
	int		i;
	
	cVN=0;
	for(i=1;i<=n;i++)
		cVN+=1/(float)i;
	coef=q/(cVN*n);
	
	for(i=n-1;i>=0;i--)
		if(p[i]<(i+1)*coef)
			break;
	
	if(i>=0)
		return p[i];
	else
		return 0;
}
float fdr_independent(float *p, int n, float q)
{
	qsort(p,n,sizeof(float),compare);
    
	return fdr_id(p,n,q);
}
float fdr_nonparametric(float *p, int n, float q)
{
	qsort(p,n,sizeof(float),compare);
    
	return fdr_n(p,n,q);
}
float f2p(float f, int dfnum, int dfden)
{
/* F-ratio value to p-value */
    float	x,a,b,p;
	
	x=dfden/(float)(dfden+dfnum*f);
	a=dfden/2.0;
	b=dfnum/2.0;
	p=betai(a,b,x);
	return p;
}
float fdr2f(float *fratio, int nv, int dfnum, int dfden, float fdr)
{
/* FDR q-value to F-ratio value threshold
    dfnum= (df_model-1)
    dfden=(N-df_model)
    fdr=q-value
 */
	int		i;
	float	x;
	float	*pv;
	float	pvthr,fthr,l0,l1,p0,p1,m,n,min;

	// compute p-value volume from f-ratio volume
	printf("convert F-ratio file to p-values\n");
	pv=(float*)calloc(nv,sizeof(float));
	min=1;
	for(i=0;i<nv;i++)
	{
		pv[i]=betai(dfden/2.0,dfnum/2.0,dfden/(float)(dfden+dfnum*fratio[i]));
		if(pv[i]<min)
			min=pv[i];
	}
	printf("minimum p-value in volume: %f\n",min);
    
	// compute fdr-adjusted p-value threshold
	printf("compute fdr-adjusted threshold\n");
	qsort(pv,nv,sizeof(float),compare);
	pvthr=fdr_n(pv,nv,fdr);
	printf(" %le(n) %le(id)\n",pvthr,fdr_id(pv,nv,fdr));
	
	// convert p-value threshold to f-ratio threshold
	printf("convert p-values threshold to F-ratio {dfnum=%i, dfden=%i}:\n",dfnum,dfden);
	if(pvthr>0)
	{
		l0=1;
		x=dfden/(float)(dfden+dfnum*l0);
		p0=betai(dfden/2.0,dfnum/2.0,x);
		printf("l0:%f p0:%f\n",l0,p0);
		
		l1=6;
		x=dfden/(float)(dfden+dfnum*l1);
		p1=betai(dfden/2.0,dfnum/2.0,x);
		printf("l1:%f p1:%f\n",l1,p1);
		
		fthr=0.5*(l0+l1);
        
		for(i=0;i<10;i++)
		{
			m=(l1-l0)/(p1-p0);
			n=l0-m*p0;
			fthr=m*pvthr+n;
			printf("(l0,p0):(%f,%f) (l1,p1):(%f,%f) m:%f n:%f fthr:%f\n",l0,p0,l1,p1,m,n,fthr);
			if(fabs(pvthr-p0)<fabs(pvthr-p1))
			{
				p1=betai(dfden/2.0,dfnum/2.0,dfden/(float)(dfden+dfnum*fthr));
				l1=fthr;
			}
			else
			{
				p0=betai(dfden/2.0,dfnum/2.0,dfden/(float)(dfden+dfnum*fthr));
				l0=fthr;
			}
			
			if(fabs(l0-l1)<10e-6)
				break;
		}
        
		free(pv);
		printf(" %f\n",fthr);
	}
	else
		printf("ERROR: F-threshold -> infinity\n");
	
	return fthr;
}