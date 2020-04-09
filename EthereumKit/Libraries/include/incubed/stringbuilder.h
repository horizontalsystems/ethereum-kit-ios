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
 * simple string buffer used to dynamicly add content.
 * */

#ifndef __STR_BUILDER_H__
#define __STR_BUILDER_H__

#include "bytes.h"
#include <stdbool.h>
#include <stddef.h>

/** shortcut macro for adding a uint to the stringbuilder using sizeof(i) to automaticly determine the size*/
#define sb_add_hexuint(sb, i) sb_add_hexuint_l(sb, i, sizeof(i))

#ifdef __ZEPHYR__
typedef unsigned long long uintmax_t;
#endif

/**
 * string build struct, which is able to hold and modify a growing string. 
 */
typedef struct sb {
  char*  data;     /**< the current string (null terminated)*/
  size_t allocted; /**< number of bytes currently allocated */
  size_t len;      /**< the current length of the string */
} sb_t;

sb_t* sb_new(const char* chars); /**< creates a new stringbuilder and copies the inital characters into it.*/
sb_t* sb_init(sb_t* sb);         /**< initializes a stringbuilder by allocating memory. */
void  sb_free(sb_t* sb);         /**< frees all resources of the stringbuilder */

sb_t* sb_add_char(sb_t* sb, char c);                                                                 /**< add a single character */
sb_t* sb_add_chars(sb_t* sb, const char* chars);                                                     /**< adds a string */
sb_t* sb_add_range(sb_t* sb, const char* chars, int start, int len);                                 /**< add a string range */
sb_t* sb_add_key_value(sb_t* sb, const char* key, const char* value, int value_len, bool as_string); /**< adds a value with an optional key. if as_string is true the value will be quoted. */
sb_t* sb_add_bytes(sb_t* sb, const char* prefix, const bytes_t* bytes, int len, bool as_array);      /**< add bytes as 0x-prefixed hexcoded string (including an optional prefix), if len>1 is passed bytes maybe an array ( if as_array==true)  */
sb_t* sb_add_hexuint_l(sb_t* sb, uintmax_t uint, size_t l);                                          /**< add a integer value as hexcoded, 0x-prefixed string*/

#endif
