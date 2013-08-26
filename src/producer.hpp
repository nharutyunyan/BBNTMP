#ifndef PRODUCER_HPP_
#define PRODUCER_HPP_

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <bb/cascades/GroupDataModel>
#include "infolistmodel.hpp"

using namespace bb::cascades;

class Producer: public QObject
{
	Q_OBJECT

public:
    Producer(InfoListModel* videoFiles);
    void updateVideoList(InfoListModel* videoFiles);

public slots:
    void produce();
signals:
    void produced(QString data, QVariantList index);
    void finished();

private:
	GroupDataModel m_result;
	QString m_filepath;
	QString m_thumbPng;
};
#endif /* PRODUCER_HPP_ */
