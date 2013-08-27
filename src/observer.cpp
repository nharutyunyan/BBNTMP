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


Observer::Observer(QObject* parent): QObject(parent), size(0)
{
	threadPool = new QThreadPool();
	createWatcher();
	QObject::connect(this, SIGNAL(directoryChanged(const QString&)), this->parent(),
						SLOT(getVideoFiles(const QString&)));
	QObject::connect(this, SIGNAL(Complate(QString)), this->parent(),
								SLOT(fileComplate(QString)));
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
					SLOT(waitForComplate(const QString & )));
}

void Observer::waitForComplate(const QString& path)
{
	QFile videoFile(path.toStdString().c_str());
	VideoParser parser;
	if(size == 0)
		size = parser.getVideoSize(path);
	if(videoFile.size()/size > 0.9)
	{
		emit Complate(path);
		watcher->removePath(path);
		size = 0;
	}
}

void Observer::setNewVideos(QStringList newVideos)
{
	for(QStringList::iterator it = newVideos.begin(); it != newVideos.end(); ++it)
	{
		watcher->addPath(*it);
	}
}

