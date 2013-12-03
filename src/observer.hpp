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

public slots:
	void setNewVideos(const QStringList&);
	void waitForComplete(const QString&);

private:
	void fileComplete( const QString& path);

signals:
	void directoryChanged(const QString&);
	void Complete(QString);

private slots:
	void waitTimerTimeout();

private:
	QFileSystemWatcher* watcher;

	struct NewFileData
	{
		NewFileData() : size(0), onWaitTimer(false) {}

		QElapsedTimer timer;
		_int64 size;
		bool onWaitTimer;
	};

	QMap<QString, NewFileData> m_newVideos;
	QTimer m_waitTimer;

	static const int s_newFileTimeInterval = 60*20; 		// 20 mins;
	static const float s_fileCompletnessTreshold  = 0.9; 	// 90% completeness should be enough.
	static const int s_waitTimerTickTimerout = 2000; 		// every 2 seconds
	static const int s_timerWaitTimeout = 5000; 			// 5 seconds

private:
	void putOnWaitTimer(NewFileData& fileData);
};


#endif /* OBSERVER_HPP_ */
