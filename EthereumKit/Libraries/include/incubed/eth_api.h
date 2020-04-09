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

// @PUBLIC_HEADER
/** @file
 * Ethereum API.
 * 
 * This header-file defines easy to use function, which are preparing the JSON-RPC-Request, which is then executed and verified by the incubed-client. 
 * */

#ifndef ETH_API_H
#define ETH_API_H

#include "client.h"
#include "api_utils.h"
#include <stdarg.h>

/** Initializer macros for eth_blknum_t */
#define BLKNUM(blk) ((eth_blknum_t){.u64 = blk, .is_u64 = true})
#define BLKNUM_LATEST() ((eth_blknum_t){.def = BLK_LATEST, .is_u64 = false})
#define BLKNUM_EARLIEST() ((eth_blknum_t){.def = BLK_EARLIEST, .is_u64 = false})
#define BLKNUM_PENDING() ((eth_blknum_t){.def = BLK_PENDING, .is_u64 = false})

/**< The current error or null if all is ok */
#define eth_last_error() api_last_error()

/** Optional types */
DEFINE_OPTIONAL_T(uint64_t);
DEFINE_OPTIONAL_T(bytes_t);
DEFINE_OPTIONAL_T(address_t);
DEFINE_OPTIONAL_T(uint256_t);

/** A transaction */
typedef struct eth_tx {
  bytes32_t hash;              /**< the blockhash */
  bytes32_t block_hash;        /**< hash of ther containnig block */
  uint64_t  block_number;      /**< number of the containing block */
  address_t from;              /**< sender of the tx */
  uint64_t  gas;               /**< gas send along */
  uint64_t  gas_price;         /**< gas price used */
  bytes_t   data;              /**< data send along with the transaction */
  uint64_t  nonce;             /**< nonce of the transaction */
  address_t to;                /**< receiver of the address 0x0000.. -Address is used for contract creation. */
  uint256_t value;             /**< the value in wei send */
  int       transaction_index; /**< the transaction index */
  uint8_t   signature[65];     /**< signature of the transaction */
} eth_tx_t;

/** An Ethereum Block */
typedef struct eth_block {
  uint64_t   number;            /**< the blockNumber */
  bytes32_t  hash;              /**< the blockhash */
  uint64_t   gasUsed;           /**< gas used by all the transactions */
  uint64_t   gasLimit;          /**< gasLimit */
  address_t  author;            /**< the author of the block. */
  uint256_t  difficulty;        /**< the difficulty of the block. */
  bytes_t    extra_data;        /**< the extra_data of the block. */
  uint8_t    logsBloom[256];    /**< the logsBloom-data */
  bytes32_t  parent_hash;       /**< the hash of the parent-block */
  bytes32_t  sha3_uncles;       /**< root hash of the uncle-trie*/
  bytes32_t  state_root;        /**< root hash of the state-trie*/
  bytes32_t  receipts_root;     /**< root of the receipts trie */
  bytes32_t  transaction_root;  /**< root of the transaction trie */
  int        tx_count;          /**< number of transactions in the block */
  eth_tx_t*  tx_data;           /**< array of transaction data or NULL if not requested */
  bytes32_t* tx_hashes;         /**< array of transaction hashes or NULL if not requested */
  uint64_t   timestamp;         /**< the unix timestamp of the block */
  bytes_t*   seal_fields;       /**< sealed fields */
  int        seal_fields_count; /**< number of seal fields */

  /* data */
} eth_block_t;

/** A linked list of Ethereum Logs  */
typedef struct eth_log {
  bool            removed;           /**< true when the log was removed, due to a chain reorganization. false if its a valid log */
  size_t          log_index;         /**< log index position in the block */
  size_t          transaction_index; /**< transactions index position log was created from */
  bytes32_t       transaction_hash;  /**< hash of the transactions this log was created from */
  bytes32_t       block_hash;        /**< hash of the block where this log was in */
  uint64_t        block_number;      /**< the block number where this log was in */
  address_t       address;           /**< address from which this log originated */
  bytes_t         data;              /**< non-indexed arguments of the log */
  bytes32_t*      topics;            /**< array of 0 to 4 32 Bytes DATA of indexed log arguments */
  size_t          topic_count;       /**< counter for topics */
  struct eth_log* next;              /**< pointer to next log in list or NULL */
} eth_log_t;

/** A transaction receipt */
typedef struct eth_tx_receipt {
  bytes32_t  transaction_hash;    /**< the transaction hash */
  int        transaction_index;   /**< the transaction index */
  bytes32_t  block_hash;          /**< hash of ther containnig block */
  uint64_t   block_number;        /**< number of the containing block */
  uint64_t   cumulative_gas_used; /**< total amount of gas used by block */
  uint64_t   gas_used;            /**< amount of gas used by this specific transaction */
  bytes_t*   contract_address;    /**< contract address created (if the transaction was a contract creation) or NULL */
  bool       status;              /**< 1 if transaction succeeded, 0 otherwise. */
  eth_log_t* logs;                /**< array of log objects, which this transaction generated */
} eth_tx_receipt_t;

/** Abstract type for holding a block number */
typedef enum {
  BLK_LATEST,
  BLK_EARLIEST,
  BLK_PENDING
} eth_blknum_def_t;

typedef struct {
  union {
    uint64_t         u64;
    eth_blknum_def_t def;
  };
  bool is_u64;
} eth_blknum_t;

uint256_t         eth_getStorageAt(in3_t* in3, address_t account, bytes32_t key, eth_blknum_t block);      /**< Returns the storage value of a given address.*/
bytes_t           eth_getCode(in3_t* in3, address_t account, eth_blknum_t block);                          /**< Returns the code of the account of given address. (Make sure you free the data-point of the result after use.) */
uint256_t         eth_getBalance(in3_t* in3, address_t account, eth_blknum_t block);                       /**< Returns the balance of the account of given address. */
uint64_t          eth_blockNumber(in3_t* in3);                                                             /**< Returns the current price per gas in wei. */
uint64_t          eth_gasPrice(in3_t* in3);                                                                /**< Returns the current blockNumber, if bn==0 an error occured and you should check eth_last_error() */
eth_block_t*      eth_getBlockByNumber(in3_t* in3, eth_blknum_t number, bool include_tx);                  /**< Returns the block for the given number (if number==0, the latest will be returned). If result is null, check eth_last_error()! otherwise make sure to free the result after using it! */
eth_block_t*      eth_getBlockByHash(in3_t* in3, bytes32_t hash, bool include_tx);                         /**< Returns the block for the given hash. If result is null, check eth_last_error()! otherwise make sure to free the result after using it! */
eth_log_t*        eth_getLogs(in3_t* in3, char* fopt);                                                     /**< Returns a linked list of logs. If result is null, check eth_last_error()! otherwise make sure to free the log, its topics and data after using it! */
in3_ret_t         eth_newFilter(in3_t* in3, json_ctx_t* options);                                          /**< Creates a new event filter with specified options and returns its id (>0) on success or 0 on failure */
in3_ret_t         eth_newBlockFilter(in3_t* in3);                                                          /**< Creates a new block filter with specified options and returns its id (>0) on success or 0 on failure */
in3_ret_t         eth_newPendingTransactionFilter(in3_t* in3);                                             /**< Creates a new pending txn filter with specified options and returns its id on success or 0 on failure */
bool              eth_uninstallFilter(in3_t* in3, size_t id);                                              /**< Uninstalls a filter and returns true on success or false on failure */
in3_ret_t         eth_getFilterChanges(in3_t* in3, size_t id, bytes32_t** block_hashes, eth_log_t** logs); /**< Sets the logs (for event filter) or blockhashes (for block filter) that match a filter; returns <0 on error, otherwise no. of block hashes matched (for block filter) or 0 (for log filter) */
in3_ret_t         eth_getFilterLogs(in3_t* in3, size_t id, eth_log_t** logs);                              /**< Sets the logs (for event filter) or blockhashes (for block filter) that match a filter; returns <0 on error, otherwise no. of block hashes matched (for block filter) or 0 (for log filter) */
uint64_t          eth_chainId(in3_t* in3);                                                                 /**< Returns the currently configured chain id */
uint64_t          eth_getBlockTransactionCountByHash(in3_t* in3, bytes32_t hash);                          /**< Returns the number of transactions in a block from a block matching the given block hash. */
uint64_t          eth_getBlockTransactionCountByNumber(in3_t* in3, eth_blknum_t block);                    /**< Returns the number of transactions in a block from a block matching the given block number. */
json_ctx_t*       eth_call_fn(in3_t* in3, address_t contract, eth_blknum_t block, char* fn_sig, ...);      /**< Returns the result of a function_call. If result is null, check eth_last_error()! otherwise make sure to free the result after using it with json_free()! */
uint64_t          eth_estimate_fn(in3_t* in3, address_t contract, eth_blknum_t block, char* fn_sig, ...);  /**< Returns the result of a function_call. If result is null, check eth_last_error()! otherwise make sure to free the result after using it with json_free()! */
eth_tx_t*         eth_getTransactionByHash(in3_t* in3, bytes32_t tx_hash);                                 /**< Returns the information about a transaction requested by transaction hash. If result is null, check eth_last_error()! otherwise make sure to free the result after using it! */
eth_tx_t*         eth_getTransactionByBlockHashAndIndex(in3_t* in3, bytes32_t block_hash, size_t index);   /**< Returns the information about a transaction by block hash and transaction index position. If result is null, check eth_last_error()! otherwise make sure to free the result after using it! */
eth_tx_t*         eth_getTransactionByBlockNumberAndIndex(in3_t* in3, eth_blknum_t block, size_t index);   /**< Returns the information about a transaction by block number and transaction index position. If result is null, check eth_last_error()! otherwise make sure to free the result after using it! */
uint64_t          eth_getTransactionCount(in3_t* in3, address_t address, eth_blknum_t block);              /**< Returns the number of transactions sent from an address. */
eth_block_t*      eth_getUncleByBlockNumberAndIndex(in3_t* in3, eth_blknum_t block, size_t index);         /**< Returns information about a uncle of a block by number and uncle index position. If result is null, check eth_last_error()! otherwise make sure to free the result after using it! */
uint64_t          eth_getUncleCountByBlockHash(in3_t* in3, bytes32_t hash);                                /**< Returns the number of uncles in a block from a block matching the given block hash. */
uint64_t          eth_getUncleCountByBlockNumber(in3_t* in3, eth_blknum_t block);                          /**< Returns the number of uncles in a block from a block matching the given block number. */
bytes_t*          eth_sendTransaction(in3_t* in3, address_t from, address_t to, OPTIONAL_T(uint64_t) gas,  /* */
                                      OPTIONAL_T(uint64_t) gas_price, OPTIONAL_T(uint256_t) value,         /* */
                                      OPTIONAL_T(bytes_t) data, OPTIONAL_T(uint64_t) nonce);               /**< Creates new message call transaction or a contract creation. Returns (32 Bytes) - the transaction hash, or the zero hash if the transaction is not yet available. Free result after use with b_free(). */
bytes_t*          eth_sendRawTransaction(in3_t* in3, bytes_t data);                                        /**< Creates new message call transaction or a contract creation for signed transactions. Returns (32 Bytes) - the transaction hash, or the zero hash if the transaction is not yet available. Free after use with b_free(). */
eth_tx_receipt_t* eth_getTransactionReceipt(in3_t* in3, bytes32_t tx_hash);                                /**< Returns the receipt of a transaction by transaction hash. Free result after use with eth_tx_receipt_free() */
char*             eth_wait_for_receipt(in3_t* in3, bytes32_t tx_hash);                                     /**< Waits for receipt of a transaction requested by transaction hash. */
void              eth_log_free(eth_log_t* log);                                                            /**< Frees a eth_log_t object */
void              eth_tx_receipt_free(eth_tx_receipt_t* txr);                                              /**< Frees a eth_tx_receipt_t object */

/**
 * this function should only be called once and will register the eth-API verifier.
 */
void in3_register_eth_api();

#endif
