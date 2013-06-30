#include "fish.h"
#include <stdio.h>
#include <stdlib.h>

/* Lists */

// ListInt 
struct ListInt {
    int *list;
    int space;
    int spaceBuffer;
    int next;
};

ListInt *ListIntCreate() {
    ListInt *list = malloc(sizeof(ListInt));
    list->space = 100;
    list->spaceBuffer = list->space;
    list->next = 0;
    list->list = malloc(sizeof(int) * list->space);
    return list;
}

void addInt(ListInt *self, int a) {
    if (self->next > self->space) {
        // Too many items! We need to expand and copy
        int *newList = malloc((sizeof(int) * self->next) \
                + self->spaceBuffer);

        for (int i = 0; i < self->next; i++) {
            newList[i] = self->list[i];
        }
        
        self->list = newList;
    }

    self->list[(self->next)++] = a;
}



// ListString
struct ListString {
    char **list;
    int space;
    int spaceBuffer;
    int next;
};

ListString *ListStringCreate() {
    ListString *list = malloc(sizeof(ListString));
    list->space = 100;
    list->spaceBuffer = list->space;
    list->next = 0;
    list->list = malloc(list->space);
    return list;
}

void addString(ListString *self, char *a) {
    if (self->next > self->space) {
        // Too many items! We need to expand and copy
        char **newList = malloc(self->next + self->spaceBuffer);

        for (int i = 0; i < self->next; i++) {
            newList[i] = self->list[i];
        }
        
        self->list = newList;
    }

    self->list[(self->next)++] = a;
}

/* Conversion Functions */
int str_to_int(char *a) {
    return atoi(a);
}

char *int_to_str(int a) {
    char *str = malloc(15);
    sprintf(str, "%d", a);
    return str;
}

