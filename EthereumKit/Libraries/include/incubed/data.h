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
 * json-parser.
 * 
 * The parser can read from :
 * - json
 * - bin
 * 
 * When reading from json all '0x'... values will be stored as bytes_t. If the value is lower than 0xFFFFFFF, it is converted as integer.
 * 
 * 
 * */

#include "bytes.h"
#include "stringbuilder.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#ifndef __DATA_H__
#define __DATA_H__
#ifndef DATA_DEPTH_MAX
/** the max DEPTH of the JSON-data allowed. It will throw an error if reached. */
#define DATA_DEPTH_MAX 11
#endif

typedef uint16_t d_key_t;
/** type of a token. */
typedef enum {
  T_BYTES   = 0, /**< content is stored as data ptr. */
  T_STRING  = 1, /**<content is stored a c-str*/
  T_ARRAY   = 2, /**< the node is an array with the length stored in length */
  T_OBJECT  = 3, /**< the node is an object with properties*/
  T_BOOLEAN = 4, /**< boolean with the value stored in len */
  T_INTEGER = 5, /**< a integer with the value stored */
  T_NULL    = 6  /**< a NULL-value */
} d_type_t;

/** a token holding any kind of value. 
 * 
 * use d_type,  d_len or the cast-function to get the value.
 */
typedef struct item {
  uint8_t* data; /**< the byte or string-data  */
  uint32_t len;  /**< the length of the content (or number of properties) depending +  type. */
  d_key_t  key;  /**< the key of the property. */
} d_token_t;

/** internal type used to represent the a range within a string. */
typedef struct str_range {
  char*  data; /**< pointer to the start of the string */
  size_t len;  /**< len of the characters */
} str_range_t;

/** parser for json or binary-data. it needs to freed after usage.*/
typedef struct json_parser {
  d_token_t* result;    /**< the list of all tokens. the first token is the main-token as returned by the parser.*/
  char*      c;         /** pointer to the src-data*/
  size_t     allocated; /** amount of tokens allocated result */
  size_t     len;       /** number of tokens in result */
  size_t     depth;     /** max depth of tokens in result */
} json_ctx_t;

/**
 * 
 * returns the byte-representation of token. 
 * 
 * In case of a number it is returned as bigendian. 
 * booleans as 0x01 or 0x00 
 * and NULL as 0x.
 * Objects or arrays will return 0x.
 */
bytes_t                d_to_bytes(d_token_t* item);
int                    d_bytes_to(d_token_t* item, uint8_t* dst, const int max);                                        /**< writes the byte-representation to the dst. details see d_to_bytes.*/
bytes_t*               d_bytes(const d_token_t* item);                                                                  /**< returns the value as bytes (Carefully, make sure that the token is a bytes-type!)*/
bytes_t*               d_bytesl(d_token_t* item, size_t l);                                                             /**< returns the value as bytes with length l (may reallocates) */
char*                  d_string(const d_token_t* item);                                                                 /**< converts the value as string. Make sure the type is string! */
int32_t                d_int(const d_token_t* item);                                                                    /**< returns the value as integer. only if type is integer */
int32_t                d_intd(const d_token_t* item, const uint32_t def_val);                                           /**< returns the value as integer or if NULL the default. only if type is integer */
uint64_t               d_long(const d_token_t* item);                                                                   /**< returns the value as long. only if type is integer or bytes, but short enough */
uint64_t               d_longd(const d_token_t* item, const uint64_t def_val);                                          /**< returns the value as long or if NULL the default. only if type is integer or bytes, but short enough */
bytes_t**              d_create_bytes_vec(const d_token_t* arr);                                                        /** creates a array of bytes from JOSN-array */
static inline d_type_t d_type(const d_token_t* item) { return item == NULL ? T_NULL : (item->len & 0xF0000000) >> 28; } /**< type of the token */
static inline int      d_len(const d_token_t* item) { return item == NULL ? 0 : item->len & 0xFFFFFFF; }                /**< number of elements in the token (only for object or array, other will return 0) */
bool                   d_eq(const d_token_t* a, const d_token_t* b);                                                    /**< compares 2 token and if the value is equal */
d_key_t                keyn(const char* c, const size_t len);                                                           /**< generates the keyhash for the given stringrange as defined by len */

d_token_t* d_get(d_token_t* item, const uint16_t key);                          /**< returns the token with the given propertyname (only if item is a object) */
d_token_t* d_get_or(d_token_t* item, const uint16_t key1, const uint16_t key2); /**< returns the token with the given propertyname or if not found, tries the other. (only if item is a object) */
d_token_t* d_get_at(d_token_t* item, const uint32_t index);                     /**< returns the token of an array with the given index */
d_token_t* d_next(d_token_t* item);                                             /**< returns the next sibling of an array or object */

void        d_serialize_binary(bytes_builder_t* bb, d_token_t* t); /**< write the token as binary data into the builder */
json_ctx_t* parse_binary(const bytes_t* data);                     /**< parses the data and returns the context with the token, which needs to be freed after usage! */
json_ctx_t* parse_binary_str(const char* data, int len);           /**< parses the data and returns the context with the token, which needs to be freed after usage! */
json_ctx_t* parse_json(char* js);                                  /**< parses json-data, which needs to be freed after usage! */
void        json_free(json_ctx_t* parser_ctx);                     /**< frees the parse-context after usage */
str_range_t d_to_json(const d_token_t* item);                      /**< returns the string for a object or array. This only works for json as string. For binary it will not work! */
char*       d_create_json(d_token_t* item);                        /**< creates a json-string. It does not work for objects if the parsed data were binary!*/

json_ctx_t* json_create();
d_token_t*  json_create_null(json_ctx_t* jp);
d_token_t*  json_create_bool(json_ctx_t* jp, bool value);
d_token_t*  json_create_int(json_ctx_t* jp, uint64_t value);
d_token_t*  json_create_string(json_ctx_t* jp, char* value);
d_token_t*  json_create_bytes(json_ctx_t* jp, bytes_t value);
d_token_t*  json_create_object(json_ctx_t* jp);
d_token_t*  json_create_array(json_ctx_t* jp);
d_token_t*  json_object_add_prop(d_token_t* object, d_key_t key, d_token_t* value);
d_token_t*  json_array_add_value(d_token_t* object, d_token_t* value);

// Helper function to map string to 2byte keys (only for tests or debugging)
char* d_get_keystr(d_key_t k);     /**< returns the string for a key. This only works track_keynames was activated before! */
void  d_track_keynames(uint8_t v); /**< activates the keyname-cache, which stores the string for the keys when parsing. */
void  d_clear_keynames();          /**< delete the cached keynames */

#ifndef IN3_DONT_HASH_KEYS
static inline d_key_t key(const char* c) {
  uint16_t val = 0;
  size_t   l   = strlen(c);
  for (; l; l--, c++) val ^= *c | val << 7;
  return val;
}
#else
d_key_t key(const char* c);
#endif

static inline char*    d_get_stringk(d_token_t* r, d_key_t k) { return d_string(d_get(r, k)); }              /**< reads token of a property as string. */
static inline char*    d_get_string(d_token_t* r, char* k) { return d_get_stringk(r, key(k)); }              /**< reads token of a property as string. */
static inline char*    d_get_string_at(d_token_t* r, uint32_t pos) { return d_string(d_get_at(r, pos)); }    /**< reads string at given pos of an array. */
static inline int32_t  d_get_intk(d_token_t* r, d_key_t k) { return d_int(d_get(r, k)); }                    /**< reads token of a property as int. */
static inline int32_t  d_get_intkd(d_token_t* r, d_key_t k, uint32_t d) { return d_intd(d_get(r, k), d); }   /**< reads token of a property as int. */
static inline int32_t  d_get_int(d_token_t* r, char* k) { return d_get_intk(r, key(k)); }                    /**< reads token of a property as int. */
static inline int32_t  d_get_int_at(d_token_t* r, uint32_t pos) { return d_int(d_get_at(r, pos)); }          /**< reads a int at given pos of an array. */
static inline uint64_t d_get_longk(d_token_t* r, d_key_t k) { return d_long(d_get(r, k)); }                  /**< reads token of a property as long. */
static inline uint64_t d_get_longkd(d_token_t* r, d_key_t k, uint64_t d) { return d_longd(d_get(r, k), d); } /**< reads token of a property as long. */
static inline uint64_t d_get_long(d_token_t* r, char* k) { return d_get_longk(r, key(k)); }                  /**< reads token of a property as long. */
static inline uint64_t d_get_long_at(d_token_t* r, uint32_t pos) { return d_long(d_get_at(r, pos)); }        /**< reads long at given pos of an array. */
static inline bytes_t* d_get_bytesk(d_token_t* r, d_key_t k) { return d_bytes(d_get(r, k)); }                /**< reads token of a property as bytes. */
static inline bytes_t* d_get_bytes(d_token_t* r, char* k) { return d_get_bytesk(r, key(k)); }                /**< reads token of a property as bytes. */
static inline bytes_t* d_get_bytes_at(d_token_t* r, uint32_t pos) { return d_bytes(d_get_at(r, pos)); }      /**< reads bytes at given pos of an array. */
static inline bool     d_is_binary_ctx(json_ctx_t* ctx) { return ctx->allocated == 0; }                      /**< check if the parser context was created from binary data. */
bytes_t*               d_get_byteskl(d_token_t* r, d_key_t k, uint32_t minl);
d_token_t*             d_getl(d_token_t* item, uint16_t k, uint32_t minl);

/**
 * iterator over elements of a array opf object.
 * 
 * usage:
 * ```c
 * for (d_iterator_t iter = d_iter( parent ); iter.left ; d_iter_next(&iter)) {
 *   uint32_t val = d_int(iter.token);
 * }
 * ```
 */
typedef struct d_iterator {
  d_token_t* token; /**< current token */
  int        left;  /**< number of result left */
} d_iterator_t;

static inline d_iterator_t d_iter(d_token_t* parent) { return (d_iterator_t){.left = d_len(parent), .token = parent + 1}; } /**< creates a iterator for a object or array */
static inline bool         d_iter_next(d_iterator_t* const iter) {
  iter->token = d_next(iter->token);
  return iter->left--;
} /**< fetched the next token an returns a boolean indicating whther there is a next or not.*/

#ifdef __ZEPHYR__

#define printX printk
#define fprintX fprintf // (kg): fprintk caused link-problems!
#define snprintX snprintk
#define vprintX vprintk

#else

#define printX printf
#define fprintX fprintf
#define snprintX snprintf
#define vprintX vprintf

#endif

#endif
