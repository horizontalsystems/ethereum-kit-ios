// @PUBLIC_HEADER
/** @file
 * Bitcoin verification.
 * */

#ifndef in3_btc_h__
#define in3_btc_h__

#include "verifier.h"

/** entry-function to execute the verification context. */
in3_ret_t in3_verify_btc(in3_vctx_t* v);

/**
 * this function should only be called once and will register the bitcoin verifier.
 */
void in3_register_btc();

#endif // in3_btc_h__
