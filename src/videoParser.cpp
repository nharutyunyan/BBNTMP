/*
 * videoParser.cpp
 *
 *  Created on: Օգս 26, 2013
 *      Author: Trainee
 */
#include "videoParser.hpp"
#include <fstream>
#include <QDebug>

 unsigned int VideoParser::getVideoSize(QString path)
 {
	 QString format = getVideoFormat(path);
	 if( format == "avi")
		return getAviSize(path);
	 if(format == "QuickTime")
		 return getQuickTimeFileSize(path);
	 if(format == "Unknown")
		 return 0;
 }

 QString VideoParser::getVideoFormat(QString path)
 {

	 char* ext = new char[4];
	 fstream videoFile;
	 videoFile.open(path.toStdString().c_str(), videoFile.binary|videoFile.in);
	 videoFile.seekg(8,videoFile.beg);
	 videoFile.read(ext,3);
	 if(ext[0] == 'A'&& ext[1] == 'V' && ext[2] == 'I')
		 return "avi";
	 videoFile.seekg(4,videoFile.beg);
	 videoFile.read(ext,4);
	 unsigned int ftyp_size;
	 if(ext[0] == 'f'&& ext[1] == 't' && ext[2] == 'y' && ext[3] == 'p')
		 return "QuickTime";
	 return "Unknown";
 }

 unsigned int VideoParser::getAviSize(QString path)
 {
	 unsigned int size;
	 fstream videoFile;
	 videoFile.open(path.toStdString().c_str(), videoFile.binary|videoFile.in);
	 videoFile.seekg(4,videoFile.beg);
	 videoFile.read((char*)&size,4);
	 return size;
 }

 unsigned int VideoParser::getQuickTimeFileSize(QString path)
 {
	 unsigned int currentAtomSize;
	 char* atomName = new char[4];
	 char* num = new char[4];
	 fstream videoFile;
	 videoFile.open(path.toStdString().c_str(), videoFile.binary|videoFile.in);
	 videoFile.seekg(0,videoFile.beg);
	 videoFile.read(num,4);
	 currentAtomSize = charToint(num);
	 videoFile.seekg(4,videoFile.beg);
	 videoFile.read(atomName,4);
	 while(!(atomName[0] == 'm' && atomName[1] == 'd' && atomName[2] == 'a' && atomName[3] == 't'))
	 {
		 videoFile.seekg(0, videoFile.end);
		 if(currentAtomSize > videoFile.tellg())
			 return 0;
		 videoFile.seekg(currentAtomSize,videoFile.beg);
		 videoFile.read(num,4);
		 videoFile.seekg(currentAtomSize + 4,videoFile.beg);
		 videoFile.read(atomName,4);
		 currentAtomSize += charToint(num);
	 }
	 return currentAtomSize;
 }

 unsigned int VideoParser::charToint(char* num)
 {
	 char temp1= num[0];
	 num[0] = num[3];
	 num[3] = temp1;
	 char temp2 = num[1];
	 num[1] = num[2];
	 num[2] = temp2;
	 return (*((int*)num));
 }
