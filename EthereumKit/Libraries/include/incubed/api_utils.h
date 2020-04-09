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
 * Ethereum API utils.
 *
 * This header-file helper utils for use with API modules.
 * */

#ifndef IN3_API_UTILS_H
#define IN3_API_UTILS_H

#include "client.h"

/**
 * a 32 byte long integer used to store ethereum-numbers.
 *
 * use the as_long() or as_double() to convert this to a useable number.
*/
typedef struct {
  uint8_t data[32];
} uint256_t;

// Helper functions
long double as_double(uint256_t d);                                          /**< Converts a uint256_t in a long double. Important: since a long double stores max 16 byte, there is no guarantee to have the full precision. */
uint64_t    as_long(uint256_t d);                                            /**< Converts a uint256_t in a long . Important: since a long double stores 8 byte, this will only use the last 8 byte of the value. */
uint256_t   to_uint256(uint64_t value);                                      /**< Converts a uint64_t into its uint256_t representation. */
in3_ret_t   decrypt_key(d_token_t* key_data, char* password, bytes32_t dst); /**< Decrypts the private key from a json keystore file using PBKDF2 or SCRYPT (if enabled) */

// more helper
in3_ret_t to_checksum(address_t adr, chain_id_t chain_id, char out[43]); /**< converts the given address to a checksum address. If chain_id is passed, it will use the EIP1191 to include it as well. */

/**
 * function to set error. Will only be called internally.
 * default implementation is NOT MT safe!
 */
typedef void (*set_error_fn)(int err, const char* msg);
void api_set_error_fn(set_error_fn fn);

/**
 * function to get last error message.
 * default implementation is NOT MT safe!
 */
typedef char* (*get_error_fn)(void);
void api_get_error_fn(get_error_fn fn);

/** returns current error or null if all is ok */
char* api_last_error();

#endif //IN3_API_UTILS_H
