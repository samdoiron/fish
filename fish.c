#include "fish.h"
#include <stdio.h>


/* Printing Functions */
void pint(int a) {
    printf("%d\n", a);
}

void pstring(char *a) {
    printf("%s\n", a);
}

void pdouble(double a) {
    printf("%f\n", a);
}

void pfloat(float a) {
    printf("%s\n", a);
}

/* Conversion Functions */
int str_int(char *a) {
    return atoi(a);
}

char *int_str(int a) {
    char str[15];
    sprintf(str, "%d", a);
    return str;
}


