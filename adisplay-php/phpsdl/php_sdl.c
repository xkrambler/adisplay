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

/* $Id: ad433bacdb3a41dd528f0e28b85f34b4b1e84830 $ */

#include "php_sdl.h"
#include "blendmode.h"
#include "cpuinfo.h"
#include "error.h"
#include "event.h"
#include "filesystem.h"
#include "glcontext.h"
#include "keyboard.h"
#include "messagebox.h"
#include "mouse.h"
#include "mutex.h"
#include "platform.h"
#include "power.h"
#include "pixels.h"
#include "rect.h"
#include "render.h"
#include "rwops.h"
#include "sdl.h"
#include "shape.h"
#include "surface.h"
#include "timer.h"
#include "version.h"
#include "video.h"
#include "window.h"

#ifdef COMPILE_DL_SDL
ZEND_GET_MODULE(sdl)
#endif

/* {{{ php_sdl_check_overflow */
zend_bool php_sdl_check_overflow(int a, int b, int silent)
{
	TSRMLS_FETCH();

	if(a <= 0 || b <= 0) {
		if (!silent) {
			php_error_docref(NULL TSRMLS_CC, E_WARNING, "one parameter to a memory allocation multiplication is negative or zero, failing operation gracefully");
		}
		return 1;
	}
	if(a > INT_MAX / b) {
		if (!silent) {
			php_error_docref(NULL TSRMLS_CC, E_WARNING, "product of memory allocation multiplication would exceed INT_MAX, failing operation gracefully");
		}
		return 1;
	}
	return 0;
}
/* }}} */


#define PHP_MINIT_CALL(func) PHP_MINIT(func)(INIT_FUNC_ARGS_PASSTHRU)

/* {{{ PHP_MINIT_FUNCTION */
PHP_MINIT_FUNCTION(sdl)
{
	if (   SUCCESS == PHP_MINIT_CALL(sdl_blendmode)
		&& SUCCESS == PHP_MINIT_CALL(sdl_cpuinfo)
		&& SUCCESS == PHP_MINIT_CALL(sdl_error)
		&& SUCCESS == PHP_MINIT_CALL(sdl_event)
		&& SUCCESS == PHP_MINIT_CALL(sdl_glcontext)
		&& SUCCESS == PHP_MINIT_CALL(sdl_keyboard)
		&& SUCCESS == PHP_MINIT_CALL(sdl_messagebox)
		&& SUCCESS == PHP_MINIT_CALL(sdl_mouse)
		&& SUCCESS == PHP_MINIT_CALL(sdl_mutex)
		&& SUCCESS == PHP_MINIT_CALL(sdl_platform)
		&& SUCCESS == PHP_MINIT_CALL(sdl_power)
		&& SUCCESS == PHP_MINIT_CALL(sdl_filesystem)
		&& SUCCESS == PHP_MINIT_CALL(sdl_pixels)
		&& SUCCESS == PHP_MINIT_CALL(sdl_rect)
		&& SUCCESS == PHP_MINIT_CALL(sdl_render)
		&& SUCCESS == PHP_MINIT_CALL(sdl_rwops)
		&& SUCCESS == PHP_MINIT_CALL(sdl_sdl)
		&& SUCCESS == PHP_MINIT_CALL(sdl_shape)
		&& SUCCESS == PHP_MINIT_CALL(sdl_surface)
		&& SUCCESS == PHP_MINIT_CALL(sdl_timer)
		&& SUCCESS == PHP_MINIT_CALL(sdl_version)
		&& SUCCESS == PHP_MINIT_CALL(sdl_video)
		&& SUCCESS == PHP_MINIT_CALL(sdl_window)
		) {
		return SUCCESS;
	}
	return FAILURE;
}
/* }}} */


/* {{{ PHP_MSHUTDOWN_FUNCTION */
PHP_MSHUTDOWN_FUNCTION(sdl)
{
	return SUCCESS;
}
/* }}} */


/* {{{ PHP_MINFO_FUNCTION */
PHP_MINFO_FUNCTION(sdl)
{
	SDL_version ver;
	char buf[64];

	php_info_print_table_start();
	php_info_print_table_header(2, "SDL support", "enabled");

	php_info_print_table_row(2, "SDL module version", PHP_SDL_VERSION);

	/* buildtime headers version */
	SDL_VERSION(&ver);
	snprintf(buf, sizeof(buf), "%d.%d.%d", ver.major, ver.minor, ver.patch);
	php_info_print_table_row(2, "SDL2 headers version", buf);

	/* runtime library version */
	SDL_GetVersion(&ver);
	snprintf(buf, sizeof(buf), "%d.%d.%d", ver.major, ver.minor, ver.patch);
	php_info_print_table_row(2, "SDL2 library version", buf);

	php_info_print_table_end();
}
/* }}} */


/* {{{ sdl_module_entry
 */
zend_module_entry sdl_module_entry = {
	STANDARD_MODULE_HEADER,
	"SDL",
	NULL,
	PHP_MINIT(sdl),     /* Replace with NULL if there is nothing to do at php startup   */
	PHP_MSHUTDOWN(sdl), /* Replace with NULL if there is nothing to do at php shutdown  */
	NULL, /* RINIT */
	NULL, /* RSHUTDOWN */
	PHP_MINFO(sdl),
	PHP_SDL_VERSION,
	STANDARD_MODULE_PROPERTIES
};
/* }}} */

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
