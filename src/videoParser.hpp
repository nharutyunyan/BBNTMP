/*
 * videoParser.hpp
 *
 *  Created on: Օգս 26, 2013
 *      Author: Trainee
 */

#ifndef VIDEOPARSER_HPP_
#define VIDEOPARSER_HPP_
#include <QString>

class VideoParser
{
public:
	unsigned int getVideoSize(QString);
	QString getVideoFormat(QString);
private:
	unsigned int getAviSize(QString);
	unsigned int getQuickTimeFileSize(QString);
	unsigned int charToint(char*);
};


#endif /* VIDEOPARSER_HPP_ */
