/*
  +----------------------------------------------------------------------+
  | PHP Version 5                                                        |
  +----------------------------------------------------------------------+
  | Copyright (c) 1997-2013 The PHP Group                                |
  +----------------------------------------------------------------------+
  | This source file is subject to version 3.01 of the PHP license,      |
  | that is bundled with this package in the file LICENSE, and is        |
  | available through the world-wide-web at the following url:           |
  | http://www.php.net/license/3_01.txt                                  |
  | If you did not receive a copy of the PHP license and are unable to   |
  | obtain it through the world-wide-web, please send a note to          |
  | license@php.net so we can mail you a copy immediately.               |
  +----------------------------------------------------------------------+
  | Authors: Santiago Lizardo <santiagolizardo@php.net>                  |
  |          Remi Collet <remi@php.net>                                  |
  +----------------------------------------------------------------------+
*/

/* $Id: ee44d9947250b146b4abb0736a8de29e75e3a1b5 $ */ 

#ifndef PHP_SDL_RWOPS_H
#define PHP_SDL_RWOPS_H

#ifdef  __cplusplus
extern "C" {
#endif

zend_class_entry *get_php_sdl_rwops_ce(void);
zend_bool  sdl_rwops_to_zval(SDL_RWops *rwops, zval *z_val, Uint32 flags, char *buf TSRMLS_DC);
SDL_RWops *zval_to_sdl_rwops(zval *z_val TSRMLS_DC);
void php_stream_to_zval_rwops(php_stream *stream, zval *return_value, int autoclose TSRMLS_DC);

PHP_MINIT_FUNCTION(sdl_rwops);

#ifdef  __cplusplus
} // extern "C" 
#endif

#endif /* PHP_SDL_RWOPS_H */

