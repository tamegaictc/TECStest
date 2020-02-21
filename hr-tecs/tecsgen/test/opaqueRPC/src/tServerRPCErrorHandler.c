/*
 * This file was automatically generated by tecsgen.
 * Move and rename like below before editing,
 *   gen/tServerRPCErrorHandler_template.c => src/tServerRPCErrorHandler.c
 * to avoid to be overwritten by tecsgen.
 */
/* #[<PREAMBLE>]#
 * Don't edit the comments between #[<...>]# and #[</...>]#
 * These comment are used by tecsmerege when merging.
 *
 * call port function #_TCPF_#
 * call port : cOpener  signature: sServerChannelOpener context: task
 *   ER             cOpener_open( );
 *   ER             cOpener_close( );
 *
 * #[</PREAMBLE>]# */

/* Put prototype declaration and/or variale definition here #_PAC_# */
#include "tServerRPCErrorHandler_tecsgen.h"

#ifndef E_OK
#define	E_OK	0		/* success */
#define	E_ID	(-18)	/* illegal ID */
#endif

/* entry port function #_TEPF_# */
/* #[<ENTRY_PORT>]# eHandler
 * entry port: eHandler
 * signature:  sRPCErrorHandler
 * context:    task
 * #[</ENTRY_PORT>]# */

/* #[<ENTRY_FUNC>]# eHandler_errorOccured
 * name:         eHandler_errorOccured
 * global_name:  tServerRPCErrorHandler_eHandler_errorOccured
 * oneway:       false
 * #[</ENTRY_FUNC>]# */
ER
eHandler_errorOccured(CELLIDX idx, int16_t func_id, ER er, int16_t state)
{
	ER		ercd = E_OK;
	CELLCB	*p_cellcb;
	if (VALID_IDX(idx)) {
		p_cellcb = GET_CELLCB(idx);
	}
	else {
		return(E_ID);
	} /* end if VALID_IDX(idx) */

	/* Put statements here #_TEFB_# */

	/* チャンネルを閉じたのち、1秒休憩して、再度開きなおす */
	syslog( LOG_INFO, "ServerHandler closing channel" );
	cOpener_close( );
	sleep(1);
	syslog( LOG_INFO, "ServerHandler reopen channel" );
	cOpener_open( );

	return(ercd);
}

/* #[<POSTAMBLE>]#
 *   Put non-entry functions below.
 * #[</POSTAMBLE>]#*/
