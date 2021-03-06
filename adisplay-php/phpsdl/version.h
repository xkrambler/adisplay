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

/* $Id: 612001d1a95ff8737fa7b3d3a3f54da40c5f3dfa $ */ 

#ifndef PHP_SDL_VERSION_H
#define PHP_SDL_VERSION_H

#ifdef  __cplusplus
extern "C" {
#endif

zend_bool convert_sdl_version_to_php_array(SDL_version *version, zval *version_array);

PHP_MINIT_FUNCTION(sdl_version);

#ifdef  __cplusplus
} // extern "C" 
#endif

#endif /* PHP_SDL_VERSION_H */

