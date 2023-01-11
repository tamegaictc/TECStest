#include <stdio.h>
#include "tSimple_tecsgen.h"

#ifndef E_OK
#define	E_OK	0		/* 正常終了 */
#define	E_ID	(-18)	/* 不正ID番号 */
#endif

void
eBody_main(CELLIDX idx)
{
	CELLCB *p_cellcb;
	char buf[256];
	if (VALID_IDX(idx)) {
		p_cellcb = GET_CELLCB(idx);
	}
	else {

	}

#define N_HELLO 3
	printf( "Simple: Say hello %d times.\n", N_HELLO );
	cCall_sayHello( N_HELLO );

	printf( "Simple: How are you?\n" );
	cCall_howAreYou( buf, sizeof(buf) );

	puts( buf );
}