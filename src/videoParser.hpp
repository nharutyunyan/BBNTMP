/*
 * videoParser.hpp
 *
 *  Created on: Օգս 26, 2013
 *      Author: Trainee
 */

#ifndef VIDEOPARSER_HPP_
#define VIDEOPARSER_HPP_
#include <QString>
#include <QVector>
#include <QFile>

class VideoParser
{
public:
	VideoParser();
	unsigned long long int getVideoSize(QString);

private:
	QString ASF_Header_Object_GUID;
	QString ASF_File_Properties_Object_GUID_FIRST_COMPONENT;
	unsigned int getAviSize(QString);
	unsigned int getQuickTimeFileSize(QString);
	unsigned int charToint(char*);
	unsigned long long int getAsf_WmvSize(QString);
	QString getVideoHeaderGUID(QFile*);
	QString getVideoFormat(QString);
};


#endif /* VIDEOPARSER_HPP_ */
