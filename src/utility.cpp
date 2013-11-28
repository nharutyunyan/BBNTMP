/**
 * @file utility.cpp
 * @brief Implementation of utility type classes
 */

#include "utility.hpp"

#include <QDir>
#include <QVariant>

#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>


namespace utility {

bool FileSystemUtility::getEntryListR(const QString& dir, const QStringList& filters, QStringList& result)
{
	QDir currentDir(dir);

	readFileList(dir, filters, result);

	QStringList currentDirList = currentDir.entryList(QDir::Dirs);
	foreach(QString subDir, currentDirList)
	{
		if (subDir == "." || subDir == "..")
			continue;

		getEntryListR(dir + "/" + subDir, filters, result);
	}

	return !result.isEmpty();
}

bool FileSystemUtility::getSubFolders(const QString& dir, QStringList& result)
{
	result.append(dir);
	QDir currentDir(dir);
	QDir::setCurrent(dir);
	QStringList currentDirList = currentDir.entryList(QDir::Dirs);

	foreach(QString subDir, currentDirList)
	{
		if (subDir == "." || subDir == "..")			continue;

		getSubFolders(dir + "/" + subDir,result);
	}

	return !result.isEmpty();
}

void FileSystemUtility::readFileList(const QString& dir, const QStringList& filters, QStringList& result)
{
	DIR* dirp;
	dirp = opendir(dir.toLocal8Bit().data());
	if( dirp != NULL )
	{
		struct dirent* direntp;
		for(direntp = readdir( dirp ); direntp != NULL; direntp = readdir( dirp ))
		{
			QString fileName = dir + "/" + QString::fromLocal8Bit((char*)direntp->d_name);

			QFileInfo info(fileName);
			if(info.isFile())
			{
				for(int i = 0; i < filters.size(); ++i)
				{
					if(fileName.endsWith(filters.at(i), Qt::CaseInsensitive))
					{
						result << fileName;
						break;
					}
				}
			}
		}
		closedir( dirp );
	}
}

MetaDataReader::MetaDataReader(QObject* parent): QObject(parent), m_started(false), m_retryCount(0)
{
	connect(&m_mediaPlayer, SIGNAL(metaDataChanged(const QVariantMap&)), this,
		    SLOT(onMetaDataChanged(const QVariantMap&)));
}

MetaDataReader::~MetaDataReader()
{
	//Free the resources
	m_mediaPlayer.reset();
}

void MetaDataReader::setData(QString videoFile)
{
    m_queue.append(videoFile);
    if(!m_started)
    {
       	m_started = true;
       	readNextMetadata();
    }
}

void MetaDataReader::readNextMetadata()
{
    if (m_queue.isEmpty()) {
        //added to start thread
        m_started = false;
        m_mediaPlayer.reset();
        emit allMetaDataRead();
        return;
    }
    m_currentVideoUrl = m_queue.dequeue();
    m_retryCount = 0;
    prepareToRead();
}

void MetaDataReader::prepareToRead()
{
	++m_retryCount;
	m_mediaPlayer.reset();
	m_mediaPlayer.setSourceUrl(m_currentVideoUrl);

	if (m_mediaPlayer.prepare() != bb::multimedia::MediaError::None)
	{
		qDebug() << "Error during metadata reading from " << m_currentVideoUrl << "\n";
		emit videoNotSupported(m_currentVideoUrl);
		readNextMetadata();
	}
}

void MetaDataReader::onMetaDataChanged(const QVariantMap& metaData)
{

	if(metaData.value(bb::multimedia::MetaData::Width).toInt() > 0
		&& metaData.value(bb::multimedia::MetaData::Height).toInt() > 0
		&& metaData.value(bb::multimedia::MetaData::Duration).toInt() > 0)
	{
		emit metadataReady(metaData);
		readNextMetadata();
	}
}

void MetaDataReader::addToQueue(QString videoUrl)
{
    m_queue.push_front(videoUrl);
}

} //end of namespace
