#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>

#define PRECISION 13

double frac(double x)
{
    assert(x >= 0.0);
    return x - (double) (uint64_t) x;
}

void print_frac(double f)
{
    double R = f;
    double M = pow(10.0, -PRECISION) * 0.5;
    double U = 0.0;

    while (1) {
        U = R * 10.0;
        R = frac(R * 10.0);
        M = M * 10.0;
        if (!(M <= R && R <= 1.0 - M)) break;
        putc(((char) U) + '0', stdout);
    }

    if (R <= 0.5) {
        putc(((char) U) + '0', stdout);
    } else if (R >= 0.5) {
        putc(((char) U + 1) + '0', stdout);
    }
    putc('\n', stdout);
}

void print_f64(double x)
{
    assert(x >= 0.0);

    if ((1.0 - frac(x)) <= pow(10.0, -PRECISION) * 0.5) {
        printf("%"PRIu64, (uint64_t) (x - frac(x) + 1));
        printf(".0");
    } else {
        printf("%"PRIu64, (uint64_t) (x - frac(x)));
        printf(".");
        print_frac(frac(x));
    }
    printf("\n");
}

int main(void)
{
    const uint64_t x = 0x407a3fffffffffff; // 419.(9)
    // const uint64_t x = 0x4024000000000000;
    // const uint64_t x = 0x3fefffffffffec00;

    print_f64(*(double*)&x);

    // printf("%.20lf\n", *(double*)&x);
    // printf("%.20lf\n", *(double*)&x - (double)(uint64_t)*(double*)&x);

    // printf("%c\n", 10 + '0');

    return 0;
}
