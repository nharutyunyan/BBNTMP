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

class Observer : public QObject
{
	Q_OBJECT
public:
	Observer(QObject* parent);
private:
	void createWatcher();
	QFileSystemWatcher* watcher;
	std::map<QString, unsigned int> m_newVideos;
signals:
	void directoryChanged(const QString&);
	void Complate(QString);
public slots:
	void setNewVideos(QStringList);
	void waitForComplate(const QString&);
};


#endif /* OBSERVER_HPP_ */
