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
	//createWatcher();
	QObject::connect(this, SIGNAL(directoryChanged(const QString&)), this->parent(),
						SLOT(getVideoFiles()));
	QObject::connect(this, SIGNAL(Complete(QString)), this->parent(),
								SLOT(fileComplete(QString)));
}


void Observer::createWatcher()
{
	QStringList paths;

	//Phone storage
	FileSystemUtility::getSubFolders("/accounts/1000/shared/videos", paths);
	FileSystemUtility::getSubFolders("/accounts/1000/shared/camera", paths);
	FileSystemUtility::getSubFolders("/accounts/1000/shared/downloads", paths);

	//SD card storage
	FileSystemUtility::getSubFolders("/accounts/1000/removable/sdcard/videos", paths);
	FileSystemUtility::getSubFolders("/accounts/1000/removable/sdcard/camera", paths);
	FileSystemUtility::getSubFolders("/accounts/1000/removable/sdcard/downloads", paths);
	//FileSystemUtility::getSubFolders("/accounts/1000/removable/sdcard",paths);

	watcher->addPaths(paths);
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
		if(m_newVideos[path] == 0)
		{
			if(videoFile.size() == 0)
				return;
			if(parser.getVideoSize(path) == 0)
				return;
			m_newVideos[path] = parser.getVideoSize(path);
		}
		if(videoFile.size() / m_newVideos[path] > 0.9)
		{
			emit Complete(path);
			watcher->removePath(path);
			m_newVideos.erase(path);
		}
	}
}

void Observer::setNewVideos(QStringList newVideos)
{
	for(QStringList::iterator it = newVideos.begin(); it != newVideos.end(); ++it)
	{
		watcher->addPath(*it);
		m_newVideos[*it] = 0;
		waitForComplete(*it);
	}
}

