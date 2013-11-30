/*
 * observer.cpp
 *
 *  Created on: Օգս 26, 2013
 *      Author: Trainee
 */

#include "observer.hpp"
#include "videoParser.hpp"
#include <QStringList>
#include <QFile>
#include <QDebug>
#include <QThread>

using namespace utility;

Observer::Observer(QObject* parent): QObject(parent)
{
	watcher = new QFileSystemWatcher();
	QObject::connect(this, SIGNAL(directoryChanged(const QString&)), this->parent(),
						SLOT(getVideoFiles(QString)));
	QObject::connect(this, SIGNAL(Complete(QString)), this->parent(),
						SLOT(fileComplete(QString)));
	QObject::connect(&m_waitTimer, SIGNAL(timeout()), this, SLOT(waitTimerTimeout()));

	m_waitTimer.setInterval(2000); //check each 2 seconds
}

void Observer::createWatcher()
{
	//Phone storage
	watcher->addPath("/accounts/1000/shared/videos");
	watcher->addPath("/accounts/1000/shared/camera");
	watcher->addPath("/accounts/1000/shared/downloads");

	//SD card storage
	if(QDir("/accounts/1000/removable/sdcard").exists()) {
		watcher->addPath("/accounts/1000/removable/sdcard/videos");
		watcher->addPath("/accounts/1000/removable/sdcard/camera");
		watcher->addPath("/accounts/1000/removable/sdcard/downloads");
		//FileSystemUtility::getSubFolders("/accounts/1000/removable/sdcard",paths);
	}

	QObject::connect(watcher, SIGNAL(directoryChanged(const QString&)), this,
					SIGNAL(directoryChanged(const QString&)));
	QObject::connect(watcher, SIGNAL(fileChanged(const QString &)), this,
					SLOT(waitForComplete(const QString & )));
}

void Observer::addWatcher(const QString& path)
{
	watcher->addPath(path);
}

void Observer::waitForComplete(const QString& path)
{
	if(m_newVideos.find(path) != m_newVideos.end())
	{
		QFile videoFile(path);
		VideoParser parser;
		if(m_newVideos[path].size == 0)
		{
			if(videoFile.size() == 0)
				return;

			if(parser.getVideoSize(path) <= 0)
			{
				if(!m_waitTimer.isActive())
					m_waitTimer.start();

				m_newVideos[path].size = -1;
				m_newVideos[path].timer.start();
				return;
			}

			m_newVideos[path].size = parser.getVideoSize(path);
		}

		if(m_newVideos[path].size == -1)
		{
			m_newVideos[path].timer.start();
		}
		else if(videoFile.size() / m_newVideos[path].size > 0.9)
		{
			fileComplete(path);
		}
	}
}

void Observer::setNewVideos(const QStringList& newVideos)
{
	for(QStringList::const_iterator it = newVideos.begin(); it != newVideos.end(); ++it)
	{
		watcher->addPath(*it);
		m_newVideos[*it].size = 0;
		waitForComplete(*it);
	}
}

void Observer::waitTimerTimeout()
{
	for(QMap<QString, NewFileData>::iterator it = m_newVideos.begin(); it != m_newVideos.end(); ++it)
	{
		if(it.value().size == -1 && it.value().timer.hasExpired(5000)) // wait 5 seconds
		{
			fileComplete(it.key());
			waitTimerTimeout();
			return;
		}
	}
}

void Observer::fileComplete( const QString& path)
{
	emit Complete(path);
	watcher->removePath(path);
	m_newVideos.remove(path);
	if(m_newVideos.empty() && m_waitTimer.isActive())
		m_waitTimer.stop();
}
