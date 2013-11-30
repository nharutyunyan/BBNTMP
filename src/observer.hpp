/*
 * observer.hpp
 *
 *  Created on: Օգս 26, 2013
 *      Author: Trainee
 */

#ifndef OBSERVER_HPP_
#define OBSERVER_HPP_
#include <QFileSystemWatcher>
#include <QStringList>
#include <QObject>
#include <QRunnable>
#include <QTimer>
#include <QElapsedTimer>
#include <QMap>
#include <map>

#include "utility.hpp"



class Observer : public QObject
{
	Q_OBJECT
public:
	Observer(QObject* parent);
	void createWatcher();
	void addWatcher(const QString& path);
private:
	void fileComplete( const QString& path);
private:
	QFileSystemWatcher* watcher;

	struct NewFileData
	{
		_int64 size;
		QElapsedTimer timer;
	};

	QMap<QString, NewFileData> m_newVideos;
	QTimer m_waitTimer;
signals:
	void directoryChanged(const QString&);
	void Complete(QString);
public slots:
	void setNewVideos(const QStringList&);
	void waitForComplete(const QString&);
	void waitTimerTimeout();

};


#endif /* OBSERVER_HPP_ */
