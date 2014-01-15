/*
 * SubtitleArrayDataModel.cpp
 *
 *  Created on: Dec 13, 2013
 *      Author: bmnatsakanyan
 */

#include "SubtitleArrayDataModel.h"
#include "SubtitleDownloadManager.h"

SubtitleArrayDataModel::SubtitleArrayDataModel(QObject* parent) : ArrayDataModel(parent)
{
    bool res = connect(SubtitleDownloadManager::getInstance(), SIGNAL(subtitleListReceived(const QVariant&)),
                       this, SLOT(onSubtitleListReceived(const QVariant&)));
    Q_ASSERT(res);
}

QString SubtitleArrayDataModel::filePath() const
{
    return m_filePath;
}

void SubtitleArrayDataModel::setFilePath(const QString& filePath)
{
    if(filePath != m_filePath)
    {
        m_filePath = filePath;
        searchSubtitles(filePath);
    }
}

void SubtitleArrayDataModel::searchSubtitles(const QString& filePath)
{
    SubtitleDownloadManager::getInstance()->searchSubtitles(filePath);
}

void SubtitleArrayDataModel::onSubtitleListReceived(const QVariant& data)
{
	if(data.toMap()["status"].toString() == "401 Unauthorized") {
		searchSubtitles(m_filePath);
		return;
	}
    QVariantMap dataMap = data.toMap();
    QVariantList dataList = dataMap["data"].toList();
    QVariant movieItem;
    Q_FOREACH(movieItem, dataList)
    {
        if(movieItem.toMap()["SubFormat"].toString() == "srt")
            append(movieItem);
    }
    emit subtitleRecieved();
}

void SubtitleArrayDataModel::downloadSubtitles(const QString& id)
{
    SubtitleDownloadManager::getInstance()->downloadSubtitle(id, m_filePath);
}
