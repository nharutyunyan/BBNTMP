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
#include <QThreadPool>


class Observer : public QObject
{
	Q_OBJECT
public:
	Observer(QObject* parent);
private:
	void createWatcher();
	QFileSystemWatcher* watcher;
	QThreadPool* threadPool;
	unsigned size;
signals:
	void directoryChanged(const QString&);
	void Complate(QString);
public slots:
	void setNewVideos(QStringList);
	void waitForComplate(const QString&);
};


#endif /* OBSERVER_HPP_ */
