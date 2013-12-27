/*
 * ApplicationInfo.cpp
 *
 *  Created on: Jan 10, 2014
 *      Author: akhanoyan
 */

#include "ApplicationInfo.hpp"
#include <QDir>
#include <QTextStream>
#include <QStringList>

const QString ApplicationInfo::APP_VERSION_KEY = "Application-Version:";
const QString ApplicationInfo::JSON_FILE_SUFFIX = "videoInfoList_";
const QString ApplicationInfo::JSON_EXTENTION = ".json";
const QString ApplicationInfo::APPLICATION_PATH = QDir::home().absoluteFilePath("");

ApplicationInfo::ApplicationInfo() {
}

ApplicationInfo::~ApplicationInfo() {
}

QString ApplicationInfo::getApplicationVersion()
{
	QString version;
	// Get the version of the app
	// The version in the MANIFEST.MF file is the one that the app was signed with.
	// The version in bar-descriptor.xml is not accurate when build from command line
	QString path = APPLICATION_PATH + "/../app/META-INF/MANIFEST.MF";
	QFile textfile(path);
	if (textfile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		QTextStream stream(&textfile);
		QString line;
		do {
			line = stream.readLine();
			if (line.startsWith(APP_VERSION_KEY)) {
				version = line.remove(APP_VERSION_KEY, Qt::CaseSensitive);
				break;
			}
		} while (!line.isNull());
	}

	if (version.isEmpty()) {
		version = "Unknown"; // Should not happen so no need to localise
	}
	return version;
}

QString ApplicationInfo::getJsonName()
{
	QStringList list = QDir(APPLICATION_PATH).entryList(QStringList() << "*" + JSON_EXTENTION);
	QString filename = "";

	if(list.size() != 0)
		filename = list[0];
	return filename;
}

QString ApplicationInfo::getValidJsonName()
{
	return JSON_FILE_SUFFIX + getApplicationVersion().trimmed() + JSON_EXTENTION;
}
