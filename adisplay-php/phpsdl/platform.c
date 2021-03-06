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

/* $Id: c743e869ea4eee18c448ddb901e30e5d5d3520c3 $ */ 

/*
  +----------------------------------------------------------------------+
  | wrapper for SDL2/SDL_platform.h                                      |
  +----------------------------------------------------------------------+
*/

#include "php_sdl.h"
#include "platform.h"

ZEND_BEGIN_ARG_INFO_EX(arginfo_SDL_GetPlatform, 0, 0, 0)
ZEND_END_ARG_INFO()

/* {{{ proto string SDL_GetPlatform(void)

 *  \brief Gets the name of the platform.
 */
PHP_FUNCTION(SDL_GetPlatform)
{
	if (zend_parse_parameters_none() == FAILURE) {
		RETURN_FALSE;
	}

	RETURN_STRING(SDL_GetPlatform());
}

/* {{{ sdl_platform_functions[] */
zend_function_entry sdl_platform_functions[] = {
	ZEND_FE(SDL_GetPlatform,	arginfo_SDL_GetPlatform)
	ZEND_FE_END
};
/* }}} */

/* {{{ MINIT */
PHP_MINIT_FUNCTION(sdl_platform)
{
	return (zend_register_functions(NULL, sdl_platform_functions, NULL, MODULE_PERSISTENT TSRMLS_CC));
}
/* }}} */
