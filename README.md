# Conjunto de Mandelbrot (basado en Julia)

## **Mandel_J.c**: Programa que genera una imagen .tga del conjunto fractal de Mandelbrot

Se ejecuta pasando 2 parámetros:
1. Dimensión de la imagen de salida: por ejemplo, 1000.
2. Nº máximo de iteraciones: por ejemplo, 100 para pruebas, 5000 para evaluar tiempos.

Ejemplo de ejecución:

```bash
$ ./Mandel_J 1000 5000

```

Este comando genera el archivo **mandelbrot.tga**, que se puede visualizar con eog:

```bash

$ eog mandelbrot.tga

```
## Resultados
Los resultados se pueden consultar en el documento **mandelbrot_results.pdf**
