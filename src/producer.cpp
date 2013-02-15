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

Producer::Producer()
    : m_index(0)
 {
	QDir dir;
	dir.mkpath("data/thumbnails/");
	m_filepath = dir.absolutePath() + "/data/thumbnails/";
	m_thumbPng = "-thumb.png";

	QStringList filters;
	filters << "*.mp4";
	filters << "*.avi";
	utility::FileSystemUtility::getEntryListR("/accounts/1000/shared/videos",
			filters, m_result);
}

void Producer::produce()
{
	//do whatever to retrieve the data
	//and then emit a produced signal with the data
	QStringList pathElements = m_result[m_index].split('/',
			QString::SkipEmptyParts, Qt::CaseSensitive);
	// Each thumbnail should have <videoFileNameWithExtention>-thumb.png format
	QString finalFileName = m_filepath + pathElements[pathElements.size() - 1]
			+ m_thumbPng;

	//create thumbnail
	try {
		VideoThumbnailer videoThumbnailer;
		videoThumbnailer.generateThumbnail(
				m_result[m_index].toUtf8().constData(),
				finalFileName.toUtf8().constData());
	} catch (exception& e) {
		std::cerr << "Error: " << e.what() << endl;
	} catch (...) {
		std::cerr << "General error" << endl;
	}
	qDebug() << " process data === " << m_index;
	++m_index;

	//if no more data, emit a finished signal
	if (m_index >= m_result.size()) {
		emit finished();
	} else {
		emit produced(finalFileName, m_index - 1);
	}
}
