/*******************************************************************************
 * This file is part of the Incubed project.
 * Sources: https://github.com/slockit/in3-c
 * 
 * Copyright (C) 2018-2020 slock.it GmbH, Blockchains LLC
 * 
 * 
 * COMMERCIAL LICENSE USAGE
 * 
 * Licensees holding a valid commercial license may use this file in accordance 
 * with the commercial license agreement provided with the Software or, alternatively, 
 * in accordance with the terms contained in a written agreement between you and 
 * slock.it GmbH/Blockchains LLC. For licensing terms and conditions or further 
 * information please contact slock.it at in3@slock.it.
 * 	
 * Alternatively, this file may be used under the AGPL license as follows:
 *    
 * AGPL LICENSE USAGE
 * 
 * This program is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Affero General Public License as published by the Free Software 
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *  
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY 
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
 * PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
 * [Permissions of this strong copyleft license are conditioned on making available 
 * complete source code of licensed works and modifications, which include larger 
 * works using a licensed work, under the same license. Copyright and license notices 
 * must be preserved. Contributors provide an express grant of patent rights.]
 * You should have received a copy of the GNU Affero General Public License along 
 * with this program. If not, see <https://www.gnu.org/licenses/>.
 *******************************************************************************/

/** @file
 * Ethereum Nanon verification.
 * */

#ifndef in3_eth_basic_h__
#define in3_eth_basic_h__

#include "verifier.h"

/** entry-function to execute the verification context. */
in3_ret_t in3_verify_eth_basic(in3_vctx_t* v);
/**
 * verifies internal tx-values.
 */
in3_ret_t eth_verify_tx_values(in3_vctx_t* vc, d_token_t* tx, bytes_t* raw);

/**
 * verifies a transaction.
 */
in3_ret_t eth_verify_eth_getTransaction(in3_vctx_t* vc, bytes_t* tx_hash);

/**
 * verifies a transaction by block hash/number and id.
 */
in3_ret_t eth_verify_eth_getTransactionByBlock(in3_vctx_t* vc, d_token_t* blk, uint32_t tx_idx);

/**
 * verify account-proofs
 */
in3_ret_t eth_verify_account_proof(in3_vctx_t* vc);

/**
 * verifies a block
 */
in3_ret_t eth_verify_eth_getBlock(in3_vctx_t* vc, bytes_t* block_hash, uint64_t blockNumber);

/**
 * verifies block transaction count by number or hash
 */
in3_ret_t eth_verify_eth_getBlockTransactionCount(in3_vctx_t* vc, bytes_t* block_hash, uint64_t blockNumber);

/**
 * this function should only be called once and will register the eth-nano verifier.
 */
void in3_register_eth_basic();

/**
 *  verify logs
 */
in3_ret_t eth_verify_eth_getLog(in3_vctx_t* vc, int l_logs);

/**
 * this is called before a request is send
 */
in3_ret_t eth_handle_intern(in3_ctx_t* ctx, in3_response_t** response);

#endif // in3_eth_basic_h__
