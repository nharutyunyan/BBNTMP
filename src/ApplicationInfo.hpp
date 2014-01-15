/*
 * ApplicationInfo.hpp
 *
 *  Created on: Jan 10, 2014
 *      Author: akhanoyan
 */

#ifndef APPLICATIONINFO_HPP_
#define APPLICATIONINFO_HPP_

#include <QString>

class ApplicationInfo {
public:
	ApplicationInfo();
	virtual ~ApplicationInfo();
	static QString getApplicationVersion();
	static QString getJsonName();
	static QString getValidJsonName();

	static const QString APPLICATION_PATH;
	static const QString APP_VERSION_KEY;
	static const QString JSON_FILE_SUFFIX;
	static const QString JSON_EXTENTION;
};

#endif /* APPLICATIONINFO_HPP_ */
