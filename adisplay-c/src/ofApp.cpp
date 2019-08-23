#include "ofApp.h"
#include "accord8th_radio_packets.h"

// convert number to string
template <typename T> string numberToString(T number) {
	ostringstream ss;
	ss << number;
	return ss.str();
}

// draw text aligned
void drawStringAlignLeft(ofTrueTypeFont font, string text, unsigned int x, unsigned int y) {
	font.drawString(text, x, y);
}
void drawStringAlignRight(ofTrueTypeFont font, string text, unsigned int x, unsigned int y) {
	ofRectangle r=font.getStringBoundingBox(text, 0, 0);
	font.drawString(text, x-(r.x+r.width), y);
}
void drawStringAlignCenter(ofTrueTypeFont font, string text, unsigned int x, unsigned int y) {
	ofRectangle r=font.getStringBoundingBox(text, 0, 0);
	font.drawString(text, x-(r.x+r.width)/2, y);
}

// load image
void ofApp::imageLoad(string alias, string fileName) {
	ofImage image;
	image.load(fileName);
	images[alias]=image;
}

// load font
void ofApp::fontLoad(string alias, string fileName, int fontSize) {
	ofTrueTypeFont font;
	font.load(fileName, fontSize, true, true);
	font.setLetterSpacing(1);
	font.setSpaceSize(0.5);
	fonts[alias]=font;
}

// setup
void ofApp::setup() {

	// inicializar
	clock="";

	// general
	ofSetWindowTitle("Accord 8th Display");
	ofSetVerticalSync(true);
	ofEnableSmoothing();
	ofEnableAlphaBlending();
	ofSetFrameRate(30);
	/*
		ofSetLogLevel(OF_LOG_VERBOSE);
		ofSetRectMode(OF_RECTMODE_CENTER);
		for ( int i=0; i<ofGetWidth(); i+=step )
		for ( int j=0; j<ofGetHeight(); j+=step )
	*/

	// set background
	ofBackground(0, 0, 0, 255);

	// OF default is 96
	ofTrueTypeFont::setGlobalDpi(96);

	// preload images
	imageLoad("sys.bg", "bg.jpg");
	//imageLoad("sys.overlay", "overlay.png");
	imageLoad("sys.clock", "clock.png");
	imageLoad("sys.bluetooth", "bluetooth.png");
	imageLoad("sys.usb", "usb.png");
	imageLoad("sys.cd0", "cd0.png");
	imageLoad("sys.cd1", "cd1.png");
	imageLoad("sys.cd2", "cd2.png");
	imageLoad("sys.stereo", "stereo.png");
	imageLoad("sys.af", "af.png");
	imageLoad("sys.ta", "ta.png");
	imageLoad("sys.tp", "tp.png");
	imageLoad("sys.rds", "rds.png");

	// preload fonts
	fontLoad("console", "Sansation_Light.ttf", 16);
	fontLoad("sansation24l", "Sansation_Light.ttf", 24);
	fontLoad("sansation32l", "Sansation_Light.ttf", 32);
	fontLoad("sansation24b", "Sansation_Bold.ttf", 26);
	fontLoad("sansation32b", "Sansation_Bold.ttf", 32);
	fontLoad("sansation48b", "Sansation_Bold.ttf", 48);
	fontLoad("LCD54b", "LCD.ttf", 54);
	fontLoad("LCD68b", "LCD.ttf", 68);
	//fontLoad("audimatmono54b", "Audimat-Mono-Bold.ttf", 54);
	//fontLoad("audimatmono58b", "Audimat-Mono-Bold.ttf", 58);
	//fontLoad("robotomono48b", "RobotoMono-Bold.ttf", 48);
	//fontLoad("robotomono56b", "RobotoMono-Bold.ttf", 56);
	//fontLoad("robotomono48b", "NovaMono.ttf",drawString 48);
	//fontLoad("robotomono56b", "NovaMono.ttf", 56);

	// initialize packet system
	xPacketsInit();

	// locate serial devices
	serial.listDevices();
	vector <ofSerialDeviceInfo> deviceList=serial.getDeviceList();
	serialAvailable=false;

}

// process packets
void ofApp::processPackets() {
	if (xPackets.size()) {
		cout<<"("<<dec<<xPackets.size()<<") New Packets:"<<endl;
		while (!xPackets.empty()) {
			xPacket p=xPackets.front();
			xPackets.pop();
			cout<<"- Packet("<<p.len<<"):"<<xPacketDataDump(p.data)<<endl;
			switch (p.len) {
			case 0x05:
				switch (p.data[1]) {
				case ':':
					stringstream b;
					b<<(p.data[3]<0x10?"0":"")<<hex<<(int)p.data[3]<<":"<<(p.data[4]<0x10?"0":"")<<hex<<(int)p.data[4];
					clock=b.str();
					cout<<"- CLOCK: "<< clock <<endl;
					break;
				}//CLOCK(05):(01)(17)(01)(04)
				break;

			}
		}
	}
}

// update app
void ofApp::update() {

	static unsigned long lastCheck=0;
	//unsigned int readBufferCount=0;
	unsigned int readBufferBytes=0;
	unsigned char readBuffer[1024]; // max packet length=1K

	// read bytes from serial port
	if (serialAvailable && serial.available()) {
		lastCheck=ofGetElapsedTimeMillis();
		while ((readBufferBytes=serial.readBytes(readBuffer, sizeof(readBuffer)))>0) {
			//buffer+=string(readBuffer, readBuffer+readBufferBytes);
			xPacketDataReceive(string(readBuffer, readBuffer+readBufferBytes));
			processPackets();
			//readBufferCount+=readBufferBytes;
		}
	} else {
		if (ofGetElapsedTimeMillis()-lastCheck>3000 || !lastCheck) {
			lastCheck=ofGetElapsedTimeMillis();
			serial.close();
			serialAvailable=serial.setup("COM21", 19200);
		}
	}

	// process pending packets
	processPackets();

}

//--------------------------------------------------------------
void ofApp::draw() {

	int w=ofGetWidth();
	int h=ofGetHeight();

	ofPushMatrix();

	//ofScale(1.0, 1.0, 1.0);
	//ofGetElapsedTimeMillis()%2

	ofSetColor(255);
	images["sys.bg"].draw(0, 0);

	ofSetColor(96);
	drawStringAlignLeft(fonts["console"], numberToString(w)+"x"+numberToString(h)+" "+numberToString(ofGetElapsedTimeMillis()), 10, h-4);

	//ofSetColor(32);
	//images["sys.overlay"].draw(0, 0);

	// Clock
	clock="12:32";
	if (clock!="") {
		ofSetColor(255);
		images["sys.clock"].draw(15, 24);
		drawStringAlignRight(fonts["LCD68b"], clock.substr(0,2), 175, 90);
		drawStringAlignLeft(fonts["LCD68b"], clock.substr(3,5), 205, 90);
		ofSetColor(ofGetSeconds()%2?255:128);
		drawStringAlignCenter(fonts["LCD68b"], ":", 188, 90);
	}

	// CDs
	ofSetColor(255);
	for (uint i=0;i<6;i++) {
		int x=320+i*115;
		if (i==2) images["sys.cd2"].draw(x-10, 20);
		images[(i==1 || i==2?"sys.cd1":"sys.cd0")].draw(x, 20);
		drawStringAlignLeft(fonts["sansation24b"], numberToString(i+1), x+80, 88);
	}

	// USB & Bluetooth
	images["sys.usb"].draw(1030, 20);
	images["sys.bluetooth"].draw(1180, 20);
	//ofSetColor(32);
	//images["sys.bluetooth"].draw(1180, 20);

	ofSetColor(ofGetSeconds()%3?255:48);
	images["sys.af"].draw(w-535, 120);
	ofSetColor(ofGetSeconds()%4?255:48);
	images["sys.ta"].draw(w-430, 120);
	ofSetColor(ofGetSeconds()%5?255:48);
	images["sys.tp"].draw(w-325, 120);
	ofSetColor(ofGetSeconds()%2?255:48);
	images["sys.rds"].draw(w-220, 120);
	ofSetColor(ofGetSeconds()%6?255:48);
	images["sys.stereo"].draw(w-105, 120);

	// Playing/Menus
	ofSetColor(255);
	drawStringAlignLeft(fonts["sansation32l"], "The Prodigy", 320, 230);
	drawStringAlignRight(fonts["sansation32b"], "Track 125", 290+5, 230);
	drawStringAlignLeft(fonts["sansation48b"], "Take me to the Hospital", 320, 290);
	drawStringAlignRight(fonts["LCD54b"], "3:57", 290, 290);
	ofSetColor(220);
	drawStringAlignRight(fonts["sansation24b"], "Mem 6", 290, 330);
	drawStringAlignLeft(fonts["sansation24l"], "USB", 320, 330);

	// Climatizer
	drawStringAlignLeft(fonts["LCD68b"], "23", 15, h-20);
	drawStringAlignRight(fonts["LCD68b"], "23", w-15-30, h-20);
	drawStringAlignLeft(fonts["sansation24b"], "o", 112, h-60);
	drawStringAlignRight(fonts["sansation24b"], "o", w-15, h-60);

	ofPopMatrix();

	/*
		ofRect(420, 97, 292, 62);
		ofSetColor(54, 54, 54);
		ofLine(30, 169, ofGetWidth()-4, 169);
		ofSetColor(225);

		ofPushMatrix();
			string rotZ = "Rotate Z";
			ofRectangle bounds = verdana30.getStringBoundingBox(rotZ, 0, 0);
			ofTranslate(110 + bounds.width/2, 500 + bounds.height / 2, 0);
			ofRotateZ(ofGetElapsedTimef() * -30.0);
			verdana30.drawString(rotZ, -bounds.width/2, bounds.height/2 );
		ofPopMatrix();

		ofPushMatrix();
			string scaleAA = "SCALE AA";
			bounds = verdana14.getStringBoundingBox(scaleAA, 0, 0);
			ofTranslate(500 + bounds.width/2, 480 + bounds.height / 2, 0);
			ofScale(2.0 + sin(ofGetElapsedTimef()), 2.0 + sin(ofGetElapsedTimef()), 1.0);
			verdana14.drawString(scaleAA, -bounds.width/2, bounds.height/2 );
		ofPopMatrix();

		ofPushMatrix();
			string scaleA = "SCALE ALIASED";
			bounds = verdana14A.getStringBoundingBox(scaleA, 0, 0);
			ofTranslate(500 + bounds.width/2, 530 + bounds.height / 2, 0);
			ofScale(2.0 + cos(ofGetElapsedTimef()), 2.0 + cos(ofGetElapsedTimef()), 1.0);
			verdana14A.drawString(scaleA, -bounds.width/2, bounds.height/2 );
		ofPopMatrix();
	*/

}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
	switch (key) {
	case 'f':
		fullScreen=!fullScreen;
		ofSetFullscreen(fullScreen);
		break;
	// OF_KEY_DEL OF_KEY_BACKSPACE OF_KEY_RETURN
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){
}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){
}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){
}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){
}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){
}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){
}
