/*
 * SubtitleDownloadManager.h
 *
 *  Created on: Dec 13, 2013
 *      Author: bmnatsakanyan
 */

#ifndef SUBTITLEDOWNLOADMANAGER_H_
#define SUBTITLEDOWNLOADMANAGER_H_

#include <QObject>
#include <QUrl>
#include <QVariantList>

class MaiaXmlRpcClient;
class QNetworkReply;

class SubtitleDownloadManager : public QObject
{
    Q_OBJECT
public:
    virtual ~SubtitleDownloadManager();
    static SubtitleDownloadManager* getInstance();
    void download();
    void serverInfo();
    void searchSubtitles(const QString& fileName);
    void logIn();
    void logOut();
    void downloadSubtitle(const QString& id, const QString& fileName);

private:
    SubtitleDownloadManager(QObject* parent = 0);
    quint64 hashCode(const QString& fileName) const;
    quint64 fileSize(const QString& fileName) const;
    QByteArray gzipDecompress(QByteArray compressData);

signals:
    void subtitleListReceived(const QVariant&);
    void subtitleDownloadFinished(const QString&);

private slots:
    void serverInfoReply(QVariant& data, QNetworkReply* reply);
    void logInReply(QVariant& data, QNetworkReply* reply);
    void logOutReply(QVariant& data, QNetworkReply* reply);
    void searchSubtitlesReply(QVariant& data, QNetworkReply* reply);
    void downloadSubtitleReply(QVariant& data, QNetworkReply* reply);
    void error(int code, const QString& message);

private:
    static SubtitleDownloadManager *_instance;
    MaiaXmlRpcClient* m_maiaXmlRpcClient;
    QString m_token;
    QMap<QNetworkReply*, QString> m_replyPtrMap;

    static const QUrl ADDRESS;          // API server domain
    static const QString USERNAME;      // Username to log in
    static const QString PASSWORD;      // Password to log in
    static const QString LANGUAGE;      // Language used in error codes and so on
    static const QString USER_AGENT;    // Registered user agent to communicate with the server

    // XMLRPC method names
    static const QString SERVER_INFO_METHOD;
    static const QString LOG_IN_METHOD;
    static const QString LOG_OUT_METHOD;
    static const QString SEARCH_SUBTITLES_METHOD;
    static const QString DOWNLOAD_SUBTITLES_METHOD;
};

#endif /* SUBTITLEDOWNLOADMANAGER_H_ */
