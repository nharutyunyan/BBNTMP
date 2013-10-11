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

Producer::Producer(InfoListModel* videoFiles)
{
    m_thumbPng = "-thumb.png";
    m_filepath = QDir::home().absoluteFilePath("thumbnails/");
    updateVideoList(videoFiles);
}

void Producer::updateVideoList(InfoListModel* videoFiles)
{
    m_result.clear();

	for (QVariantList indexPath = videoFiles->first(); !indexPath.isEmpty(); indexPath = videoFiles->after(indexPath))
	{
		QVariantMap v = videoFiles->data(indexPath).toMap();
		if(v["thumbURL"].value<QString>() == "asset:///images/BlankThumbnail.png") {
		    v["indexPath"] = indexPath;
			m_result.insert(v);
		}
	}
}

void Producer::produce()
{
	//if no more data, emit a finished signal
	if (m_result.isEmpty()) {
			emit finishedCurrentVideos();
		} else {
		    QVariantMap v = m_result.data(m_result.last()).toMap();
		    m_result.removeAt(m_result.last());
		    QVariantList indexPath = v["indexPath"].toList();

		QStringList pathElements = v["path"].toString().split('/',
				QString::SkipEmptyParts, Qt::CaseSensitive);
		// Each thumbnail should have <videoFileNameWithExtention>-thumb.png format
		QString finalFileName = m_filepath
				+ pathElements[pathElements.size() - 1] + "-" + pathElements[pathElements.size() - 2] + m_thumbPng;

		//create thumbnail
		try {
			VideoThumbnailer videoThumbnailer;
			videoThumbnailer.generateThumbnail(
			        v["path"].toString(),
					finalFileName.toUtf8().constData());
		// Indicate to infolistmodel that no thumbnail has been generated, thus don't try to save to json
		} catch (exception& e) {
			std::cerr << "Error: " << e.what() << endl;
			emit produced("", QVariantList());
			return;
		} catch (...) {
			std::cerr << "General error" << endl;
			emit produced("", QVariantList());
			return;
		}
		emit produced(finalFileName, indexPath);
	}
}
