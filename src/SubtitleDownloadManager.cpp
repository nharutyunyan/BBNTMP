/*
 * SubtitleDownloadManager.cpp
 *
 *  Created on: Dec 13, 2013
 *      Author: bmnatsakanyan
 */

#include "SubtitleDownloadManager.h"
#include "libmaia/maiaXmlRpcClient.h"

#include <QFile>
#include <QNetworkReply>
#include <QDebug>
#include <zlib.h>

SubtitleDownloadManager* SubtitleDownloadManager::_instance = 0;

const QUrl SubtitleDownloadManager::ADDRESS = QUrl("http://api.opensubtitles.org/xml-rpc");
const QString SubtitleDownloadManager::USERNAME = QString();
const QString SubtitleDownloadManager::PASSWORD = QString();
const QString SubtitleDownloadManager::LANGUAGE = QString("en");
const QString SubtitleDownloadManager::USER_AGENT = QString("OS Test User Agent");

const QString SubtitleDownloadManager::SERVER_INFO_METHOD = QString("ServerInfo");
const QString SubtitleDownloadManager::LOG_IN_METHOD = QString("LogIn");
const QString SubtitleDownloadManager::LOG_OUT_METHOD = QString("LogOut");
const QString SubtitleDownloadManager::SEARCH_SUBTITLES_METHOD = QString("SearchSubtitles");
const QString SubtitleDownloadManager::DOWNLOAD_SUBTITLES_METHOD = QString("DownloadSubtitles");


SubtitleDownloadManager::SubtitleDownloadManager(QObject* parent) : QObject(parent)
{
    m_maiaXmlRpcClient = new MaiaXmlRpcClient(ADDRESS, this);
    logIn();
}

SubtitleDownloadManager::~SubtitleDownloadManager()
{
    logOut();
}

SubtitleDownloadManager* SubtitleDownloadManager::getInstance()
{
    if(_instance == 0) {
        _instance = new SubtitleDownloadManager();
    }
    return _instance;
}

void SubtitleDownloadManager::download()
{
}

quint64 SubtitleDownloadManager::hashCode(const QString& fileName) const
{
    quint64 hash, fileSize;
    QFile file(fileName);

    if(file.open(QIODevice::ReadOnly)) {
        fileSize = file.size();
        file.seek(0);
        hash = fileSize;
        for(quint64 tmp = 0, i = 0; i < 65536 / sizeof(tmp) && file.read((char*) &tmp, sizeof(tmp)); i++, hash += tmp);
        file.seek(qMax((quint64)0, fileSize - 65536));
        for(quint64 tmp = 0, i = 0; i < 65536 / sizeof(tmp) && file.read((char*) &tmp, sizeof(tmp)); i++, hash += tmp);
    }

    return hash;
}

quint64 SubtitleDownloadManager::fileSize(const QString& fileName) const
{
    quint64 size;
    QFile file(fileName);

    if(file.open(QIODevice::ReadOnly)) {
        size = file.size();
    }

    return size;
}

void SubtitleDownloadManager::serverInfoReply(QVariant& data, QNetworkReply*)
{
    if(data.isNull())
        qDebug() << "Server is unreachable";
    else
        qDebug() << "Server is reachable";
}

void SubtitleDownloadManager::logInReply(QVariant& data, QNetworkReply*)
{
    QVariantMap dataMap = data.toMap();
    if(dataMap["status"].toString() == "200 OK") {
        m_token = dataMap["token"].toString();
    }
}

void SubtitleDownloadManager::logOutReply(QVariant& data, QNetworkReply*)
{
    QVariantMap dataMap = data.toMap();
    if(dataMap["status"].toString() == "200 OK") {
        qDebug() << "Successfully logged out";
    }
    else {
        qDebug() << "Failed to log out";
    }
}

void SubtitleDownloadManager::error(int code, const QString& message)
{
    qDebug() << "SubtitleDownloadManager::error code : " << code << ", message : " << message;
}

void SubtitleDownloadManager::serverInfo()
{
    m_maiaXmlRpcClient->call(SERVER_INFO_METHOD,
                             QVariantList(),
                             this, SLOT(serverInfoReply(QVariant&, QNetworkReply*)),
                             this, SLOT(error(int, const QString&)));
}

void SubtitleDownloadManager::searchSubtitles(const QString& fileName)
{
    QVariantList args;
    args << m_token;
    QVariantList movieInfoList;
    QVariantMap movieInfoMap;

    movieInfoMap["sublanguageid"] = "all";
    movieInfoMap["moviehash"] = hashCode(fileName);
    movieInfoMap["moviebytesize"] = fileSize(fileName);
    movieInfoMap["tag"] = QFileInfo(fileName).fileName();

    movieInfoList.append(movieInfoMap);
    QVariant movieInfoListVariant = movieInfoList;
    args << movieInfoListVariant;
    m_maiaXmlRpcClient->call(SEARCH_SUBTITLES_METHOD,
                             args,
                             this, SLOT(searchSubtitlesReply(QVariant&, QNetworkReply*)),
                             this, SLOT(error(int, const QString&)));
}

void SubtitleDownloadManager::logIn()
{
    m_maiaXmlRpcClient->call(LOG_IN_METHOD,
                             QVariantList() << USERNAME << PASSWORD << LANGUAGE << USER_AGENT,
                             this, SLOT(logInReply(QVariant&, QNetworkReply*)),
                             this, SLOT(error(int, const QString&)));
}

void SubtitleDownloadManager::logOut()
{
    m_maiaXmlRpcClient->call(LOG_OUT_METHOD,
                             QVariantList() << m_token,
                             this, SLOT(logOutReply(QVariant&, QNetworkReply*)),
                             this, SLOT(error(int, const QString&)));
}

void SubtitleDownloadManager::searchSubtitlesReply(QVariant& data, QNetworkReply*)
{
    emit subtitleListReceived(data);
    qDebug() << "Subtitle::searchSubtitlesReply data : " << data;
}

void SubtitleDownloadManager::downloadSubtitle(const QString& id, const QString& filePath)
{
    QVariantList args;
    args << m_token;
    QVariantList idList;
    idList << id;
    QVariant idsVariant = idList;
    args << idsVariant;
    QNetworkReply* reply = m_maiaXmlRpcClient->call(DOWNLOAD_SUBTITLES_METHOD,
                             args,
                             this, SLOT(downloadSubtitleReply(QVariant&, QNetworkReply*)),
                             this, SLOT(error(int, const QString&)));
    m_replyPtrMap[reply] = filePath;
}

void SubtitleDownloadManager::downloadSubtitleReply(QVariant& data, QNetworkReply* reply)
{
    QVariantMap dataMap = data.toMap();
    QVariantList dataList = dataMap["data"].toList();
    QVariant item;

    QByteArray byteArray;
    int a = m_replyPtrMap[reply].lastIndexOf('.', -1);
    QString fileName = m_replyPtrMap[reply];
    fileName.truncate(a);
    fileName += ".srt";
    QFile file(fileName);
    file.open(QIODevice::WriteOnly | QIODevice::Text);
    QTextStream out(&file);

    if(!dataList.isEmpty()) {
        byteArray.append(dataList[0].toMap()["data"].toString());
        byteArray = QByteArray::fromBase64(byteArray);
        byteArray = gzipDecompress(byteArray);
        QString result = QString::fromUtf8(byteArray.data(), byteArray.size());
        out << result;
        emit subtitleDownloadFinished(m_replyPtrMap.value(reply));
    }

    file.close();
}

QByteArray SubtitleDownloadManager::gzipDecompress( QByteArray compressData )
{
	//decompress GZIP data
	//strip header and trailer
	int sArray[4];
	for(int i = 0; i < 4; i++) { // gzip stores data size in lasr 4 bytes
		sArray[i] = compressData[compressData.length() - 4 + i];
		if(sArray[i] < 0)
			sArray[i] += 256;
	}
	int buffersize = (sArray[3] << 24) + (sArray[2] << 16) + (sArray[1] << 8) + sArray[0];

	compressData.remove(0, 10);
	compressData.chop(8);

	quint8 *buffer = new quint8[buffersize];

	z_stream cmpr_stream;
	cmpr_stream.next_in = (unsigned char *)compressData.data();
	cmpr_stream.avail_in = compressData.size();
	cmpr_stream.total_in = 0;

	cmpr_stream.next_out = buffer;
	cmpr_stream.avail_out = buffersize;
	cmpr_stream.total_out = 0;

	cmpr_stream.zalloc = Z_NULL;
	cmpr_stream.zfree = Z_NULL;

	if( inflateInit2(&cmpr_stream, -8 ) != Z_OK) {
		qDebug() << "cmpr_stream error!";
	}

	QByteArray uncompressed;
	do {
		int status = inflate( &cmpr_stream, Z_SYNC_FLUSH );

		if(status == Z_OK || status == Z_STREAM_END) {
			uncompressed.append(QByteArray::fromRawData(
					(char *)buffer,
					buffersize - cmpr_stream.avail_out));
			cmpr_stream.next_out = buffer;
			cmpr_stream.avail_out = buffersize;
		} else {
			inflateEnd(&cmpr_stream);
		}
		if(status == Z_STREAM_END) {
			inflateEnd(&cmpr_stream);
			break;
		}
	} while(cmpr_stream.avail_out == 0);

	delete [] buffer;
	return uncompressed;
}
