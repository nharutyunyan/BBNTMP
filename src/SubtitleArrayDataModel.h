/*
 * SubtitleArrayDataModel.h
 *
 *  Created on: Dec 13, 2013
 *      Author: bmnatsakanyan
 */

#ifndef SUBTITLEARRAYDATAMODEL_H_
#define SUBTITLEARRAYDATAMODEL_H_

#include <bb/cascades/ArrayDataModel>

class SubtitleArrayDataModel : public bb::cascades::ArrayDataModel
{
    Q_OBJECT
    Q_PROPERTY( QString filePath READ filePath WRITE setFilePath )

public:
    SubtitleArrayDataModel(QObject* parent = 0);

    Q_INVOKABLE void downloadSubtitles(const QString& id);

    QString filePath() const;
    void setFilePath(const QString& filePath);

signals:
    void subtitleRecieved();

private:
    void searchSubtitles(const QString& filePath);

private slots:
    void onSubtitleListReceived(const QVariant& data);

private:
    QString m_filePath;
};

#endif /* SUBTITLEARRAYDATAMODEL_H_ */
