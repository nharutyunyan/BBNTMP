#ifndef PRODUCER_HPP_
#define PRODUCER_HPP_

#include <QObject>
#include <QStringList>
#include <QVariantList>

class Producer: public QObject
{
	Q_OBJECT

public:
    Producer(const QVariantList& videoFiles, int);
    void updateVideoList(const QVariantList& videoFiles, int start);

public slots:
    void produce();
signals:
    void produced(QString data, int index);
    void finished();

private:
	QStringList m_result;
	QString m_filepath;
	QString m_thumbPng;
	int m_index;
	int current;

};
#endif /* PRODUCER_HPP_ */
