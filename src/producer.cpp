/**
 * @file producer.cpp
 * @brief Implementation of producer class
 */

#include <QDir>
#include <bb/Application>
#include <QThread>
#include <bps/bps.h>
#include <iostream.h>


#include "utility.hpp"
#include "videothumbnailer.hpp"
#include "producer.hpp"

Producer::Producer(QObject* parent) : QObject(parent)
{
    m_thumbPng = "-thumb.png";
    m_filepath = QDir::home().absoluteFilePath("thumbnails/");
}

void Producer::produce(QString path, int duration)
{
	QStringList pathElements = path.split('/',
			QString::SkipEmptyParts, Qt::CaseSensitive);
	// Each thumbnail should have <videoFileNameWithExtention>-thumb.png format
	QString finalFileName = m_filepath
			+ pathElements[pathElements.size() - 1] + "-" + QString(QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Md5).toHex()) + m_thumbPng;

	//create thumbnail
	bool succssed = false;
	try {
		VideoThumbnailer videoThumbnailer;
		succssed = videoThumbnailer.generateThumbnail(path, finalFileName.toUtf8().constData(), duration);
	// Indicate to infolistmodel that no thumbnail has been generated, thus don't try to save to json
	} catch (exception& e) {
		qDebug() << "Error: " << e.what() << ", path = " << path;
		emit produced("", path);
		succssed = false;
		return;
	} catch (...) {
		qDebug() << "General error, path = " << path;
		emit produced("", path);
		succssed = false;
		return;
	}

	//try one more time
	if(!succssed)
		emit produced("", path);
	else
	{
		qDebug() << "Successfully generated, path = " << path;
		emit produced(finalFileName, path);
	}

}
