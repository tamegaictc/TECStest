#include <stdio.h>
#include <string.h>
#include "tSample_tecsgen.h"

#ifndef E_OK
#define E_OK 0
#define E_ID (-18)
#endif

ER
eEnt_sayHello(CELLIDX idx, int32_t times)
{
	ER ercd = E_OK;
	CELLCB *p_cellcb;
	if (VALID_IDX(idx)) {
		p_cellcb = GET_CELLCB(idx);
	}
	else {
		return(E_ID);
	}

	if( 0 < times ){
		if( times < 10){
			printf("Sample: ");
			while( times-- > 0 )
				printf("hello ");
			printf("\n");
		}
		else {
			printf("The argument is too large\n");
			return -1;
		}
	}
	else {
		printf("The argument is error number\n");
		return -1;
	}

	return(ercd);
}

ER
eEnt_howAreYou(CELLIDX idx, char_t* buf, int32_t len)
{
	ER ercd = E_OK;
	CELLCB *p_cellcb;
	if (VALID_IDX(idx)) {
		p_cellcb = GET_CELLCB(idx);
	}
	else {
		return(E_ID);
	}

	strncpy( buf, "Sample: I'm fine!", len );

	return(ercd);
}

ER
eEnt_BoundarySample(CELLIDX idx, int8_t x)
{
	ER ercd = E_OK;
	CELLCB *p_cellcb;
	if (VALID_IDX(idx)) {
		p_cellcb = GET_CELLCB(idx);
	}
	else {
		return(E_ID);
	}

	if( 0 < x &&  x < 100 ){
		printf("0 < The argument < 100\n");
		return 0;
	}
	printf("The argument is out of range\n");
	return -1;
}