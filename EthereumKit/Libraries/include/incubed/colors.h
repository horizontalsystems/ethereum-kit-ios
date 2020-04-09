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

/*Term colors*/

#ifdef LOG_USE_COLOR
#define COLORT_RESET "\033[0m"
#define COLORT_BOLD "\033[1m"
#define COLORT_DIM "\033[2m"
#define COLORT_UNDERLINED "\033[4m"
#define COLORT_BLINK "\033[5m"
#define COLORT_REVERSE "\033[7m"
#define COLORT_HIDDEN "\033[8m"
#define COLORT_RESETBOLD "\033[21m"
#define COLORT_RESETDIM "\033[22m"
#define COLORT_RESETUNDERLINED "\033[24m"
#define COLORT_RESETBLINK "\033[25m"
#define COLORT_RESETREVERSE "\033[27m"
#define COLORT_RESETHIDDEN "\033[28m"
#define COLORT_DEFAULT "\033[39m"
#define COLORT_BLACK "\033[30m"
#define COLORT_BBLACK "\033[1;30m"
#define COLORT_RRED "\033[0;31m"
#define COLORT_RED "\033[31m"
#define COLORT_SELECT "\033[%sm"
#define COLORT_GREEN "\033[32m"
#define COLORT_RGREEN "\033[0;32m"
#define COLORT_YELLOW "\033[33m"
#define COLORT_RYELLOW "\033[0;33m"
#define COLORT_BLUE "\033[34m"
#define COLORT_MAGENTA "\033[35m"
#define COLORT_RMAGENTA "\033[0;35m"
#define COLORT_CYAN "\033[36m"
#define COLORT_LIGHTGRAY "\033[37m"
#define COLORT_DARKGRAY "\033[90m"
#define COLORT_LIGHTRED "\033[91m"
#define COLORT_LIGHTGREEN "\033[92m"
#define COLORT_LIGHTYELLOW "\033[93m"
#define COLORT_LIGHTBLUE "\033[94m"
#define COLORT_LIGHTMAGENTA "\033[95m"
#define COLORT_LIGHTCYAN "\033[96m"
#define COLORT_WHITE "\033[97m"
#else
#define COLORT_RESET " "
#define COLORT_BOLD ""
#define COLORT_DIM ""
#define COLORT_UNDERLINED ""
#define COLORT_BLINK ""
#define COLORT_REVERSE ""
#define COLORT_HIDDEN " "
#define COLORT_RESETBOLD ""
#define COLORT_RESETDIM ""
#define COLORT_RESETUNDERLINED ""
#define COLORT_RESETBLINK ""
#define COLORT_RESETREVERSE ""
#define COLORT_RESETHIDDEN " "
#define COLORT_DEFAULT ""
#define COLORT_BLACK ""
#define COLORT_BBLACK ""
#define COLORT_RRED " "
#define COLORT_RED " "
#define COLORT_SELECT "%s"
#define COLORT_GREEN ""
#define COLORT_RGREEN ""
#define COLORT_YELLOW " "
#define COLORT_RYELLOW ""
#define COLORT_BLUE ""
#define COLORT_MAGENTA ""
#define COLORT_RMAGENTA ""
#define COLORT_CYAN ""
#define COLORT_LIGHTGRAY ""
#define COLORT_DARKGRAY ""
#define COLORT_LIGHTRED ""
#define COLORT_LIGHTGREEN ""
#define COLORT_LIGHTYELLOW ""
#define COLORT_LIGHTBLUE ""
#define COLORT_LIGHTMAGENTA ""
#define COLORT_LIGHTCYAN ""
#define COLORT_WHITE ""
#endif

/* Control sequences, based on ANSI. 
Can be used to control color, and 
clear the screen
*/

#ifdef LOG_USE_COLOR
#define COLOR_RESET "\x1B[0m" // Reset to default colors
#define COLOR_CLEAR "\x1B[2J" // Clear screen, reposition cursor to top left
#define COLOR_BLACK "\x1B[30m"
#define COLOR_RED "\x1B[31m"
#define COLOR_GREEN "\x1B[32m"
#define COLOR_YELLOW "\x1B[33m"
#define COLOR_BLUE "\x1B[34m"
#define COLOR_MAGENTA "\x1B[35m"
#define COLOR_CYAN "\x1B[36m"
#define COLOR_WHITE "\x1B[37m"
#define COLOR_DEFAULT "\x1B[39m"
#else
#define COLOR_RESET " " // Reset to default colors
#define COLOR_CLEAR " " // Clear screen, reposition cursor to top left
#define COLOR_BLACK " "
#define COLOR_RED " "
#define COLOR_GREEN " "
#define COLOR_YELLOW " "
#define COLOR_BLUE " "
#define COLOR_MAGENTA " "
#define COLOR_CYAN " "
#define COLOR_WHITE " "
#define COLOR_DEFAULT " "
#endif

#define COLOR_RED_STR COLOR_RED "%s" COLOR_RESET
#define COLOR_GREEN_STR COLOR_GREEN "%s" COLOR_RESET
#define COLOR_GREEN_S2 COLOR_GREEN "%-10s" COLOR_RESET
#define COLOR_GREEN_X1 COLOR_GREEN "%01x" COLOR_RESET
#define COLOR_GREEN_STR_INT COLOR_GREEN "%s%i" COLOR_RESET
#define COLOR_YELLOW_STR COLOR_YELLOW "%s" COLOR_RESET
#define COLOR_YELLOW_STR COLOR_YELLOW "%s" COLOR_RESET
#define COLOR_MAGENTA_STR COLOR_MAGENTA "%s" COLOR_RESET
#define COLOR_YELLOW_PRIu64 COLOR_YELLOW "%5" PRIu64 "" COLOR_RESET
#define COLOR_YELLOW_PRIu64plus COLOR_YELLOW "%5" PRIu64 "" COLOR_RESET
#define COLOR_BRIGHT_BLACK "\x1B[90m"
#define COLOR_BRIGHT_RED "\x1B[91m"
#define COLOR_BRIGHT_GREEN "\x1B[92m"
#define COLOR_BRIGHT_YELLOW "\x1B[93m"
#define COLOR_BRIGHT_BLUE "\x1B[94m"
#define COLOR_BRIGHT_MAGENTA "\x1B[95m"
#define COLOR_BRIGHT_CYAN "\x1B[96m"
#define COLOR_BRIGHT_WHITE "\x1B[97m"

#define COLOR_BG_DEFAULT "\x1B[24;49m"
#define COLOR_BG_BLACK "\x1B[24;40m"
#define COLOR_BG_RED "\x1B[24;41m"
#define COLOR_BG_GREEN "\x1B[24;42m"
#define COLOR_BG_YELLOW "\x1B[24;43m"
#define COLOR_BG_BLUE "\x1B[24;44m"
#define COLOR_BG_MAGENTA "\x1B[24;45m"
#define COLOR_BG_CYAN "\x1B[24;46m"
#define COLOR_BG_WHITE "\x1B[24;47m"

#define COLOR_BG_BRIGHT_BLACK "\x1B[4;100m"
#define COLOR_BG_BRIGHT_RED "\x1B[4;101m"
#define COLOR_BG_BRIGHT_GREEN "\x1B[4;102m"
#define COLOR_BG_BRIGHT_YELLOW "\x1B[4;103m"
#define COLOR_BG_BRIGHT_BLUE "\x1B[4;104m"
#define COLOR_BG_BRIGHT_MAGENTA "\x1B[4;105m"
#define COLOR_BG_BRIGHT_CYAN "\x1B[4;106m"
#define COLOR_BG_BRIGHT_WHITE "\x1B[4;107m"
