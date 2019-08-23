// Accord Interface
function AccordInterface(o) {
	var self=this;
	var o=o||{};
	self.data={};
	self.data.clock="";
	self.data.clima={};
	self.o=o;
	self.o.buffer="";
	self.o.connected=false;
	self.o.initialized=false;
	self.o.interval=3000;
	self.o.timeout=1000;

	self.connected=function(){
		return self.o.connected;
	};

	self.initialized=function(){
		return self.o.initialized;
	};

	self.echo=function(msg){
		lib.echo("[AccordInterface] "+msg+"\n");
	};

	self.device=function(device){
		if (isset(device)) self.o.device=device;
		return (self.o.device?self.o.device:false);
	};

	self.init=function(){
		self.serial=lib.serial.init(self.o.device);
		return (self.serial?true:false);
	};

	self.open=function(){
		self.o.connected=lib.serial.open(self.serial);
		self.o.pingTimer=new Date();
		self.o.timeoutTimer=false;
		self.setup();
		return self.o.connected;
	};

	self.close=function(){
		lib.serial.close(self.serial);
		self.o.pingTimer=false;
		self.o.timeoutTimer=false;
		self.o.connected=false;
		self.o.initialized=false;
	};

	self.read=function(){
		return lib.serial.read(self.serial);
	};

	self.data=function(){
		return lib.serial.data(self.serial);
	};

	self.write=function(p){
		if (!lib.serial.write(self.serial, p)) {
			self.echo("Cannot write, disconnecting!");
			self.close();
			return false;
		}
		return true;
	};

	self.error=function(){
		return lib.serial.error(self.serial);
	};

	// setup interface
	self.setup=function(){
		self.write("-a-d-u+s");
		self.o.initialized=true;
	};

	// comprobar ping
	self.pingCheck=function(){
		if (self.o.initialized) {
			var actual=new Date();
			if (self.o.timeoutTimer) {
				//app.iface.echo("timeout="+(actual - self.o.timeoutTimer)+">"+self.o.timeout);
				if ((actual - self.o.timeoutTimer) > self.o.timeout) {
					app.iface.echo("TIMEOUT!");
					self.close();
					return false;
				}
			} else {
				//app.iface.echo("ping="+(actual - self.o.pingTimer)+">"+self.o.interval);
				if ((actual - self.o.pingTimer) > self.o.interval) { // ping a intervalos (en ms)
					app.iface.echo("PING!");
					self.o.timeoutTimer=actual;
					return self.ping();
				}
			}
		}
		return true;
	};

	// hacer ping
	self.ping=function(){
		self.o.ping=new Date();
		return self.write("p")
	};

	// read and process buffer
	self.process=function(){
		var n=self.read();
		if (n<0) return false; // connection closed
		if (n==0) return 0; // no data
		self.o.buffer+=self.data();
		while ((n=self.o.buffer.indexOf("\n"))>=0) {
			var line=self.o.buffer.substring(0, n);
			self.o.buffer=self.o.buffer.substring(n+1);
			if (line.length) {
				self.o.pingTimer=new Date();
				self.o.timeoutTimer=false;
				self.echo(line);
				var p=line.indexOf(" ");
				var c=(p>=0?line.substring(0,p):line);
				var p=(p>=0?line.substring(p):"");
				switch (c) {
				case "OK": break;
				case "PONG": break;
				case "DIGITAL": break;
				case "ANALOG": break;
				case "UART": self.decodeUART(self.decodeHex(p)); break;
				case "SPI": self.decodeSPI(self.decodeHex(p)); break;
				}
			}
		}
	};

	// convert hex string to decimal byte array
	self.decodeHex=function(hex){
		var hex=hex.replace(/\s/g, ''), bytes=[], str;
		for (var i=0; i<hex.length-1; i+=2)
			bytes.push(parseInt(hex.substr(i, 2), 16));
		return bytes;
	};

	// CRC SPI
	self.checksumSPI=function(p) {
		return p[1] ^ p[2] ^ p[3] ^ p[4] ^ p[5] ^ p[6] ^ p[7] ^ 0x40;
	};

	// verify SPI packet
	self.verifySPI=function(p) {
		return (
			p.length==10
			&& p[0]==0x80
			&& p[8]==0x80
			&& p[9]==self.checksumSPI(p)
		);
	};

	// HVAC SPI-bus packet decoding
	self.decodeSPI=function(p) {
		//lib.echo("SPI["+p+"]\n");
		if (!self.verifySPI(p)) return false;
		var a={
			time: new Date(),
			t1: "",
			t2: "",
			manual: 0,
			ac: "",
			mode: ""
		};
		if (p[3]==0xDC) a.t1="LO";
		if (p[3]==0xEF) a.t1=19;
		if (p[3]==0x86) a.t1=21;
		if (p[3]==0x9B) a.t1=22;
		if (p[3]==0x8F) a.t1=23;
		if (p[3]==0xE6) a.t1=24;
		if (p[3]==0xAD) a.t1=25;
		if (p[3]==0xFD) a.t1=(p[5] & 0x4?26:16);
		if (p[3]==0xC7) a.t1=(p[5] & 0x4?27:17);
		if (p[3]==0xBF) a.t1=(p[5] & 0x4?(p[5] & 0x08?28:20):18);
		if (p[3]==0xD0) a.t1="HI";
		if (p[1]==0x1C) a.t2="LO";
		if (p[1]==0x2F) a.t2=19;
		if (p[1]==0x46) a.t2=21;
		if (p[1]==0x5B) a.t2=22;
		if (p[1]==0x4F) a.t2=23;
		if (p[1]==0x26) a.t2=24;
		if (p[1]==0x6D) a.t2=25;
		if (p[1]==0x3D) a.t2=(p[5] & 0x10?26:16);
		if (p[1]==0x07) a.t2=(p[5] & 0x10?27:17);
		if (p[1]==0x7F) a.t2=(p[5] & 0x10?(p[5] & 0x20?28:20):18);
		if (p[1]==0x10) a.t2="HI";
		if ((p[6] & 0xF0) == 0xE0) a.manual=1;
		if ((p[6] & 0xF0) == 0xD0) a.manual=2;
		if ((p[6] & 0xF0) == 0xB0) a.manual=3;
		if ((p[6] & 0xF0) == 0xC0) a.manual=4;
		if ((p[6] & 0xF0) == 0xA0) a.manual=5;
		if ((p[6] & 0xF0) == 0x90) a.manual=6;
		if ((p[6] & 0xF0) == 0xF0) a.manual=7;
		if ((p[6] & 0x0F) == 0x00) a.ac="auto";
		if ((p[6] & 0x0F) == 0x05) a.ac="on";
		if ((p[6] & 0x0F) == 0x06) a.ac="off";
		if (p[7]==0xF8) a.mode="feet_defrost";
		if (p[7]==0xB0) a.mode="feet";
		if (p[7]==0xF4) a.mode="feet_front";
		if (p[7]==0xA4) a.mode="front";
		if (!a.t1) a=false; // si no tenemos temperatura, esta el climatizador apagado	
		self.data.clima=a;
		//lib.echo(adump(a)+"\n");
		return a;
	};

	// calculate LRC
	self.uartLRC=function(p){
		var r=0;
		// XOR all except the DLE-STX header...
		for (var i=0; i<p.length; i++)
			r=r^p[i];
		r=r^0x10^0x03; // ...but including filling DLE's and DLE-ETX
		return r;
	};

	// get hex byte
	self.hexByte=function(b){
		return ("0"+b.toString(16)).substr(-2);
	};

	// convert to BCD number
	self.bcdNumber=function(s){
		var r="";
		for (var i=0; i<s.length; i++)
			r+=self.hexByte(s[i]);
		r=parseInt(r.replace(/f/g, ""));
		return (r?r:0);
	};

	// convert to string
	self.toString=function(p, s, len){
		var r="";
		for (var i=s; i<s+len; i++)
			r+=String.fromCharCode(p[i]);
		return r;
	};

	// OEM Radio Display UART packet decoding
	self.decodeUARTpacket=function(p){

		switch (p[0]) {
		case 0x05:
			// clock
			// 10 02 05 3A 01 17 02 04 10 03 3C
			if (p[1] == 0x3A) {
				self.data.clock=self.hexByte(p[3])+":"+self.hexByte(p[4]);
				//lib.echo("clock="+self.hexByte(p[5])+":"+self.hexByte(p[6])+"\n");
			}
			break;

		case 0x09:
			// information
			if (p[1] == 0x32) {
				self.data.ta =(p[6] & 1 == 1);
				self.data.usb=(p[5] & 2 == 2);
			}
			break;
	
		case 0x10:
			// 10 02 10 30 03 10 03 43 11 05 FF 01 FF 73 FF F2 40 00 00 10 03 4B // timming 2:40
			// 10 02 10 30 03 10 03 43 11 05 FF 01 FF 73 FF F2 41 00 00 10 03 4A // timming 2:41
			// 10 02 10 30 03 10 03 01 0B 05 FF 01 FF 13 FF F5 04 00 00 10 03 30
			// 10 02 10 30 03 10 03 01 0B 05 FF 01 FF 14 FF F0 05 00 00 10 03 33
			// 10 02 10 30 03 10 03 01 0B 05 FF 01 FF 13 FF F4 55 00 00 10 03 62
			// *  *  10 30 03 10 01 01 05 05 ff ff ff ff ff ff ff 00 00 // menu
			// *  *  10 30 03 10 03 01 05 05 ff 01 ff 02 ff f0 28 00 00 *  *  * // usb
			if (p[1] == 0x30) {
				self.data.mode=(p[4]==0x01?"menu":"usb"); // usb es ¿00=loading 03=playing?
				self.data.vol=p[6];
				self.data.folder=self.bcdNumber([p[8], p[9]]);
				self.data.track=self.bcdNumber([p[10], p[11]]);
				self.data.time=self.bcdNumber([p[12], p[13]])+":"+self.bcdNumber([p[14]]);
				lib.echo("mode="+self.data.mode+" vol="+self.data.vol+" folder="+self.data.folder+" track="+self.data.track+" time="+self.data.time+"\n");
			// volumen
			// 10 02 10 30 03 10 01 01 98 05 FF FF FF FF FF FF FF 00 00
			} else if (p[5] == 0x01) {
				self.data.vol=p[6]-0x80;
			}
			break;

		case 0x15:
			// radio
			// 10 02 15 30 01 00 00 22 11 01 01 FF 91 60 40 03 4D 41 58 49 4D 41 46 4D 10 03 53
			if (p[12] == 0x40) {
				switch (p[3]) {
				case 0x00: self.data.channel="FM-1"; break;
				case 0x01: self.data.channel="FM-2"; break;
				case 0x07: self.data.channel="MW-1"; break;
				case 0x08: self.data.channel="LW-1"; break;
				}
				self.data.mode="radio";
				self.data.stereo=(p[13] & 1 == 1);
				self.data.vol=p[6];
				self.data.key=self.bcdNumber([p[8]]);
				self.data.freq=self.bcdNumber([p[9], p[10]])+"."+self.bcdNumber([p[11]]);
				self.data.msg=self.toString(p, 14, 8);
				lib.echo("radio stereo="+self.data.stereo+" key="+self.data.key+" freq="+self.data.freq+" msg="+self.data.msg+"\n");
			// volumen
			// 10 02 15 30 01 00 00 01 8A 01 00 FF FF FF 7F 00 00 00 00 00 00 00 00 00 10 03 55
			} else if (p[5] == 0x01) {
				self.data.vol=p[6]-0x80;
			}
			break;

		case 0x17:
			if (p[1] == 0x34) {
				if (p[20] & 0x10 == 0x10) {
					/*
mode=menu vol=5 folder=0 track=0 time=0:0
 17 34 20 00 53 43 41 4e 20 20 20 20 20 20 20 46 4c 44 00 02 12 00 00 00
usb msg=  SCAN       FL
 17 34 20 00 53 43 41 4e 20 20 20 20 20 20 20 46 4c 44 00 02 12 00 00 00
usb msg=  SCAN       FL
UART(ERROR[37]) 17 34 20 00 53 43 41 4e 20 20 20 20 20 20 20 46 4c 00 00 00 00
UART(ERROR[235]) 17 34 20 00 53 43 41 4e 20 20 20 20 20 20 20 46 4c 00 00 00 00 10 10 02 10 30 03 10 01 01 05 05 ff ff ff ff ff ff ff 00 00
 10 30 03 10 01 01 05 05 ff ff ff ff ff ff ff 00 00
mode=menu vol=5 folder=0 track=0 time=0:0
 10 30 03 10 01 01 05 05 ff ff ff ff ff ff ff 00 00
					*/
					// if (p[18] & 0x02 == 0x02) // esto indicaría que estamos en el menú raíz (o bien, que no estamos configurando)
					// if (p[19] & 0x01 == 0x01) // esto indicaría que hay más elementos para desplazarse (ya no sé si arriba o abajo)
					// if (p[19] & 0x02 == 0x02) // esto indicaría que hay más elementos para desplazarse (idem)
					// 10 02 17 34 20 20 42 41 53 53 20 20 20 20 20 20 20 43 00 00 00 02 11 00 00 00 10 03 43
					self.data.mode="menu";
				} else {
					// 10 02 17 34 48 6F 6C 65 20 2D 20 56 69 6F 6C 65 74 20 20 20 00 00 00 00 00 00 10 03 3E
					self.data.mode="usb";
				}
				self.data.stereo=(p[13] & 1);
				self.data.key="";
				self.data.freq="";
				self.data.msg=self.toString(p, 2, 15).replace(/\0/g, " ");
				lib.echo(self.data.mode+" msg="+self.data.msg+"\n");
			}
			break;

		}
	};

	// OEM Radio Display UART buffer decoding
	self.decodeUART=function(p){
		if (!this.buffer) this.buffer=[];

/*
		if (!this.firstpacket) {
			this.firstpacket=true;
			this.buffer.push(65);
			this.buffer.push(66);
			this.buffer.push(67);
			// (10)(02)(10)(10)0(03)(10)(10)(03)(01)(0B)(05)(FF)(01)(FF)(14)(FF)(F0)(05)(00)(00)(10)(03)3
			this.buffer.push(0x10);
			this.buffer.push(0x02);
			this.buffer.push(0x10);
			this.buffer.push(0x10);
			this.buffer.push(0x30);
			this.buffer.push(0x03);
			this.buffer.push(0x10);
			this.buffer.push(0x10);
			this.buffer.push(0x03);
			this.buffer.push(0x01);
			this.buffer.push(0x0B);
			this.buffer.push(0x05);
			this.buffer.push(0xFF);
			this.buffer.push(0x01);
			this.buffer.push(0xFF);
			this.buffer.push(0x14);
			this.buffer.push(0xFF);
			this.buffer.push(0xF0);
			this.buffer.push(0x05);
			this.buffer.push(0x00);
			this.buffer.push(0x00);
			this.buffer.push(0x10);
			this.buffer.push(0x03);
			this.buffer.push(0x33);

			this.buffer.push(16);this.buffer.push(02);this.buffer.push(01);this.buffer.push(64);this.buffer.push(16);this.buffer.push(03);this.buffer.push(82);
			//[19:03:01.19] OK:(15)0(01)(00)(00)"(11)(01)(01)(FF)(91)`@(03)MAXIMAFM
			this.buffer.push(16);this.buffer.push(02);this.buffer.push(0x15);
			this.buffer.push(0);this.buffer.push(1);this.buffer.push(0);this.buffer.push(0);
			this.buffer.push(34);this.buffer.push(0x11);this.buffer.push(1);this.buffer.push(1);
			this.buffer.push(0xFF);
			this.buffer.push(0x91);
			this.buffer.push(0x60);
			this.buffer.push(0x40);
			this.buffer.push(0x03);
			this.buffer.push(0x41);
			this.buffer.push(0x42);
			this.buffer.push(0x43);
			this.buffer.push(0x41);
			this.buffer.push(0x42);
			this.buffer.push(0x43);
			this.buffer.push(0x41);
			this.buffer.push(0x43);
			this.buffer.push(16);this.buffer.push(03);
			this.buffer.push(123);


//		(10)(02)(15)0(01)(00)(00)(01)(8A)(01)(00)(FF)(FF)(FF)(00)(00)(00)(00)(00)(00)(00)(00)(00)(10)(03)=
//		(10)(02)(15)0(01)(00)(00)"(0A)(01)(03)(FF)(91)0@(03)CUARENTA(10)(03)(1B)

		}
*/
		for (var i in p)
			this.buffer.push(p[i]);

		//lib.echo("decodeUART:"); self.packetPrint(this.buffer);

		var i=0;
		while (i<this.buffer.length) {
			for (i=0; i<this.buffer.length; i++) {
				if (this.buffer[i]==0x10) {
					if (i+2 < this.buffer.length) {
						if (this.buffer[i+1]==0x02) {
							// borrar paquete mal formado hasta posición actual
							//if (i > 0) lib.echo("DISCARD:"); self.packetPrint(this.buffer, i);
							this.buffer.splice(0, i);
							// buscar a partir de aquí 10 03
							var p=[];
							for (var j=2; j<this.buffer.length-2; j++) {
								var c=this.buffer[j];
								if (c==0x10) {
									// miro si es una repetición, y la ignoro
									if (this.buffer[j+1]==0x10) {
										j++;
									} else if (this.buffer[j+1]==0x03) {
										// fin de paquete!
										var ok=(this.buffer[j+2] == self.uartLRC(p));
										//lib.echo("BUFFER:"); self.packetPrint(this.buffer);
										// quitar paquete del buffer
										this.buffer.splice(0, j+3);
										// procesar
										if (!ok) lib.echo("UART("+(ok?"OK":"ERROR["+self.uartLRC(p)+"]")+")"); self.packetPrint(p);
										if (ok) {
											self.decodeUARTpacket(p);
											i=0;
											break;
										}
									}
								}
								p.push(c);
							}
							return false;
						}
					} else {
						return false;
					}
				}
			}
		}

		// sin datos
		return false;

	};

	// imprimir datos de un paquete
	self.packetPrint=function(p, len){
		var c=1, len=len||0;
		for (var i in p) {
			lib.echo(" "+self.hexByte(p[i]));
			if (len && ++c > len) break;
		}
		lib.echo("\n");
	};

};

var app={

	"test":false,
	"device":false,
	"base":"data/",
	"title":"aDisplay",

	"dateToTime":function(date) {
		return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
	},

	"fontLoad":function(filename, size) {
		return lib.gdi.fontOpen(app.base+filename, size);
	},

	"textureLoad":function(filename) {
		var surface, texture;
		if (!(surface=lib.gdi.loadImage(app.base+filename))) return false;
		texture=lib.gdi.createTextureFromSurface(app.renderer, surface);
		lib.gdi.freeSurface(surface);
		return texture;
	},

	"renderText":function(font, text, x, y, align, color, alpha){
		if (!font || !text) return;
		var surface_text=lib.gdi.text(font, text, color);
		var texture_text=lib.gdi.createTextureFromSurface(app.renderer, surface_text);
		if (isset(alpha)) lib.gdi.setTextureAlphaMod(texture_text, alpha);
		lib.gdi.renderTexture(app.renderer, texture_text, x, y, align);
		var rect=lib.gdi.queryTexture(texture_text);
		lib.gdi.destroyTexture(texture_text);
		lib.gdi.freeSurface(surface_text);
		return rect;
	},

	"renderTexture":function(texture, x, y, align, alpha){
		if (texture) {
			if (isset(alpha)) lib.gdi.setTextureAlphaMod(texture, alpha);
			lib.gdi.renderTexture(app.renderer, texture, x, y, align);
		}
	},

	"getTempColor":function(temp){
		var t=temp;
		if (t=="LO") t=18;
		if (t=="HI") t=31;
		t-=18;
		if (t<0) t=0;
		if (t>16) t=16;
		var r=(t/16*128);
		return [128+r,255-r,255-r];
	},

	"connect":function(){
		app.iface.echo("Connecting to "+app.iface.device());
		if (app.iface.open()) {
			app.iface.echo("Connected successfully, waiting for data.");
		} else {
			app.iface.echo("Cannot open device: "+app.iface.error());
		}
	},

	"unload":function(){
		if (app.win) lib.gdi.destroyWindow(app.win);
		lib.exit(0);
	},

	"init":function(){
		// procesar parámetros
		var args=lib.kernel.args();
		for (var i=2;i<args.length;i++) {
			switch (args[i]) {
			case "-t": case "--test": app.test=true; break;
			case "-d": case "--device": app.device=args[++i]; break;
			case "-f": case "--fullscreen": app.fullscreen=true; break;
			case "-h": case "--help":
				lib.echo(
					args[1]+" [options]\n"
					+"   -d --device <device>  Set device\n"
					+"   -f --fullscreen       Fullscreen\n"
					+"   -t --test             Test mode (console mode)\n"
					+"   -h --help             Show this help\n"
				);
				lib.exit(0);
			default:
				//if (args[i].substring(0,1)!="-") app.device=args[i];
			}
		}
		// cargar librerías
		lib.include("common.js");
		// inicializar interface
		app.iface=new AccordInterface();
		// si hay device, conectar
		if (app.device) {
			app.iface.device(app.device);
			if (!app.iface.init()) {
				lib.echo("Cannot initialize device.");
				return false;
			}
		}

		// modo test
		if (app.test) {

			// intentar conectarse a la interfaz
			if (app.device) app.connect();

			// work loop
			while (true) {

				// procesar interface
				if (app.device) {
					if (app.iface.connected()) {
						// se comprueban datos a intervalos (en ms)
						if (!interfaceCheck || actual-interfaceCheck>250) {
							interfaceCheck=actual;
							//app.iface.echo("process();");
							var r=app.iface.process();
							if (r===false) app.iface.close();
							// comprobar ping a intervalos regulares
							if (!app.iface.pingCheck()) app.iface.echo("Ping timeout, closed connection.");
						}
					// si la interface no está conectada, intentar conectar
					} else {
						if (!app.retryTimer) app.retryTimer=actual;
						if ((actual - app.retryTimer) > 2500) {
							app.retryTimer=actual;
							app.connect();
						}
					}
				}

				// poll events
				if (lib.gdi.pollEvent().type=="quit") return false;

			}

		}

		// inicializar ventana gráfica
		app.w=1280;
		app.h=800;
		app.win=lib.gdi.window(app.title, 0, 0, app.w, app.h, 0);
		if (app.fullscreen) lib.gdi.setWindowFullscreen(app.win, 2);
		app.renderer=lib.gdi.createRenderer(app.win, -1, 0);
		return true;
	}

};

// inicializar núcleo
if (lib.kernel.init()) {

	// inicializar aplicación
	if (app.init()) {

		// intentar conectarse a la interfaz
		if (app.device) {
			do {
				if (!app.connect()) lib.gdi.delay(200);

				// intentar inicializar
				var start=new Date();
				while (!app.iface.initialized || (new Date() - start)<100)
					app.iface.process();

				// si no lo consigue, desconectar y volver a empezar
				if (!app.iface.initialized)
					app.iface.close();

			} while (!app.iface.initialized);
		}

		// cargar imágenes
		app.images={
			ac:{
				auto: app.textureLoad("ac_auto.png"),
				on:   app.textureLoad("ac_on.png"),
				//off:  app.textureLoad("ac_off.png")
			},
			clima:{
				feet:         app.textureLoad("clima_feet.png"),
				feet_defrost: app.textureLoad("clima_feet_defrost.png"),
				feet_front:   app.textureLoad("clima_feet_front.png"),
				front:        app.textureLoad("clima_front.png")
			},
			manual:[
				app.textureLoad("manual1.png"),
				app.textureLoad("manual2.png"),
				app.textureLoad("manual3.png"),
				app.textureLoad("manual4.png"),
				app.textureLoad("manual5.png"),
				app.textureLoad("manual6.png"),
				app.textureLoad("manual7.png"),
			],
			usbtrack: app.textureLoad("usbtrack.png"),
			logo:     app.textureLoad("logo.png"),
			//logo_red: app.textureLoad("logo_red.png"),
			clock:    app.textureLoad("clock.png"),
			//bgw:      app.textureLoad("bgw.png"),
			//bgn:      app.textureLoad("bgn.png"),
			bgb:      app.textureLoad("bgb.png"),
			bgg:      app.textureLoad("bgg.png"),
			bgr:      app.textureLoad("bgr.png")
		};

		// cargar fuentes
		app.fonts={
			bigger:       app.fontLoad("Bitstream Vera Sans.ttf", 90),
			big:          app.fontLoad("Bitstream Vera Sans.ttf", 64),
			small:        app.fontLoad("Bitstream Vera Sans.ttf", 24),
			temperature:  app.fontLoad("LCD.ttf", 160),
			temperature2: app.fontLoad("LCD.ttf", 175)
		};

		// bucle principal
		var bgs=[app.images.bgr, app.images.bgb, app.images.bgg];
		var bga=0;
		var bgtimer=false;
		var working=true;
		var start=new Date();
		var starting=0;
		var frames=0;
		var fullscreen=false;
		var lock_fps=false;
		var interfaceCheck=false;
		while (working) {

			// timming
			frames++;
			var actual=new Date();
			var elapsed=(actual-start);
			var fps=(elapsed?Math.round(frames*1000/elapsed):0);
			//if (!(frames%1000)) lib.gdi.windowTitle(app.win, "pruebas setTitle: "+fps+"fps - "+frames);

			// frame rate lock
			lib.gdi.delay(lock_fps && fps>lock_fps?((1000/lock_fps)-(1000/fps))*10:0);

			// startup
			var p=1;
			if (starting<1) {
				starting=elapsed/2000;
				if (starting>1) starting=1;
				p=(1-((1-starting)*(1-starting)));
			}

			// procesar interface
			if (app.device) {
				if (app.iface.connected()) {
					// se comprueban datos a intervalos (en ms)
					if (!interfaceCheck || actual-interfaceCheck>250) {
						interfaceCheck=actual;
						//app.iface.echo("process();");
						var r=app.iface.process();
						if (r===false) app.iface.close();
						// comprobar ping a intervalos regulares
						if (!app.iface.pingCheck()) app.iface.echo("Ping timeout, closed connection.");
					}
				// si la interface no está conectada, intentar conectar
				} else {
					if (!app.retryTimer) app.retryTimer=actual;
					if ((actual - app.retryTimer) > 2500) {
						app.retryTimer=actual;
						app.connect();
					}
				}
			}

			// datos
			if (app.device) {
				// obtener del dispositivo
				var datos=app.iface.data;
			} else {
				// datos random
				var datos={
					clock: app.dateToTime(actual).substring(0,5),
					clima: {
						"t1":parseInt(14+frames%1800/100),
						"t2":parseInt(14+(frames+805)%1800/100),
						"manual":parseInt((frames/200)%8),
					}
				};
				if (datos.clima.t1<18) datos.clima.t1="LO";
				if (datos.clima.t2<18) datos.clima.t2="LO";
				if (datos.clima.t1>28) datos.clima.t1="HI";
				if (datos.clima.t2>28) datos.clima.t2="HI";
				var _k=array_keys(app.images.clima);
				datos.clima.mode=_k[parseInt((frames+205)/500)%4];
				var _k=array_keys(app.images.ac);
				datos.clima.ac=_k[parseInt((frames+505)/1000)%3];
			}

			// si los datos del clima no se actualizan, mantener los datos un poco más
			if (datos.clima && datos.clima.time)
				if ((actual - datos.clima.time) >= 1000)
					datos.clima=false;

			// start frame
			lib.gdi.renderClear(app.renderer);

			// fondo actual
			app.renderTexture(bgs[bga], 0, 0, 0, parseInt(p*255));

			// animación de fondos
			if (p>=1) {
				if (!bgtimer) bgtimer=new Date();
				var bgp=(actual - bgtimer) / 60000; // cada 60sg
				var bgn=(bga+1)%bgs.length;
				app.renderTexture(bgs[bgn], 0, 0, 0, parseInt((bgp<1?bgp:1)*255));
				if (bgp>=1) {
					bga=bgn;
					bgtimer=false;
				}
			}
			
			// cuadros del clima
			//if (datos.clima) app.renderTexture(app.images.bgw, 0, app.h, 6);

			// logo
			//app.renderTexture(app.images.logo_red, app.w/2, app.h/2.5, 3+1);
			//app.renderTexture(app.images.logo, app.w/2, app.h/2.5, 3+1, parseInt(p*255));

			// music track
			if (false) {
				var x=100, y=app.h-280;
				app.renderTexture(app.images.usbtrack, x, y, 0);
				app.renderText(app.fonts.big, "Esto es un track de música", x+120, y+12, 0);
			}

			// radio mode
			if (datos.usb) app.renderText(app.fonts.big, "USB", app.w-490, 20, 2, [0,255,255]);
			if (datos.ta) app.renderText(app.fonts.big, "TA", app.w-340, 20, 2, [255,255,0]);
			switch (datos.mode) {
			case "radio":
				if (datos.stereo) app.renderText(app.fonts.big, "STEREO", app.w-20, 20, 2, [255,255,255]);
				app.renderText(app.fonts.bigger, datos.key, 50, 600, 6, [255,255,255]);
				app.renderText(app.fonts.bigger, datos.freq, 200, 600, 6, [192,255,255]);
				app.renderText(app.fonts.bigger, datos.msg, 500, 600, 6, [255,255,255]);
				break;

			case "usb":
				if (datos.stereo) app.renderText(app.fonts.big, "STEREO", app.w-20, 20, 2, [255,255,255]);
				app.renderText(app.fonts.bigger, datos.time, 100, 600, 6, [192,255,255]);
				app.renderText(app.fonts.bigger, datos.msg, 400, 600, 6, [255,255,255]);
				break;

			case "menu":
				app.renderText(app.fonts.small, "MENU", 250, 470, 6 [255,255,255]);
				app.renderText(app.fonts.bigger, datos.msg, 250, 600, 6, [255,255,255]);
				break;

			}
			app.renderText(app.fonts.bigger, datos.vol, app.w-50, 600, 8, [255,255,255]);

			// reloj
			var y=-100*(1-p);
			if (datos.clock) {
				app.renderTexture(app.images.clock, 20, y+20, 0);
				var rect=lib.gdi.queryTexture(app.images.clock);
				app.renderText(app.fonts.big, datos.clock, 30+rect.w, y+24, 0, [192,192,192]);
			}
			// climatizador
			if (datos.clima) {
				// clima: temperaturas
				var y=app.h+150*(1-p);
				var alpha=32;
				var color=[255, 255, 255];
				//var color=app.getTempColor(datos.clima.t1);
				if (datos.clima.t1) {
					var rect=app.renderText(app.fonts.temperature2, datos.clima.t1, 30-6, y+4, 6+0, color, alpha);
					var rect=app.renderText(app.fonts.temperature, datos.clima.t1, 30, y, 6+0, color);
					//app.renderText(app.fonts.big, "o", 30+rect.w, y-rect.h, 0, color);
				}
				//var color=app.getTempColor(datos.clima.t2);
				if (datos.clima.t2) {
					//var rect=app.renderText(app.fonts.big, "o", app.w-30, y-rect.h, 2, color);
					var rect={"w":0};
					app.renderText(app.fonts.temperature2, datos.clima.t2, app.w-30-rect.w+6, y+4, 6+2, color, alpha);
					app.renderText(app.fonts.temperature, datos.clima.t2, app.w-30-rect.w, y, 6+2, color);
				}
				// clima: manual
				var cx=app.w/2, cy=y-20;
				if (datos.clima.manual) app.renderTexture(app.images.manual[datos.clima.manual-1], cx, cy, 6+1);

				var sx=cx/2.5;
				// clima: mode
				if (datos.clima.mode) app.renderTexture(app.images.clima[datos.clima.mode], cx-sx, cy, 6+1);
				// clima: AC
				if (datos.clima.ac && datos.clima.ac!="off") app.renderTexture(app.images.ac[datos.clima.ac], cx+sx, cy, 6+1);
			}

			// fps
			app.renderText(app.fonts.small, fps+"fps", app.w-2, 1, 2, [96,96,96]);

			// end frame
			lib.gdi.renderPresent(app.renderer);

			// poll events
			var event=lib.gdi.pollEvent();
			//if (event.type) lib.echo("event="+JSON.stringify(event)+"\n");
			switch (event.type) {
			case "quit": working=false; break;
			case "keyup":
				//if (event.key.keysym.sym==100) lib.gdi.destroyWindow(win2);
				if (event.key.keysym.sym==13 && event.key.keysym.mod.indexOf("lalt")!=-1) {
					app.fullscreen=!app.fullscreen;
					lib.gdi.setWindowFullscreen(app.win, (app.fullscreen?2:0));
				}
				if (event.key.keysym.sym==27) working=false;
				break;
			//case "mousebuttondown":
			case "mousebuttonup":
			case "mousemotion":
				break;
			default:
				if (event.type) lib.echo("event="+JSON.stringify(event)+"\n");
			}

		}

	}

	// terminar aplicación
	app.unload();

}
