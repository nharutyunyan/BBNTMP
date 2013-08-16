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

Producer::Producer(const QVariantList& videoFiles, int start)
{
}

void Producer::updateVideoList(const QVariantList& videoFiles, int start)
{
    m_result.clear();
    qDebug() << "m_result ==  " << m_result;
    m_index = start;
    current = start;
    m_filepath = QDir::home().absoluteFilePath("thumbnails/");
	qDebug() << "m_filepath " << m_filepath;
	m_thumbPng = "-thumb.png";

	for (int i = 0; i < videoFiles.size(); ++ i)
	{
		QVariantMap v = videoFiles[i].toMap();
		if(v["thumbURL"].value<QString>() == "asset:///images/BlankThumbnail.png")
			m_result.append(v["path"].toString());
		else
			m_index++;
	}
	qDebug() << "m_result size() " << m_result.size();
}

void Producer::produce()
{
	//if no more data, emit a finished signal
	int test = m_result.size();
	if (current >= m_result.size()) {
			emit finished();
		} else {
		//do whatever to retrieve the data
		//and then emit a produced signal with the data
		QStringList pathElements = m_result[current].split('/',
				QString::SkipEmptyParts, Qt::CaseSensitive);
		// Each thumbnail should have <videoFileNameWithExtention>-thumb.png format
		QString finalFileName = m_filepath
				+ pathElements[pathElements.size() - 1] + "-" + pathElements[pathElements.size() - 2] + m_thumbPng;

		//create thumbnail
		// increment index before the try block because we want to continue to the next video even if it fails
		++m_index;

		try {
			VideoThumbnailer videoThumbnailer;
			videoThumbnailer.generateThumbnail(
					m_result[current].toUtf8().constData(),
					finalFileName.toUtf8().constData());
		// Indicate to infolistmodel that no thumbnail has been generated, thus don't try to save to json
		} catch (exception& e) {
			std::cerr << "Error: " << e.what() << endl;
			++current;
			emit produced("", utility::INVALID_VIDEO);
			return;
		} catch (...) {
			std::cerr << "General error" << endl;
			++current;
			emit produced("", utility::INVALID_VIDEO);
			return;
		}
		++current;
		emit produced(finalFileName, m_index - 1);
	}
}
