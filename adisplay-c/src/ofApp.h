#pragma once

#include "ofMain.h"
#include <map>

class ofApp : public ofBaseApp{

	public:

		void setup();
		void update();
		void draw();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);

		void processPackets();

		void imageLoad(string alias, string fileName);
		void fontLoad(string alias, string fileName, int size);

		map<string, ofImage> images;
		map<string, ofTrueTypeFont> fonts;

		bool fullScreen=false;

		bool serialAvailable;
		ofSerial serial;
		string buffer;

		string clock;

};

