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

/* $Id: 938444594ba5852c09ab1558873d9cfbd3406900 $ */ 

#ifndef PHP_SDL_PIXELS_H
#define PHP_SDL_PIXELS_H

#ifdef  __cplusplus
extern "C" {
#endif

/* PHP specific struct to manage memory access */
typedef struct SDL_Pixels
{
    int    h;
    int    pitch;
    Uint8 *pixels;
} SDL_Pixels;


zend_class_entry *get_php_sdl_color_ce(void);
zend_bool sdl_color_to_zval(SDL_Color *color, zval *value TSRMLS_DC);
zend_bool zval_to_sdl_color(zval *value, SDL_Color *color TSRMLS_DC);

zend_class_entry *get_php_sdl_pixelformat_ce(void);
zend_bool sdl_pixelformat_to_zval(SDL_PixelFormat *format, zval *z_val, Uint32 flags TSRMLS_DC);
SDL_PixelFormat *zval_to_sdl_pixelformat(zval *z_val TSRMLS_DC);

zend_class_entry *get_php_sdl_palette_ce(void);
zend_bool sdl_palette_to_zval(SDL_Palette *palette, zval *z_val, Uint32 flags TSRMLS_DC);
SDL_Palette *zval_to_sdl_palette(zval *z_val TSRMLS_DC);

zend_class_entry *get_php_sdl_pixels_ce(void);
zend_bool sdl_pixels_to_zval(SDL_Pixels *pixels, zval *z_val, Uint32 flags TSRMLS_DC);
SDL_Pixels *zval_to_sdl_pixels(zval *z_val TSRMLS_DC);


PHP_MINIT_FUNCTION(sdl_pixels);

#ifdef  __cplusplus
} // extern "C" 
#endif

#endif /* PHP_SDL_PIXELS_H */

