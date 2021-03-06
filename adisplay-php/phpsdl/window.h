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

/* $Id: 713e77d788228402ec883d3ccc11c361f26f6fda $ */ 

#ifndef PHP_SDL_WINDOW_H
#define PHP_SDL_WINDOW_H

#ifdef  __cplusplus
extern "C" {
#endif

zend_class_entry *get_php_sdl_window_ce(void);
zend_bool sdl_window_to_zval(SDL_Window *window, zval *z_val TSRMLS_DC);
SDL_Window *zval_to_sdl_window(zval *z_val TSRMLS_DC);

PHP_MINIT_FUNCTION(sdl_window);

#ifdef  __cplusplus
} // extern "C" 
#endif

#endif /* PHP_SDL_WINDOW_H */

