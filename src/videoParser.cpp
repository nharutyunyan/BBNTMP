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
	 QFile videoFile(path);
	 videoFile.open(QIODevice::ReadOnly);

	 if( getVideoHeaderGUID(&videoFile) ==  ASF_Header_Object_GUID)
		 return "asf_wmv";

	 videoFile.seek(8);
	 videoFile.read(ext, 3);
	 if(ext[0] == 'A'&& ext[1] == 'V' && ext[2] == 'I')
		 return "avi";

	 videoFile.seek(4);
	 videoFile.read(ext, 4);
	 unsigned int ftyp_size;
	 if(ext[0] == 'f'&& ext[1] == 't' && ext[2] == 'y' && ext[3] == 'p')
		 return "QuickTime";
	 return "Unknown";
 }

 QString VideoParser::getVideoHeaderGUID(QFile* videoFile)
  {
	 QString result("");
 	 unsigned  long long int currentData = 0;
 	 int QUIDComponentsNumber = 5;
 	 int GUIDCurrentComponentSize = 0;
 	 int currentPos = 0;
 	 for(int i = 1; i <= QUIDComponentsNumber; ++i)
 	 {
 		videoFile->seek(currentPos);
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

	 QFile videoFile(path);
	 videoFile.open(QIODevice::ReadOnly);
	 videoFile.seek(4);
	 videoFile.read((char*)&size, 4);

	 return size;
 }

 unsigned int VideoParser::getQuickTimeFileSize(QString path)
 {
	 unsigned int currentAtomSize;
	 char* atomName = new char[4];
	 char* num = new char[4];

	 QFile videoFile(path);
	 videoFile.open(QIODevice::ReadOnly);
	 videoFile.seek(0);
	 videoFile.read(num, 4);

	 currentAtomSize = charToint(num);

	 videoFile.seek(4);
	 videoFile.read(atomName, 4);

	 while(!(atomName[0] == 'm' && atomName[1] == 'd' && atomName[2] == 'a' && atomName[3] == 't'))
	 {
		 if(currentAtomSize > videoFile.size())
			 return 0;

		 videoFile.seek(currentAtomSize);
		 videoFile.read(num, 4);
		 videoFile.seek(currentAtomSize + 4);
		 videoFile.read(atomName, 4);

		 currentAtomSize += charToint(num);
	 }
	 return currentAtomSize;
}

 unsigned long long int VideoParser::getAsf_WmvSize(QString path)
{
	unsigned long long int size = 0;

	 QFile videoFile(path);
	 videoFile.open(QIODevice::ReadOnly);

	_uint64 currentObjectAdrres = HEADER_OBJECT_DATA_SIZE;
	_uint64 offset = 0;
	_uint64 headerObjectSize = 0;
	uint id = 0;

	 videoFile.seek(GUID_SIZE);
	 videoFile.read((char*) &headerObjectSize, 8);

	while(currentObjectAdrres < headerObjectSize )
	{
		id = 0;
		offset = 0;

		 videoFile.seek(currentObjectAdrres);
		 videoFile.read((char*) &id, 4);

		if(QString::number(id, GUID_SIZE).toUpper() != ASF_File_Properties_Object_GUID_FIRST_COMPONENT)
		{

			videoFile.seek(currentObjectAdrres + GUID_SIZE);
			videoFile.read((char*) &offset, 8);

			currentObjectAdrres += offset;
			continue;
		}
		else
		{
			videoFile.seek(currentObjectAdrres + FILE_SIZE_OFFSET);
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

