/**
 * @file utility.cpp
 * @brief Implementation of utility type classes
 */

#include <QDir>
#include <QVariant>

#include "utility.hpp"

namespace utility {

bool FileSystemUtility::getEntryListR(const QString& dir, const QStringList& filters, QStringList& result)
{
	QDir currentDir(dir);
	QDir::setCurrent(dir);
	QStringList currentFileList = QDir::current().entryList(filters, QDir::Files);
	if(!currentFileList.isEmpty())
	{
	    foreach(QString item, currentFileList)
		{
		  result.append(dir + "/" + item);
		}
	}

	QStringList currentDirList = currentDir.entryList(QDir::Dirs);
	foreach(QString subDir, currentDirList)
	{
		if (subDir == "." || subDir == "..")
			continue;

		getEntryListR(dir + "/" + subDir, filters, result);
	}

	return !result.isEmpty();
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

void MetaDataReader::addMetadataReadRequest(QStringList videoFiles)
{
    m_queue.append(videoFiles);
    if(!m_started)
    {
    	m_started = true;
    	readNextMetadata();
    }
}

void MetaDataReader::readNextMetadata()
{
    if (m_queue.isEmpty())
    {
    	m_started = false;
    	m_mediaPlayer.reset();
    	emit allMetadataRead();
    	return; //nothing to do
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
		readNextMetadata();
	}
}

void MetaDataReader::onMetaDataChanged(const QVariantMap& metaData)
{
	//Sometimes we are getting empty data, retry is used as a workaround
	if(metaData.isEmpty() && m_retryCount < MAX_RETRY_COUNT)
	{
		prepareToRead();
	}
	else
	{
		emit metadataReady(metaData);
		readNextMetadata();//switch to the next file
	}
}



} //end of namespace
