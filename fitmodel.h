#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define kTESTWHOLE	1
#define kTESTEFFECT	2

#define	kI	1
#define	kC	2
#define	kQ	3
#define	kCC	4
#define	kQQ	5
#define	kCQ	6

typedef struct
{
	int	type;
	int	e1;
	int	e2;
	double	m1;
	double	m2;
}Effect;
typedef struct
{
	int		n;
	Effect	*e;
}Model;

double	**indep;
void svdfit(double y[],double sig[],int ndata,
			double a[],int ma, void(*funcs)(int,double[],Model*,int), Model *m,
			double **u,double **v,double w[],double *chisq);
void fmodel(int i, double p[], Model *m, int ma);