#ifndef UTILITY_HPP_
#define UTILITY_HPP_

/**
 * @file utility.hpp
 * @brief Holder for utility routines used in the application
 */

#include <bb/multimedia/MediaPlayer.hpp>

namespace utility
{

// used for error handling
const int INVALID_VIDEO = -1;

/**
 * @brief class FileSystemUtility
 * @details FileSystemUtility is intended to hold utility routines related to file system stuff
 */
class FileSystemUtility
{
public:
	/**
	 * @details getEntryListR get the files list in the specified directory using the specified filters.
	 * for example get all the ".avi" files
	 */
	static bool getEntryListR(const QString& dir, const QStringList& filters, QStringList& result);
};



/**
 * @brief   class MetaDataReader, implements logic of reading metadata from video files
 * @details It sequentially reads metadata of queued vide files, and emits signal with read data.
 */
class MetaDataReader : public QObject
{
	Q_OBJECT

public:

	static const int MAX_RETRY_COUNT = 10;

	MetaDataReader(QObject* parent = 0);
	~MetaDataReader();

	/**
	 * @brief Adds the list of video files to the queue.
	 * @details If the reading process is not started, this function also starts it
	 * @param videoFiles  List of video file paths
	 */

signals:
	void metadataReady(const QVariantMap&);

public slots:
	void onMetaDataChanged(const QVariantMap& metaData);
	void setData(QStringList videoFiles);

private:

	void readNextMetadata();
	void prepareToRead();

	QQueue<QString> m_queue;
	bb::multimedia::MediaPlayer m_mediaPlayer;
	QString m_currentVideoUrl;
	bool m_started;
	int m_retryCount;
};

}//end of namespace


#endif /* UTILITY_HPP_ */
