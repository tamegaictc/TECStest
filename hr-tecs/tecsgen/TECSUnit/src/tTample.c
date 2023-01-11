#include "tTample_tecsgen.h"
#include "tTample_factory.h"

#ifndef E_OK
#define E_OK 0
#define E_ID (-18)
#endif

ER
eHello_Hello(CELLIDX idx, int16_t y)
{
    ER ercd = E_OK;
    CELLCB *p_cellcb;
    if (VALID_IDX(idx)) {
        p_cellcb = GET_CELLCB(idx);
    }
    else {
        return(E_ID);
    }

    y = y + 1;
    printf("y = %d\n", y);

    return(ercd);
}