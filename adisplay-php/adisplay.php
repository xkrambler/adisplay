<?php

	if (!extension_loaded('sdl')) dl('sdl.'.PHP_SHLIB_SUFFIX);

	error_reporting(E_ALL & ~E_NOTICE);

	define("DATA_PATH", "data/");

	// clase de acceso al puerto serie
	class AccordSerial {

		protected $o;
		protected $h;

		// constructor y parámetros
		function __construct($o) {
			$this->o=$o;
		}

		// abrir puerto
		function open() {
			passthru("stty -F ".$this->o["dev"]." ".$this->o["bauds"]." cs".$this->o["bits"]." -cstopb -parenb ignbrk -brkint -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts");
			if (!$this->h=fopen($this->o["dev"], "rw+b")) return false;
			stream_set_blocking($this->h, false);
			return true;
		}

		// leer del puerto
		function read() {
			if (feof($this->h)) return false;
			return fread($this->h, 1024);
		}

		// escribir datos
		function write($d) {
			if (feof($this->h)) return false;
			return fwrite($this->h, $d);
		}

		// cerrar puerto
		function close() {
			fclose($this->h);
		}

	}

	// class to deal with Accord Display Interface
	class AccordDisplayInterface {

		protected $o;
		protected $serial=null;
		protected $buffer;
		protected $uart;
		protected $data;

		// constructor
		public function __construct($o=Array()) {
			$this->o=$o;
			$this->clean();
		}

		// destructor
		public function __destruct() {
			$this->close();
		}

		// get current port
		public function getPort() {
			return $this->o["port"];
		}

		// cleanup
		public function clean() {
			$this->buffer="";
			$this->uart="";
			$this->data=Array();
		}

		// connect to USB Accord Interface
		public function connect() {
			if (!$this->o["port"]) return false;
			$this->clean();
			$this->serial=new AccordSerial(Array(
				"dev"=>$this->getPort(),
				"bauds"=>115200,
				"parity"=>"none",
				"bits"=>8,
				"stop"=>1,
			));
			if (!$this->serial->open()) return false;
			sleep(1); // por algún motivo del universo no puedo comenzar a leer antes de 1sg con los ttyACM
			return true;
		}

		// reconnect
		public function reconnect() {
			$this->close();
			return $this->connect();
		}

		// close connection
		public function close() {
			if ($this->serial) $this->serial->close();
		}

		// setup
		public function setup() {
			//$this->send("+a+d+u+s");
			$this->send("-a-d-u+s");
			return true;
		}

		// send data to the interface
		public function send($data) {
			$this->serial->write($data);
		}

		// read data from the interface
		public function read() {
			$read=$this->serial->read();
			if ($read===false) return false;
			$this->buffer.=$read;
			if ($nl=strpos($this->buffer, "\n")) {
				$data=substr($this->buffer, 0, $nl);
				$this->buffer=substr($this->buffer, $nl+1);
				if ($p=strpos($data," ")) {
					$cmd=substr($data, 0, $p);
					$data=substr($data, $p+1);
				} else {
					$cmd=$data;
					$data="";
				}
				if ($this->o["debug"]) echo "CMD[".$cmd."] DATA[".$data."]\n";
				switch ($cmd) {
				case "ANALOG": return Array($cmd, explode(" ",$data));
				case "DIGITAL": return Array($cmd, explode(" ",$data));
				case "OK":
				case "PONG":
				case "SPI":
				default:
					return Array($cmd, $data);
				}
			}
			return Array("","");
		}

		// add data to UART buffer
		public function uartAdd($data) {
			$this->uart.=$data;
		}

		// return value from BCD
		public function bcdValue($bcd) {
			return intval(str_replace("f"," ",bin2hex($bcd)));
		}

		// get data
		public function dataGet() {
			return $this->data;
		}

		// save decoded data
		public function dataSave($id, $d) {
			if (!$this->data[$id]) $this->data[$id]=Array();
			$this->data[$id]=array_merge($this->data[$id], $d);
		}

		// packet dump for debug
		public function dataDump($p) {
			$s="";
			for ($i=0;$i<strlen($p);$i++)
				$s.=($i?" ":"").strtoupper(bin2hex($p[$i]));
			return $s;
		}

/*
		// climatizer packet decode (SPI-bus decode)
		public function climaPacketDecode($p) {
			//if ($this->o["debug"]) echo "SPI ".$this->dataDump($p)."\n";
			echo "SPI ".$this->dataDump($p)."\n";
			$a=Array();
			$a["time"]=microtime(true);
			$a["off"]="";
			if (ord($p[1])==0x80) $a["off"]=true;
			$a["t1"]="";
			if (ord($p[3])==0x9B) $a["t1"]=22;
			if (ord($p[3])==0x8F) $a["t1"]=23;
			if (ord($p[3])==0xE6) $a["t1"]=24;
			if (ord($p[3])==0xAD) $a["t1"]=25;
			if (ord($p[3])==0xFD) $a["t1"]=26;
			if (ord($p[3])==0xC7) $a["t1"]=27;
			if (ord($p[3])==0xBF) $a["t1"]=28;
			if (ord($p[3])==0xD0) $a["t1"]=99;
			$a["t2"]="";
			if (ord($p[1])==0x5B) $a["t2"]=22;
			if (ord($p[1])==0x4F) $a["t2"]=23;
			if (ord($p[1])==0x26) $a["t2"]=24;
			if (ord($p[1])==0x6D) $a["t2"]=25;
			if (ord($p[1])==0x3D) $a["t2"]=26;
			if (ord($p[1])==0x07) $a["t2"]=27;
			if (ord($p[1])==0x7F) $a["t2"]=28;
			if (ord($p[1])==0x10) $a["t2"]=99;
			$a["fan"]=0;
			if (ord($p[6])==0xE0) $a["fan"]=1;
			if (ord($p[6])==0xD0) $a["fan"]=2;
			if (ord($p[6])==0xB0) $a["fan"]=3;
			if (ord($p[6])==0xC8) $a["fan"]=4;
			if (ord($p[6])==0xA8) $a["fan"]=5;
			if (ord($p[6])==0x98) $a["fan"]=6;
			if (ord($p[6])==0xF8) $a["fan"]=7;
			$a["ac_on"]=false;
			$a["ac_off"]=false;
			$a["auto"]=false;
			if ((ord($p[6]) & 0x0F) == 0x05) $a["ac_on"]=true;
			if ((ord($p[6]) & 0x0F) == 0x06) $a["ac_off"]=true;
			if ((ord($p[6]) & 0x0F) == 0x00) $a["auto"]=true;
			$a["mode"]="";
			if (ord($p[7])==0xF8) $a["mode"]="feet_defrost";
			if (ord($p[7])==0xB0) $a["mode"]="feet";
			if (ord($p[7])==0xF4) $a["mode"]="feet_front";
			if (ord($p[7])==0xA4) $a["mode"]="front";
			$this->dataSave("clima",$a);
			print_r($a); 
		}
*/

		// climatizer packet decode (SPI-bus decode)
		public function climaPacketDecode($p) {
			//if ($this->o["debug"]) echo "SPI ".$this->dataDump($p)."\n";
			$a=false;
			if (ord($p[8])==0x80) {
				$a=Array();
				$a["time"]=microtime(true);
				$a["t1"]="";
				if (ord($p[3])==0xDC) $a["t1"]="LO";
				if (ord($p[3])==0xEF) $a["t1"]=19;
				if (ord($p[3])==0x86) $a["t1"]=21;
				if (ord($p[3])==0x9B) $a["t1"]=22;
				if (ord($p[3])==0x8F) $a["t1"]=23;
				if (ord($p[3])==0xE6) $a["t1"]=24;
				if (ord($p[3])==0xAD) $a["t1"]=25;
				if (ord($p[3])==0xFD) $a["t1"]=(ord($p[5]) & 0x4?26:16);
				if (ord($p[3])==0xC7) $a["t1"]=(ord($p[5]) & 0x4?27:17);
				if (ord($p[3])==0xBF) $a["t1"]=(ord($p[5]) & 0x4?(ord($p[5]) & 0x08?28:20):18);
				if (ord($p[3])==0xD0) $a["t1"]="HI";
				$a["t2"]="";
				if (ord($p[1])==0x1C) $a["t2"]="LO";
				if (ord($p[1])==0x2F) $a["t2"]=19;
				if (ord($p[1])==0x46) $a["t2"]=21;
				if (ord($p[1])==0x5B) $a["t2"]=22;
				if (ord($p[1])==0x4F) $a["t2"]=23;
				if (ord($p[1])==0x26) $a["t2"]=24;
				if (ord($p[1])==0x6D) $a["t2"]=25;
				if (ord($p[1])==0x3D) $a["t2"]=(ord($p[5]) & 0x10?26:16);
				if (ord($p[1])==0x07) $a["t2"]=(ord($p[5]) & 0x10?27:17);
				if (ord($p[1])==0x7F) $a["t2"]=(ord($p[5]) & 0x10?(ord($p[5]) & 0x20?28:20):18);
				if (ord($p[1])==0x10) $a["t2"]="HI";
				$a["fan"]=0;
				if ((ord($p[6]) & 0xF0) == 0xE0) $a["fan"]=1;
				if ((ord($p[6]) & 0xF0) == 0xD0) $a["fan"]=2;
				if ((ord($p[6]) & 0xF0) == 0xB0) $a["fan"]=3;
				if ((ord($p[6]) & 0xF0) == 0xC0) $a["fan"]=4;
				if ((ord($p[6]) & 0xF0) == 0xA0) $a["fan"]=5;
				if ((ord($p[6]) & 0xF0) == 0x90) $a["fan"]=6;
				if ((ord($p[6]) & 0xF0) == 0xF0) $a["fan"]=7;
				$a["acon"]=((ord($p[6]) & 0x0F) == 0x05);
				$a["acoff"]=((ord($p[6]) & 0x0F) == 0x06);
				$a["auto"]=((ord($p[6]) & 0x0F) == 0x00);
				$a["mode"]="";
				if (ord($p[7])==0xF8) $a["mode"]="FEET+DEFROST";
				if (ord($p[7])==0xB0) $a["mode"]="FEET";
				if (ord($p[7])==0xF4) $a["mode"]="FEET+FRONT";
				if (ord($p[7])==0xA4) $a["mode"]="FRONT";
			}
			$this->dataSave("clima", $a);
		}

	}


	// main Application
	class Application {

		protected $o;
		public $interface;
		
		// init
		function __construct($o) {
			$this->o=$o;
			$this->interface=new AccordDisplayInterface(Array(
				"port"=>$this->o["port"],
				"debug"=>$this->o["debug"],
			));
			if (!$this->o["simulate"]) {
				$this->o["connected"]=$this->interface->connect();
				if (!$this->o["connected"]) die("Cant connect ".$this->interface->getPort()."\n");
			}
		}

		// main loop
		function process() {
			if ($this->o["simulate"]) {
				// simulate SPI packets
				$_spi=array(
					"80 5B 1B 9B 9B BF 80 C2 80 FD",
					"80 46 1B 86 9B 97 80 C2 80 D5",
					"80 7F 1B BF 9B 97 80 C2 80 D5",
					"80 2F 06 EF 86 AB 80 C2 80 E9",
					"80 7F 06 BF 86 AB 80 C2 80 E9",
					"80 07 06 C7 86 83 80 C2 80 C1",
					"80 3D 06 FD 86 AB 80 C2 80 E9",
					"80 1C 78 DC F8 AB 80 C2 80 E9",
					"80 3D 06 DC F8 AB 80 C2 80 B6",
					"80 07 06 DC F8 CB 80 C2 80 EC",
					"80 7F 06 DC F8 AB 80 C2 80 F4",
					"80 2F 06 DC F8 AB 80 C2 80 A4",
					"80 7F 1B DC F8 9B 80 C2 80 D9",
					"80 46 1B DC F8 9B 80 C2 80 E0",
					"80 5B 1B DC F8 FB 80 C2 80 9D",
					"80 4F 1B DC F8 FB 80 C2 80 89",
					"80 26 1B DC F8 FB 80 C2 80 E0",
					"80 6D 1B DC F8 FB 80 C2 80 AB",
					"80 3D 1B DC F8 FB 80 C2 80 FB",
					"80 07 1B DC F8 9B 80 C2 80 A1",
					"80 7F 1B DC F8 FB 80 C2 80 B9",
					"80 26 1B 9B 9B BF 80 C2 80 80",
					"80 5B 1B E6 9B BF 80 C2 80 80",
					"80 5B 1B E6 9B BF 86 80 80 C4",
					"80 26 1B 9B 9B BF 86 80 80 C4",
					"80 5B 1B 9B 9B BF E6 80 80 D9",
					"80 5B 1B 9B 9B BF D6 80 80 E9",
					"80 5B 1B 9B 9B BF B6 80 80 89",
					"80 5B 1B 9B 9B BF CE 80 80 F1",
					"80 5B 1B 9B 9B BF AE 80 80 91",
					"80 5B 1B 9B 9B BF 9E 80 80 A1",
					"80 5B 1B 9B 9B BF FE 80 80 C1",
					"80 4F 1B 86 9B F7 B6 80 80 C8",
					"80 4F 1B 86 9B F7 B5 80 80 CB",
					"80 2F 06 BF 9B A7 B5 80 80 DF",
					"80 2F 06 BF 86 AB B5 80 80 CE",
					"80 2F 06 BF 9B EF B5 80 80 97",
					"80 5B 1B 9B 9B BF 80 B0 80 8F",
					"80 5B 1B 9B 9B BF 80 F8 80 C7",
					"80 5B 1B 9B 9B BF 80 F4 80 CB",
					"80 5B 1B 9B 9B BF 80 A4 80 9B",
					"80 1C 78 DC F8 AB 86 80 80 AD",
					"80 3D 06 FD 86 AB 86 80 80 AD",
					"80 07 06 C7 86 83 86 80 80 85",
					"80 7F 06 BF 86 AB 86 80 80 AD",
					"80 2F 06 EF 86 AB 86 80 80 AD",
					"80 7F 1B BF 9B 97 86 80 80 91",
					"80 46 1B 86 9B 97 86 80 80 91",
					"80 5B 1B 9B 9B BF 86 80 80 B9",
					"80 4F 1B 8F 9B BF 86 80 80 B9",
					"80 26 1B E6 9B BF 86 80 80 B9",
					"80 6D 1B AD 9B BF 86 80 80 B9",
					"80 3D 1B FD 9B BF 86 80 80 B9",
					"80 07 1B C7 9B 97 86 80 80 91",
					"80 7F 1B BF 9B BF 86 80 80 B9",
					"80 10 36 D0 B6 97 86 80 80 91",
				);
				$p=hex2bin(str_replace(" ","",$_spi[time()%count($_spi)]));
				$this->interface->climaPacketDecode($p);
			} else {
				while (true) {
					$data=$this->interface->read();
					if ($data===false) return false;
					list($c, $p)=$data;
					if ($c) $ping=false; else break;
					switch ($c) {
					case "OK": $this->interface->setup(); break;
					case "PONG": break;
					case "SPI":
						$p=hex2bin(str_replace(" ","",$p));
						$this->interface->climaPacketDecode($p);
						break;
					case "ANALOG":
						if ($this->o["debug"]) {
							echo $c;
							foreach ($p as $i=>$v)
								echo " ".$v." ";
							echo "\n";
						}
						break;
					case "DIGITAL":
						if ($this->o["debug"]) {
							echo $c;
							foreach ($p as $i=>$v)
								echo " ".($v?"1":"0");
							echo "\n";
						}
						break;
					default:
						echo "Unknown cmd[".$c."] data[".$p."]\n";
					}
				}
				/*if ($ping) {
					if ((microtime(true)-$ping)>3) {
						echo "Reconnecting...\n";
						$ping=microtime(true);
						$connected=$this->interface->reconnect();
					}
				} else {
					$this->interface->send("p");
					$ping=microtime(true);
				}*/
			}
			return true;
		}

	}

	// command line parameters
	$debug=false;
	$console=false;
	$simulate=false;
	$windowed=false;
	$port="/dev/ttyUSB0";
	for ($c=1;$p=$argv[$c];$c++) {
		switch ($p) {
		case "-debug": $debug=true; break;
		case "-port": $port=$argv[++$c]; break;
		case "-console": $console=true; break;
		case "-simulate": $simulate=true; break;
		case "-windowed": $windowed=true; break;
		case "-h":
			echo $argv[0]." [ -h | -console | -debug | -port <port> | -simulate ]\n";
			echo "  -port <port>   Select serial port to connect\n";
			echo "  -console       Launch in console mode (only text)\n";
			echo "  -debug         Launch in debug mode\n";
			echo "  -simulate      Launch in simulated mode\n";
			echo "  -h             Show this help\n";
			return;
		default:
			echo "Parameter ".$p." unknown, type ".$argv[0]." -h for sintax.\n";
			return;
		}
	}

	// create main application
	$app=new Application(Array(
		"port"=>$port,
		"debug"=>$debug,
		"simulate"=>$simulate,
	));

	// console mode
	if ($console) {
		echo "Console mode started, Ctrl+C to end.\n";
		while (true) {
			if (!$app->process() && !$simulate)
				$app->interface->reconnect();
			usleep(20000);
		}
	}

	// clase de manejo de gráficos
	class GDI {

		const TALIGN_TL=0;
		const TALIGN_TC=1;
		const TALIGN_TR=2;
		const TALIGN_ML=3;
		const TALIGN_MC=4;
		const TALIGN_MR=5;
		const TALIGN_BL=6;
		const TALIGN_BC=7;
		const TALIGN_BR=8;

		protected $o;
		protected $screen;
		protected $display;

		function __construct($o) {
			$this->screen=$o["screen"];
			$this->o=$o;
			if ($o["init"]) $this->init();
		}

		// inicializar gráficos
		function init() {
			@dl('sdl.so') or @dl('phpsdl.so');
			SDL_Init(SDL_INIT_VIDEO); //SDL_Init(SDL_INIT_EVERYTHING);
			register_shutdown_function("sdl_quit");
			sdlttf_Init();
			$this->o["flags"]=($this->o["windowed"]
				?SDL_SWSURFACE+SDL_SRCALPHA
				:SDL_SWSURFACE+SDL_SRCALPHA+SDL_NOFRAME+SDL_FULLSCREEN // +SDL_SRCALPHA+SDL_DOUBLEBUF; // +SDL_NOFRAME+SDL_FULLSCREEN
			);
			$this->screen=SDL_SetVideoMode($this->w(), $this->h(), 32, $this->o["flags"]);
			SDL_ShowCursor(0);
			if (false) {
				$Rmask=0x000000ff;
				$Gmask=0x0000ff00;
				$Bmask=0x00ff0000;
				$Amask=0xff000000;
				$this->display2=SDL_CreateRGBSurface(SDL_SWSURFACE | SDL_SRCALPHA, $this->w(), $this->h(), 32, $Rmask, $Gmask, $Bmask, $Amask);
				//SDL_SetAlpha($this->display, SDL_SRCALPHA, 125);
				$this->display=SDL_DisplayFormatAlpha($this->display2);
			} else {
				$this->display=$this->screen;
			}
			$this->color=Array(255,255,255);
			SDL_WM_SetCaption($this->o["title"], ($this->o["icon"]?$this->o["icon"]:""));
		}

		// limpiar pantalla
		function clear() {
			//SDL_LockSurface($this->display);
			SDL_FillRect($this->display, $this->display["clip_rect"], 0);
		}

		// color primario
		function color($color) {
			$this->color=$color;
		}

		// alineación
		function align($r, $align) {
			switch ($align) {
			case self::TALIGN_TL: break;
			case self::TALIGN_TC: $r["x"]-=($r["w"]>>1); break;
			case self::TALIGN_TR: $r["x"]-=$r["w"]; break;
			case self::TALIGN_ML: $r["y"]-=($r["h"]>>1); break;
			case self::TALIGN_MC: $r["y"]-=($r["h"]>>1); $r["x"]-=($r["w"]>>1); break;
			case self::TALIGN_MR: $r["y"]-=($r["h"]>>1); $r["x"]-=$r["w"]; break;
			case self::TALIGN_BL: $r["y"]-=$r["h"]; break;
			case self::TALIGN_BC: $r["y"]-=$r["h"]; $r["x"]-=($r["w"]>>1); break;
			case self::TALIGN_BR: $r["y"]-=$r["h"]; $r["x"]-=$r["w"]; break;
			}
			return $r;
		}

		// cargar imagen
		function load($file) {
			$img=IMG_Load($file);
			/*$r=$img["clip_rect"];
			$Rmask = 0x000000ff;
			$Gmask = 0x0000ff00;
			$Bmask = 0x00ff0000;
			$Amask = 0xff000000;
				$surface=SDL_CreateRGBSurface(SDL_SRCALPHA, $r["w"], $r["h"], 32, $Rmask, $Gmask, $Bmask, $Amask);
				SDL_SetAlpha($img, SDL_SRCALPHA, 255);
				SDL_SetAlpha($surface, SDL_SRCALPHA, 255);
				SDL_BlitSurface($img, $r, $surface, $r);
			return $surface;*/
			return $img;
			//$surface=SDL_DisplayFormatAlpha($img);
			//sdl_freesurface($img);
			//return $surface;
		}

		// dibujar imagen
		function draw($img, $x=0, $y=0, $align=self::TALIGN_TL, $alpha=false) {
			if (!$img) return false;
			$r=array("x"=>$x, "y"=>$y) + $img["clip_rect"];
			$r=$this->align($r, $align);
			//SDL_SetAlpha($this->screen, SDL_SRCALPHA, 128);
			$alpha=false;
			if ($alpha!==false) {
				echo "alpha".$alpha."___".SDL_SRCALPHA."\n";
				$img2=SDL_DisplayFormatAlpha($img);
				//SDL_FreeSurface($img);
				SDL_SetAlpha($img2, SDL_SRCALPHA | SDL_RLEACCEL, $alpha);
				SDL_BlitSurface($img2, null, $this->display, $r);
				/*$r["x"]+=50;
				$r["y"]+=30;
				SDL_BlitSurface($img, null, $this->display, $r);*/
				//SDL_BlitSurface($img, null, $this->display, $r);
			} else {
				SDL_BlitSurface($img, null, $this->display, $r);
			}
			//$c=SDL_MapRGBA($f,255,255,0,128);
			//SDL_FillRect($img,$r,$c);
			//SDL_BlitSurface($img, null, $this->screen, $r);
		}

		// escribir texto
		function text($font, $text, $x, $y, $align=self::TALIGN_TL) {
			$img=sdlttf_RenderUTF8_Blended($font, $text, $this->color[0], $this->color[1], $this->color[2]);
			if ($img) {
				$this->draw($img, $x, $y, $align);
				sdl_freesurface($img);
			}
		}

		// actualizar display
		function update(){
			//SDL_UnLockSurface($this->display);
			if ($this->display!=$this->screen)
				SDL_BlitSurface($this->display, null, $this->screen, null);
			SDL_UpdateRect($this->screen, 0, 0, 0, 0);
		}

		// obtener ancho
		function w() {
			return $this->o["w"];
		}

		// obtener alto
		function h() {
			return $this->o["h"];
		}

	}

	// inicializar gráficos
	$gdi=new GDI(Array(
		"title"=>"Accord 8th Display",
		"w"=>1280,
		"h"=>800,
		"init"=>true,
		"windowed"=>$windowed,
	));

	// carga de tipos de letra
	$font["console"]=sdlttf_OpenFont(DATA_PATH."Sansation_Light.ttf", 16);
	$font["sansationSMl"]=sdlttf_OpenFont(DATA_PATH."Sansation_Light.ttf", 32);
	$font["sansationSMb"]=sdlttf_OpenFont(DATA_PATH."Sansation_Bold.ttf", 32);
	$font["sansationMEDl"]=sdlttf_OpenFont(DATA_PATH."Sansation_Light.ttf", 48);
	$font["sansationMEDb"]=sdlttf_OpenFont(DATA_PATH."Sansation_Bold.ttf", 48);
	$font["sansationBIG"]=sdlttf_OpenFont(DATA_PATH."Sansation_Bold.ttf", 120);
	$font["LCDSM"]=sdlttf_OpenFont(DATA_PATH."LCD.ttf", 54);
	$font["digitsLCD"]=sdlttf_OpenFont(DATA_PATH."LCD.ttf", 140);

	// carga de imágenes
	foreach ($imgs=Array(
		"bg.jpg",
		"clima_feet_defrost.png","clima_feet_front.png","clima_feet.png","clima_front.png",
	) as $f) {
		$p=strpos($f,".");
		if (!$img[substr($f,0,$p)]=$gdi->load(DATA_PATH.$f))
			die("ERROR: Loading Image ".$f);
	}

	// definición de colores
	$color["w"]=Array(255,255,255);
	$color["wg"]=Array(222,222,222);
	$color["g"]=Array(128,128,128);
	$color["tmax"]=Array(255,96,96);
	$color["tmin"]=Array(96,255,255);

	// main loop
	$running=true;
	while ($running) {

		// application main loop iteration
		$app->process();
		$data=$app->interface->dataGet();

		// some info
		$ticks=SDL_GetTicks();
		$seconds=round($ticks/1000);
		$w=$gdi->w();
		$h=$gdi->h();

		// renderizador de FPS
		$fps_frames++;
		if (!$fps_timer || $fps_time=(microtime(true)-$fps_timer)>=1) {
			if ($fps_timer) $fps=round($fps_frames/$fps_time)."fps";
			$fps_timer=microtime(true);
			$fps_frames=0;
		}

		// propiedades por defecto y fondo
		$gdi->clear();
		$gdi->color($color["w"]);
		$gdi->draw($img["bg"]);

		// DEBUG
		$gdi->color($color["g"]);
		$gdi->text($font["LCDSM"], str_pad($ticks, 4, "0", STR_PAD_LEFT)." ".$fps, $w-20, 10, GDI::TALIGN_TR);

		// reloj
		/*if ($clock=$data["clock"]["clock"]) {
			$gdi->color($color["w"]);
			$gdi->draw($img["clock"], 15, 24);
			$gdi->text($font["digitsLCD"], substr($clock,0,2), 195, 20, GDI::TALIGN_TR);
			$gdi->text($font["digitsLCD"], substr($clock,-2,2), 225, 20, GDI::TALIGN_TL);
			$gdi->color($color[($seconds%2?"w":"g")]);
			$gdi->text($font["digitsLCD"], ":", 210, 20, GDI::TALIGN_TC);
		}*/

		// Climatizer (solo si hay menos de 1 segundo entre tramas)
		if ($data["clima"] && (microtime(true) - $data["clima"]["time"]<1)) {

			// setup
			$temp_min=16;
			$temp_len=13;

			// manual: actual mode
			if ($mode=$data["clima"]["mode"]) {
				$gdi->draw($img["clima_".strtolower(str_replace("+","_",$mode))], 480, $h-50, GDI::TALIGN_MC);
			}

			// manual: fan speed
			if ($fan=$data["clima"]["fan"]) {
				$gdi->color($color["w"]);
				$gdi->text($font["sansationMEDb"], $fan, 600, $h-48, GDI::TALIGN_MR);
				$gdi->text($font["sansationMEDl"], " Manual", 600, $h-48, GDI::TALIGN_ML);
			}

			// AC Status
			$x=$w-250;
			$gdi->color($color["w"]);
			if ($data["clima"]["auto"]) {
				$gdi->text($font["sansationMEDb"], "AUTO", $x, $h-48, GDI::TALIGN_MR);
			} else if ($data["clima"]["acoff"]) {
				$gdi->text($font["sansationMEDb"], "AC/OFF", $x, $h-48, GDI::TALIGN_MR);
			} else if ($data["clima"]["acon"]) {
				$gdi->text($font["sansationMEDb"], "AC/ON", $x, $h-48, GDI::TALIGN_MR);
			}

			// Temperatures
			foreach ($climas=Array(
				Array("temp"=>$data["clima"]["t1"], "x"=>170),   // driver
				Array("temp"=>$data["clima"]["t2"], "x"=>$w-60), // passenger
			) as $clima) {
				$temp=$clima["temp"];
				if (is_numeric($temp)) {
					$p=1-(($temp-$temp_min)/$temp_len);
					$gdi->color(Array(255-$p*127,128+$p*127,128+$p*127));
				} else {
					$high=($temp=="HI");
					$gdi->color($color[($high?"tmax":"tmin")]);
				}
				$gdi->text($font["digitsLCD"], $temp, $clima["x"], $h-10, GDI::TALIGN_BR);
				$gdi->text($font["sansationMEDb"], "o", $clima["x"]+5, $h-100, GDI::TALIGN_BL);
			}

		}

		// refresh screen
		$gdi->update();

		// poll events
		$event=false;
		while (SDL_PollEvent($event)) {
			switch ($event["type"]) {
			case SDL_QUIT: $running=false; break;
			case SDL_KEYDOWN:
				$keysym=$event["key"]["keysym"]["sym"];
				if ($keysym==SDLK_ESCAPE || $keysym==SDLK_q) $running=false;
				if ($keysym==SDLK_LALT) $key_lalt=true;
				if ($keysym==SDLK_RETURN && $key_lalt || $keysym==SDLK_f) {
					$flags^=SDL_FULLSCREEN;
					$screen=SDL_SetVideoMode($screen["w"], $screen["h"], $screen["bpp"], $flags);
				}
				break;
			case SDL_KEYUP:
				$keysym=$event["key"]["keysym"]["sym"];
				if ($keysym==SDLK_LALT) unset($key_lalt);
				break;
			default: // ignore
			}
		}

	}

	// this is the end!
	echo "Bye!\n";

