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
	QFileSystemWatcher* watcher;
	std::map<QString, unsigned long long int> m_newVideos;
signals:
	void directoryChanged(const QString&);
	void Complete(QString);
public slots:
	void setNewVideos(QStringList);
	void waitForComplete(const QString&);
};


#endif /* OBSERVER_HPP_ */
