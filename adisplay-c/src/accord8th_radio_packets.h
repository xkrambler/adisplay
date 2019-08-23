#pragma once

#ifndef __ACCORD_PACKETS
#define __ACCORD_PACKETS

#include <stdlib.h>
#include <time.h>
#include <string>
#include <iostream>
#include <sstream>
#include <map>
#include <queue>

#define BS_INITIAL 0
#define BS_START 1
#define BS_LENGHT 2
#define BS_DATA 3
#define BS_PREEND 4
#define BS_END 5
#define BS_LRC 6

using namespace std;

class xPacket {
	public:
		bool ok;
		unsigned int len;
		string data;
};

string xPacketBuffer;
queue<xPacket> xPackets;

// initialize packet system
void xPacketsInit() {
	xPacketBuffer="";
}

// dump packet data
string xPacketDataDump(string data) {
	stringstream b;
	for (unsigned int i=0;i<data.length();i++) {
		unsigned char c=data[i];
		if (c<33 || c>127) {
			b<<"("<<(c<0x10?"0":"");
			b<<hex<<(unsigned int)c;
			b<<")";
		} else b<<dec<<c;
	}
	return b.str();
}

// debug packet data
/*void xPacketDataDebug(string data) {
	for (unsigned int i=0;i<data.length();i++) {
		unsigned char c=data[i];
		if (c<33 || c>127) {
			cout<<"("<<(c<0x10?"0":"");
			cout<<hex<<(unsigned int)c;
			cout<<")";
		} else cout<<dec<<c;
	}
	cout<<dec;
}*/

// calculate packet data LRC
unsigned char xPacketDataLRC(string data) {
	unsigned char lrc=0x10^0x03;
	for (unsigned int i=0;i<data.length();i++)
		lrc^=data[i];
	return lrc;
}

// prepare to receive data to create packets
void xPacketDataReceive(string bytes) {

	// add bytes received to the packet buffer
	xPacketBuffer+=bytes;
	//cout<<"RECV:"<<xPacketDataDump(bytes)<<endl;

	// packet state machine
	xPacket p;
	int bs=BS_INITIAL;
	for (unsigned int i=0;i<xPacketBuffer.length();i++) {
		unsigned char c=xPacketBuffer[i];
		switch (bs) {
		case BS_INITIAL:
			if (c==0x10) {
				if (i) {
					cout<<"WARN: Discarded "<<(int)i<<" bytes"<<endl;
					xPacketBuffer=xPacketBuffer.substr(i); // if not first byte, discard
					i=0; // restart
				}
				bs=BS_START;
				//cout<<"FROM:"<<xPacketDataDump(xPacketBuffer)<<endl;
			}
			break;

		case BS_START:
			bs=(c==0x02?BS_LENGHT:BS_INITIAL);
			break;

		case BS_LENGHT:
			bs=BS_DATA;
			p.ok=false;
			p.len=(unsigned int)c;
			p.data="";
			p.data+=c;
			//cout << "***" << p.data << "***" << endl;
			//cout<<"Need:" << p.len << " Found: " << xPacketBuffer.length() << " Char: " << dec << c << endl;
			break;

		case BS_DATA:
			p.data+=c;
			if (c==0x10) i++; // me salto el siguiente byte
			//cout<<dec<<"c="<<hex<<(int)c<<" p.data.lenght="<<p.data.length()<<" p.len="<<p.len<<endl;
			if (p.data.length()>=p.len+1) bs=BS_PREEND;
			break;

		case BS_PREEND:
			//cout<<" Caracter actual:" << dec << (int)c << endl;
			bs=(c==0x10?BS_END:BS_INITIAL);
			if (bs==BS_INITIAL) { cout<<"FAILED AT BS_PREEND"<<endl;}
			break;

		case BS_END:
			bs=(c==0x03?BS_LRC:BS_INITIAL);
			if (bs==BS_INITIAL) { cout<<"FAILED AT BS_END"<<endl;}
			break;

		case BS_LRC:
			bs=BS_INITIAL;
			p.ok=(c==xPacketDataLRC(p.data));
			xPacketBuffer=xPacketBuffer.substr(i+1); // discard until actual byte
			//cout<<"LRC "<<(p.ok?"OK":"ERR")<<", NEXT:"<<xPacketDataDump(xPacketBuffer)<<endl;
			i=-1; // next iteration will be 0
			xPackets.push(p);
			break;

		}
	}

}

#endif
