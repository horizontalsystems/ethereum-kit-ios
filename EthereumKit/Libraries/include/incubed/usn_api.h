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
 * USN API.
 * 
 * This header-file defines easy to use function, which are verifying USN-Messages.
 * */

#ifndef USN_API_H
#define USN_API_H

#include "client.h"

typedef enum {
  USN_ACTION,
  USN_REQUEST,
  USN_RESPONSE

} usn_msg_type_t;

typedef struct {
  bytes32_t tx_hash;
  uint64_t  rented_from;
  uint64_t  rented_until;
  address_t controller;
  uint8_t   props[16];
} usn_booking_t;

typedef struct {
  char*          url;
  bytes32_t      id;
  int            num_bookings;
  usn_booking_t* bookings;
  int            current_booking;
} usn_device_t;

typedef struct {
  bool           accepted;
  char*          error_msg;
  char*          action;
  usn_msg_type_t msg_type;
  unsigned int   id;
  usn_device_t*  device;
} usn_msg_result_t;

typedef struct {
  bytes32_t device_id;
  char*     contract_name;
  uint64_t  counter;
} usn_url_t;

typedef enum {
  BOOKING_NONE,
  BOOKING_START,
  BOOKING_STOP
} usn_event_type_t;

typedef struct {
  uint64_t         ts;
  usn_device_t*    device;
  usn_event_type_t type;
} usn_event_t;

typedef int (*usn_booking_handler)(usn_event_t*);

typedef struct {
  in3_t*              c;
  address_t           contract;
  usn_device_t*       devices;
  int                 len_devices;
  chain_id_t          chain_id;
  uint64_t            now;
  uint64_t            last_checked_block;
  usn_booking_handler booking_handler;
} usn_device_conf_t;

usn_msg_result_t usn_verify_message(usn_device_conf_t* conf, char* message);
in3_ret_t        usn_register_device(usn_device_conf_t* conf, char* url);
usn_url_t        usn_parse_url(char* url);

unsigned int usn_update_state(usn_device_conf_t* conf, unsigned int wait_time);
in3_ret_t    usn_update_bookings(usn_device_conf_t* conf);
void         usn_remove_old_bookings(usn_device_conf_t* conf);
usn_event_t  usn_get_next_event(usn_device_conf_t* conf);

in3_ret_t usn_rent(in3_t* c, address_t contract, address_t token, char* url, uint32_t seconds, bytes32_t tx_hash);
in3_ret_t usn_return(in3_t* c, address_t contract, char* url, bytes32_t tx_hash);
in3_ret_t usn_price(in3_t* c, address_t contract, address_t token, char* url, uint32_t seconds, address_t controller, bytes32_t price);

#endif
