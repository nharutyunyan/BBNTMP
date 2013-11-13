/*
 * InfoListModel.h
 * Data model for the video list view
 */

#ifndef InfoListModel_HPP_
#define InfoListModel_HPP_

#include <QObject>
#include <QString>
#include <QVariant>
#include <QMetaType>
#include <bb/cascades/GroupDataModel>

#include "moviedecoder.hpp"
#include "observer.hpp"
#include "utility.hpp"
#include "ParalellWorker.hpp"

class Producer;
/*
 * Mutable list model implementation
 */
class InfoListModel : public bb::cascades::GroupDataModel
{
    Q_OBJECT

public:

    static QStringList const getVideoFileList();

    /*
     * Convenience method for loading data from JSON file.
     *
     * @param file_name  file to load
     */
    Q_INVOKABLE void load();

    Q_INVOKABLE void saveData();

    /*
     * Convenience method to read the model data.
     *
     * @param ix  index of the list item
     * @param fld_name  name of data field
     */
    Q_INVOKABLE QVariant value(QVariantList ix, const QString &fld_name);

    /*
     * Convenience method to set the model data.
     *
     * @param ix  index of the list item
     * @param fld_name  name of data field
     * @param val  new value
     */
    Q_INVOKABLE void setValue(QVariantList ix, const QString &fld_name, const QVariant &val);

    /*
     * Method to set the selected index when the list selection was changed by user.
     *
     * @param index The selected item's index
     */
    Q_INVOKABLE void setSelectedIndex(QVariantList index);

    /*
     * Gets the path of the video which was selected by user.
     */
    Q_INVOKABLE QString getSelectedVideoPath();

    /*
     * Converts the specified amount of milliseconds to a formatted time (hh:mm:ss).
     *
     * @param msecs The amount of milliseconds to be converted.
     * @TODO Move this function to some utility class.
     */
    Q_INVOKABLE QString getFormattedTime(int msecs);

    Q_INVOKABLE void setVideoPosition(int);

    Q_INVOKABLE int getVideoPosition();

    Q_INVOKABLE int getWidth();

    Q_INVOKABLE int getHeight();

    Q_INVOKABLE QVariantList getVideoPosition(QString item);

    Q_INVOKABLE QString getVideoTitle();

    Q_INVOKABLE InfoListModel* get();

    Q_INVOKABLE QVariantList getSelectedIndex();

    Q_INVOKABLE int getIntIndex(QVariantList index);

    Q_INVOKABLE int deleteVideos();

    QString folderFieldName(QString path);

    Q_INVOKABLE void addToSelected(QVariantList index);

    Q_INVOKABLE int getButtonVisibility(QString folderName);

    Q_INVOKABLE void clearSelected();

    Q_INVOKABLE QVariantList getFavorites();

    Q_INVOKABLE QVariantList getFrameVideos();

    Q_INVOKABLE QString getFirstFolder();

    Q_INVOKABLE QString getSelectedVideoThumbnail();

    Q_INVOKABLE void markSelectedAsWatched();

    Q_INVOKABLE int addToFavorites();

    Q_INVOKABLE int removeFromFavorites();

    Q_INVOKABLE QVariantList getRealIndex(QVariantList index);

    Q_INVOKABLE void prepareForPlay(QVariantList indexPath);

    Q_INVOKABLE bool isPlayable(QVariantList indexPath);

    Q_INVOKABLE QString getVideoDuration();


public:
    InfoListModel(QObject* parent = 0);
    virtual ~InfoListModel();
    void clearAddedVideos();

public slots:
    void consume(QString filename, QString path);
    void onMetadataReady(const QVariantMap& data);
    void onVideoFileListComplete(QStringList result);
    void onAllMetadataRead();
    void getVideoFiles();
    void fileComplete(QString);
    void readMetadata(QString);
    void checkVideosWaitingThumbnail();
    void markAsDamaged(QString path);
    signals:
        void consumed();
        void finished();
        void finishedThumbnailGeneration();
        void notifyObserver(QStringList);
        void setData(QString);
        void produce();
        void itemMetaDataAdded();

private:
    QThread* m_ParalellWorkerThread;
    utility::MetaDataReader* reader;
    ParalellWorker* paralellWorker;
    QVariantList m_selectedIndex;
    QString m_file;
    Producer* m_producer;
    QThread* m_producerThread;
    static MovieDecoder movieDecoder;
    Observer* observer;
    QList<QVariantList> m_currentSelectionList;
    QSet<QString> addedVideos;
    QVariantList videosWaitingThumbnail;

    void prepareToStart();
    void updateListWithDeletedVideos(const QStringList& result);
    QVariantMap writeVideoMetaData(QString);
};


#endif /* InfoListModel_HPP_ */
