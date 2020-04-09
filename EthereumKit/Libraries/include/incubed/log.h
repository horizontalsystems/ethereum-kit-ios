// @PUBLIC_HEADER
/**
 * Copyright (c) 2017 rxi
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the MIT license. See `log.c` for details.
 */

#ifndef LOG_H
#define LOG_H

#include "colors.h"
#include "utils.h"
#include <stdarg.h>
#include <stdio.h>
#define LOG_VERSION "0.1.0"

typedef void (*in3_log_LockFn)(void* udata, int lock);

typedef enum { LOG_TRACE,
               LOG_DEBUG,
               LOG_INFO,
               LOG_WARN,
               LOG_ERROR,
               LOG_FATAL } in3_log_level_t;

#if defined(DEBUG)
#define in3_log_trace(...) in3_log_(LOG_TRACE, __FILE__, __func__, __LINE__, __VA_ARGS__)
#define in3_log_debug(...) in3_log_(LOG_DEBUG, __FILE__, __func__, __LINE__, __VA_ARGS__)
#define in3_log_info(...) in3_log_(LOG_INFO, __FILE__, __func__, __LINE__, __VA_ARGS__)
#define in3_log_warn(...) in3_log_(LOG_WARN, __FILE__, __func__, __LINE__, __VA_ARGS__)
#define in3_log_error(...) in3_log_(LOG_ERROR, __FILE__, __func__, __LINE__, __VA_ARGS__)
#define in3_log_fatal(...) in3_log_(LOG_FATAL, __FILE__, __func__, __LINE__, __VA_ARGS__)
#define in3_log_level_is(level) ((level) == in3_log_get_level_())
#define in3_log_set_udata(udata) in3_log_set_udata_(udata)
#define in3_log_set_lock(fn) in3_log_set_lock_(fn)
#define in3_log_set_fp(fp) in3_log_set_fp_(fp)
#define in3_log_set_level(level) in3_log_set_level_(level)
#define in3_log_get_level() in3_log_get_level_()
#define in3_log_set_quiet(enable) in3_log_set_quiet_(enable)
#define in3_log_set_prefix(prefix) in3_log_set_prefix_(prefix)
#define in3_log_enable_prefix() in3_log_enable_prefix_()
#define in3_log_disable_prefix() in3_log_disable_prefix_()
#define in3_log(...) in3_log_(__VA_ARGS__)
#else
#define in3_log_trace(...)
#define in3_log_debug(...)
#define in3_log_info(...)
#define in3_log_warn(...)
#define in3_log_error(...)
#define in3_log_fatal(...)
#define in3_log_level_is(level)
#define in3_log_set_udata(udata)
#define in3_log_set_lock(fn)
#define in3_log_set_fp(fp)
#define in3_log_set_level(level)
#define in3_log_get_level()
#define in3_log_set_quiet(enable)
#define in3_log_set_prefix(prefix)
#define in3_log_enable_prefix()
#define in3_log_disable_prefix()
#define in3_log(level, file, function, line, ...) \
  do {                                            \
    (void) (level);                               \
    (void) (file);                                \
    (void) (function);                            \
    (void) (line);                                \
  } while (0)
#endif

/**
 * in3_log_set_*() functions are not thread-safe. 
 * It is expected that these initialization functions will be called from the main thread before 
 * spawning more threads.
 */
void            in3_log_set_udata_(void* udata);
void            in3_log_set_lock_(in3_log_LockFn fn);
void            in3_log_set_fp_(FILE* fp);
void            in3_log_set_level_(in3_log_level_t level);
in3_log_level_t in3_log_get_level_();
void            in3_log_set_quiet_(int enable);
void            in3_log_set_prefix_(const char* prefix);
void            in3_log_enable_prefix_();
void            in3_log_disable_prefix_();

/* in3_log() function can be made thread-safe using the in3_log_set_lock() function */
void in3_log_(in3_log_level_t level, const char* file, const char* function, int line, const char* fmt, ...);

#endif
