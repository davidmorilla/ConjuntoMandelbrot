#include<stdlib.h>
#include<stdio.h>
#include<math.h>
#include<complex.h>
#include <cuComplex.h>
#include<tgmath.h>
#include <sys/time.h>


#define DIM 1024
#define THREADS_PER_BLOCK 128

typedef struct{
	unsigned char re,gr,bl;
} color;

void tga_write ( int w, int h, unsigned char rgb[], char *filename );

__device__ color fcolor(int iter,int num_its){
        color c;
// Poner un color dependiente del no. de iteraciones
        c.re = 255;
        c.gr = (iter*15)%255;
        c.bl = (iter*15)%255;
        return c;
}

__device__ int explode( cuFloatComplex z0, cuFloatComplex c, int n) {
    int k = 1;
    int valor = 1;
    cuFloatComplex aux= cuCmulf(z0,z0);
    cuFloatComplex z1 = cuCaddf(aux,c);
    float modul = cuCabsf(z1);
    while (k <= n && modul <= 4) {
        z0 = z1;
        z1 = cuCaddf(cuCmulf(z0, z0),c);
        modul = cuCabsf(z1);

        k++;
        valor = k;
    }

    return valor;
}

__device__ cuFloatComplex mapPoint(int width,int height,int x,int y,float x_min, float x_max, float y_min, float y_max)
{
        cuFloatComplex c;
        float xP = (float)(x) / (float) (width);
        float yP = (float) (y) / (float) (height);
        float re = x_min+(x_max-x_min)*xP;
        float im = y_min+(y_max-y_min)*yP;
	c = make_cuFloatComplex(re,im);
        return c;
}

__global__ void julMandelKernel(int width, int height, int n, unsigned char *rgb)
{
    int linearIndex = threadIdx.x + blockIdx.x * blockDim.x;
    if(linearIndex<width*height){
	    float x_min = -2.15;
	    float x_max = 1.15;
	    float y_min = -1.65;
	    float y_max = 1.65;
	    int x = linearIndex % width;
	    int y = linearIndex / width;
	    int k = linearIndex * 3;
	    cuFloatComplex c = mapPoint(width, height, x, y, x_min, x_max, y_min, y_max);
	    cuFloatComplex z0 = make_cuFloatComplex(0,0);
	    int i = explode(z0, c, n);

	    if (i < n)
	    {
		color asp = fcolor(i, n);
		rgb[k] = asp.bl;
		rgb[k + 1] = asp.gr;
		rgb[k + 2] = asp.re;
	    }
     }
}
unsigned char *julMandel(int width, int height, int n)
{
    unsigned char *rgb;
    rgb = (unsigned char *)calloc((width * height * 3), sizeof(unsigned char)); //inicializamos a negro

    int size = width * height * 3 * sizeof(unsigned char);
    unsigned char *d_rgb;
    cudaMalloc((void **)&d_rgb, size);

    int numBlocks = (width * height + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;

    julMandelKernel<<<numBlocks, THREADS_PER_BLOCK>>>(width, height, n, d_rgb);

    cudaMemcpy(rgb, d_rgb, size, cudaMemcpyDeviceToHost);
    cudaFree(d_rgb);

    return rgb;
}

int main(int argC, char* argV[])
{
int width, height;
//complex c;
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

