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

/* $Id: 3143402269a5f7f3bf7b1f1971a9106fcdd55fc2 $ */

#ifndef PHP_SDL_SHAPE_H
#define PHP_SDL_SHAPE_H

/* not included in default SDL.h */
#include <SDL_shape.h>

#ifdef  __cplusplus
extern "C" {
#endif

zend_class_entry *get_php_sdl_windowshapemode_ce(void);
zend_bool sdl_windowshapemode_to_zval(SDL_WindowShapeMode *mode, zval *z_val TSRMLS_DC);
SDL_WindowShapeMode *zval_to_sdl_windowshapemode(zval *z_val TSRMLS_DC);


PHP_MINIT_FUNCTION(sdl_shape);

#ifdef  __cplusplus
} // extern "C"
#endif

#endif /* PHP_SDL_SHAPE_H */

