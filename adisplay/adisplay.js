// Accord Interface
function AccordInterface(o) {
	var self=this;
	var o=o||{};
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
		self.o.clima=a;
		//lib.echo(adump(a)+"\n");
		return a;
	};

	// devolver información de climatización
	self.clima=function(){
		return self.o.clima;
	};

};

var app={

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
			case "-d": case "--device": app.device=args[++i]; break;
			case "-f": case "--fullscreen": app.fullscreen=true; break;
			case "-h": case "--help":
				lib.echo(
					args[1]+" [options]\n"
					+"   -d --device <device>  Set device\n"
					+"   -f --fullscreen       Fullscreen\n"
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
				var datos={
					//clock: app.dateToTime(actual).substring(0,5),
					clima: app.iface.clima()
				};
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
			app.renderText(app.fonts.small, fps+"fps", app.w-10, 10, 2, [96,96,96]);

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
