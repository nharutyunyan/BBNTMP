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


Observer::Observer(QObject* parent): QObject(parent)
{
	createWatcher();
	QObject::connect(this, SIGNAL(directoryChanged(const QString&)), this->parent(),
						SLOT(getVideoFiles(const QString&)));
	QObject::connect(this, SIGNAL(Complete(QString)), this->parent(),
								SLOT(fileComplete(QString)));
}


void Observer::createWatcher()
{
	watcher = new QFileSystemWatcher();
	QStringList paths;
	paths<<("/accounts/1000/shared/videos");
	paths<<("/accounts/1000/shared/camera");
	paths<<("/accounts/1000/shared/downloads");
	watcher->addPaths(paths);
	QObject::connect(watcher, SIGNAL(directoryChanged(const QString&)), this,
					SIGNAL(directoryChanged(const QString&)));
	QObject::connect(watcher, SIGNAL(fileChanged(const QString &)), this,
					SLOT(waitForComplete(const QString & )));
}

void Observer::waitForComplete(const QString& path)
{
	if(m_newVideos.find(path) != m_newVideos.end())
	{
		QFile videoFile(path.toStdString().c_str());
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

