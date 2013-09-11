/*
 * videoParser.cpp
 *
 *  Created on: Օգս 26, 2013
 *      Author: Trainee
 */
#include "videoParser.hpp"
#include <fstream>
#include <QDebug>
#include <math.h>
#define GUID_SIZE 16
#define FILE_SIZE_OFFSET 40
#define HEADER_OBJECT_DATA_SIZE 30


VideoParser::VideoParser()
{
	ASF_Header_Object_GUID = "75B22630-668E-11CF-D9A6-6CCE6200AA00";
	ASF_File_Properties_Object_GUID_FIRST_COMPONENT = "8CABDCA1";
}

unsigned long long int VideoParser::getVideoSize(QString path)
 {
	 QString format = getVideoFormat(path);
	 if( format == "avi")
		return getAviSize(path);
	 if(format == "QuickTime")
		return getQuickTimeFileSize(path);
	 if(format == "asf_wmv")
	 	return getAsf_WmvSize(path);
	 if(format == "Unknown")
		return 0;
 }


 QString VideoParser::getVideoFormat(QString path)
 {

	 char* ext = new char[4];
	 fstream videoFile;
	 videoFile.open(path.toStdString().c_str(), videoFile.binary|videoFile.in);
	 if( getVideoHeaderGUID(&videoFile) ==  ASF_Header_Object_GUID)
		 return "asf_wmv";

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

 QString VideoParser::getVideoHeaderGUID(fstream* videoFile)
  {
	 QString result("");
 	 unsigned  long long int currentData = 0;
 	 int QUIDComponentsNumber = 5;
 	 int GUIDCurrentComponentSize = 0;
 	 int currentPos = 0;
 	 for(int i = 1; i <= QUIDComponentsNumber; ++i)
 	 {
 		videoFile->seekg(currentPos,videoFile->beg);
 		switch (i) {
 		case 1:
 			GUIDCurrentComponentSize = 4;
 			break;
 		case 2:
 			GUIDCurrentComponentSize = 2;
 			break;
 		case 3:
 			GUIDCurrentComponentSize = 2;
 			break;
 		case 4:
 			GUIDCurrentComponentSize = 2;
 			break;
 		case 5:
 			GUIDCurrentComponentSize = 6;
 			break;
 		}
 		 videoFile->read((char*)&currentData,GUIDCurrentComponentSize);
 		 result += QString::number(currentData, 16).toUpper();
 		 if(GUIDCurrentComponentSize != 6)
 			 result += "-";
 		 currentPos += GUIDCurrentComponentSize;
 		 currentData = 0;
 	 }
 	 return result;
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

 unsigned long long int VideoParser::getAsf_WmvSize(QString path)
{
	unsigned long long int size = 0;
	fstream videoFile;
	videoFile.open(path.toStdString().c_str(), videoFile.binary | videoFile.in);
	_uint64 currentObjectAdrres = HEADER_OBJECT_DATA_SIZE;
	_uint64 offset = 0;
	_uint64 headerObjectSize = 0;
	uint id = 0;
	videoFile.seekg(GUID_SIZE, videoFile.beg);
	videoFile.read((char*) &headerObjectSize, 8);
	while(currentObjectAdrres < headerObjectSize )
	{
		id = 0;
		offset = 0;
		videoFile.seekg(currentObjectAdrres, videoFile.beg);
		videoFile.read((char*) &id, 4);
		if(QString::number(id, GUID_SIZE).toUpper() != ASF_File_Properties_Object_GUID_FIRST_COMPONENT)
		{
			videoFile.seekg(currentObjectAdrres + GUID_SIZE, videoFile.beg);
			videoFile.read((char*) &offset, 8);
			currentObjectAdrres += offset;
			continue;
		}
		else
		{
			videoFile.seekg(currentObjectAdrres + FILE_SIZE_OFFSET, videoFile.beg);
			videoFile.read((char*) &size, 8);
			break;
		}
	}
	return size;
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

