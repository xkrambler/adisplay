# Honda Accord 8th (Euro) / Acura TSX CU/CW Display Hacking

(c) 2019 Pablo Rodríguez Rey (mr.xkr - mr -at- xkr -dot- es)
These materials are licensed under the HACK license (read doc/HACK.txt) by Giacomo Tesio written on January 01, 2019.


## Getting Started

There are two protocols decoded in this work:

* Display (Radio) UART
	- UART TTL 0-5V
	- Baud rate: 19200 (standar 1N8)
	- PIN 1 RX data request from display to radio
	- PIN 2 TX data from radio to display

* Display (Climate) SPI
	- 0-12V SPI (real ~10,5V)
	- DISP CLK (Clock) y DISP SI (Data)
	- Speed aprox. 40microseg/cycle div (25kHz)
	- 3ms each message 12ms between messages
	- Messages are 10 bytes, starting with 0x80 and ending with 0x80 plus a XOR CRC (see code)


## Folder Map

	decode0/

		Photographs of the display while registering the log of the Radio protocol.

	decode1/

		Logic decoding of the packets with LogicAnalyzer, OpenBench LogicSniffer,
		pulseview, sigrok or the fabulous logic analyzer (don't remember if used
		all or some of them).

	decode2/

		First versions of Climate SPI decoding, using an PHP climaC1.php parser
		and some debugging, and datafiles.

	decode3/

		Seconds version of Climate SPI decoding.

	decode4/

		Final version of Climate SPI decoding (clima4.php) and examples
		(clima4.txt).

	doc/

		Files Accord8th_RX_notes.log and Accord8th_TX_notes.log contains
		the Radio decoding.

		Files Accord8th_RAW_RX1.log, Accord8th_RAW_RX2.log
		and Accord8th_RAW_TX1.log are the RAW data not parsed.

		There are several miscelanea files with the OEM connectors and
		the custom-made interfacing connectors.

		There are also some SPI decoding and screenshots for Climate.

	interface/

		All Arduino programs to test, debug and interface.
		Latest version is inside accordInterfaceNano4/

	display8th/

		Windows Visual Basic 6 debug application to use the interface
		for Radio (not Climate). You need to place msvbvm60.dll in the PATH
		and also RICHTX32.OCX and register it with administrative rights
		(regsvr32 RICHTX32.OCX).

	adisplaywin/

		Windows Visual Basic 6 interface applications only for climate.
		It registers a windows toolbar down to prevent windows applications
		stay over it. It's nice if you use a Carputer with Windows.

	adisplay/

		This is the best mantained version because you can run it on a RPI
		and get it running in less than 5 seconds from powerup replacing
		the init script with a basic script that gets udev up (needed for SDL2)
		and launch JSDL. So Javascript JSDL version meant to be runned on
		a Raspberry PI (2 or 3 works best). Maybe SDL 2.0 needs to be
		custom-compiled (with patches) to get working the PNG rendering
		(SDL 2.0 package is bad on the RPI and until today I don't know if its
		fixed). Also, yo need JSDL (JSDL is a lightweight C++11 OpenSource V8
			Engine powered JavaScript runner with integrated bindings -SDL 2,
			SDL Image 2, SDL TTF 2, Serial, File, System-). You can get it here:

			https://github.com/xkrambler/jsdl

			To compile it, just install V8 and SDL development libraries and write:

			# make

			And its done.

		Then, you can run this adisplay interface.

			To run in simulation:
				jsdl adisplay.js
			To check parameters:
				jsdl adisplay.js -h
					adisplay.js [options]
					   -d --device <device>  Set device
					   -f --fullscreen       Fullscreen
					   -h --help             Show this help
			To run with the interface on /dev/ttyUSB0 fullscreen:
				jsdl adisplay.js -d /dev/ttyUSB0 -f

		You get the idea on how it works.

	adisplay-c/

		OpenFrameworks C version of adisplay. It's a runinng proof-of-concept
		for Radio decoding only. You need to install OpenFrameworks and compile it.

	adisplay-php/

		PHP adisplay version. You need to install phpsdl module. Its on phpsdl/
		folder inside. Check the README.md file to compile and install it.

		Once installed, you can run it in simulation:
			php adisplay.php -simulate
		Or with the interface:
			php adisplay.php -port /dev/ttyUSB0
		Check options:
			php adisplay.php -h
				adisplay.php [ -h | -console | -debug | -port <port> | -simulate ]
				  -port <port>   Select serial port to connect
				  -console       Launch in console mode (only text)
				  -debug         Launch in debug mode
				  -simulate      Launch in simulated mode
				  -h             Show this help
