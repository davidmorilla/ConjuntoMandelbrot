#include<stdlib.h>
#include<stdio.h>
#include<math.h>
#include <omp.h>
#include<complex.h>
#include<tgmath.h>
#include <sys/time.h>


#define DIM 1024

typedef struct{
	unsigned char re,gr,bl;
} color;

void tga_write ( int w, int h, unsigned char rgb[], char *filename );

color fcolor(int iter,int num_its){
        color c;
// Poner un color dependiente del no. de iteraciones
        c.re = 255;
        c.gr = (iter*15)%255;
        c.bl = (iter*15)%255;
        return c;
}

int explode(float _Complex z0, float _Complex c, int n) {
    int k = 1;
    int valor = 1;
    float _Complex z1 = (z0 * z0) + c;
    float modul = cabsf(z1);
    while (k <= n && modul <= 4) {
        z0 = z1;
        z1 = (z0 * z0) + c;
        modul = cabsf(z1);

        k++;
        valor = k;
    }

    return valor;
}

float _Complex mapPoint(int width,int height,int x,int y,float x_min, float x_max, float y_min, float y_max)
{
        float _Complex c;
        float xP = (float)(x) / (float) (width);
        float yP = (float) (y) / (float) (height);
        float re = x_min+(x_max-x_min)*xP;
        float im = y_min+(y_max-y_min)*yP;
	c = re+im*I;
        return c;
}

unsigned char *julMandel(int width,int height,int n){
        float x_min = -2.15;
        float x_max = 1.15;
        float y_min = -1.65;
        float y_max = 1.65;
	int x,y,i,linearIndex, iterations;
	float _Complex z0,z1;
	float _Complex c;
	color asp;
	int k;

        unsigned char *rgb;
        rgb = calloc ((width*height*3) ,sizeof(unsigned char));//inicializamos a negro
        iterations=width*height;
        #pragma omp parallel for simd schedule(dynamic) private(k,linearIndex, x, y, z0, c, i, asp)
 	for(linearIndex=0; linearIndex<iterations;linearIndex++){
 		k = linearIndex*3;
 		x=linearIndex%width;
 		y=linearIndex/width;
		c = mapPoint(width,height,x,y,x_min,x_max,y_min,y_max);
		z0=0+0*I;
		i = explode(z0,c,n);
		if (i<n) { // Si esta fuera se pinta en color dependiente de n_iteraciones
			asp = fcolor(i,n);
                        rgb[k]   = asp.bl;
                        rgb[k+1] = asp.gr;
                        rgb[k+2] = asp.re;
                }
	}
return rgb;
}

int main(int argC, char* argV[])
{
int i,j;
int width, height;
complex c;
unsigned char *rgb;
struct timeval tv_start, tv_end;
float tiempo_trans;

	if(argC != 3) {
		printf("Uso : %s\n", "<dim de la ventana, n_iteraciones>");
		exit(1);
	}
	else{
		width = atoi(argV[1]);
		height = width;

		if (width >DIM) {
		   printf("El tamanyo de la ventana deben ser menor que 1024\n");
		   exit(1);
		}

		printf("Mandelbrot: %d, %d, %d\n", width, height, atoi(argV[2]));
 
		gettimeofday(&tv_start, NULL);

		rgb = julMandel(width,height,atoi(argV[2]));

		gettimeofday(&tv_end, NULL);
		tiempo_trans=(tv_end.tv_sec - tv_start.tv_sec) * 1000000 +
		  (tv_end.tv_usec - tv_start.tv_usec); //en us
		printf("Tiempo Mandel_J = %f segundos\n", tiempo_trans/1000000);
	}

tga_write ( width, height, rgb, "mandelbrot.tga" );

free(rgb);
 
return 0;
}


/******************************************************************************/

void tga_write ( int w, int h, unsigned char rgb[], char *filename )

/******************************************************************************/
/*
  Purpose:

    TGA_WRITE writes a TGA or TARGA graphics file of the data.

  Licensing:

    This code is distributed under the GNU LGPL license.

  Modified:

    06 March 2017

  Parameters:

    Input, int W, H, the width and height of the image.

    Input, unsigned char RGB[W*H*3], the pixel data.

    Input, char *FILENAME, the name of the file to contain the screenshot.
*/
{
  FILE *file_unit;
  unsigned char header1[12] = { 0,0,2,0,0,0,0,0,0,0,0,0 };
  unsigned char header2[6] = { w%256, w/256, h%256, h/256, 24, 0 };
/* 
  Create the file.
*/
  file_unit = fopen ( filename, "wb" );
/*
  Write the headers.
*/
  fwrite ( header1, sizeof ( unsigned char ), 12, file_unit );
  fwrite ( header2, sizeof ( unsigned char ), 6, file_unit );
/*
  Write the image data.
*/
  fwrite ( rgb, sizeof ( unsigned char ), 3 * w * h, file_unit );
/*
  Close the file.
*/
  fclose ( file_unit );

  printf ( "\n" );
  printf ( "TGA_WRITE:\n" );
  printf ( "  Graphics data saved as '%s'\n", filename );

  return;
}
