// List with context menu project template
#include "infolistmodel.hpp"
#include <iostream.h>

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <iostream>

#include <QSet>
#include <QVariantList>
#include "videothumbnailer.hpp"
#include "producer.hpp"

#include <bb/data/JsonDataAccess>

using namespace bb::cascades;
using namespace utility;

//TODO: Move the data handling (storage/loading) into separate module  - DataManager
//View model should be simple, and just keep the list for Views
MovieDecoder InfoListModel::movieDecoder;


QStringList const InfoListModel::getVideoFileList() {
	QStringList filters, result;

	//BB10 presumably supported formats: 3GP, 3GP2, ASF, AVI, F4V, M4V, MKV, MOV, MP4, MPEG4, WMV
	filters << "*.avi" << "*.mp4" << "*.3gp" << "*.3g2" << "*.asf" << "*.wmv"
			<< "*.mov" << "*.m4v" << "*.f4v" << "*.mkv"; //these are the formats the don't crash the app.

	//Phone storage
	FileSystemUtility::getEntryListR("/accounts/1000/shared/videos", filters, result);
	FileSystemUtility::getEntryListR("/accounts/1000/shared/camera", filters, result);
	FileSystemUtility::getEntryListR("/accounts/1000/shared/downloads", filters, result);

	//SD card storage
	if(QDir("/accounts/1000/removable/sdcard").exists())
			FileSystemUtility::getEntryListR("/accounts/1000/removable/sdcard", filters, result);

	return result;
}


InfoListModel::InfoListModel(QObject* parent)
: m_selectedIndex(QVariantList())
, m_file(QDir::home().absoluteFilePath("videoInfoList.json"))
{
    setSortingKeys(QStringList() << "folder" << "title");
    setGrouping(ItemGrouping::ByFullValue);

    qDebug() << "Creating InfoListModel object:" << this;
    setParent(parent);
    m_producer = new Producer(this);
	QObject::connect(this, SIGNAL(consumed()), m_producer, SLOT(produce()));
	QObject::connect(m_producer, SIGNAL(produced(QString, QString)), this,
			SLOT(consume(QString, QString)));

    m_producerThread  = new QThread();
	m_producer->moveToThread(m_producerThread);

	//when producer thread is started, start to produce
	QObject::connect(m_producerThread, SIGNAL(started()), parent,
					SLOT(loadingIndicatorStart()));
	QObject::connect(m_producerThread, SIGNAL(started()), m_producer,
			SLOT(produce()));
	QObject::connect(m_producer, SIGNAL(finishedCurrentVideos()), this,
					SLOT(checkVideosWaitingThumbnail()));

	QObject::connect(this, SIGNAL(finishedThumbnailGeneration()), m_producerThread,
			SLOT(quit()));
	QObject::connect(this, SIGNAL(finishedThumbnailGeneration()), parent,
				SLOT(onThumbnailsGenerationFinished()));

	m_mediaPlayerThread = new QThread();
	observer = new Observer(this);
	QObject::connect(this, SIGNAL(notifyObserver(QStringList)), observer,
					SLOT(setNewVideos(QStringList)));
	QObject::connect(this, SIGNAL(notifyObserver(QStringList)), parent,
					SLOT(loadingIndicatorStart()));
	reader = new MetaDataReader();
	reader->moveToThread(m_mediaPlayerThread);
	QObject::connect(reader, SIGNAL(metadataReady(const QVariantMap& )), this, SLOT(onMetadataReady(const QVariantMap& )));
	QObject::connect(reader, SIGNAL(allMetaDataRead()), this, SLOT(onAllMetadataRead()));
	QObject::connect(this, SIGNAL(setData(QStringList )), reader, SLOT(setData(QStringList )));
	QObject::connect(reader, SIGNAL(videoNotSupported(QString)), this, SLOT(markAsDamaged(QString)));

	prepareToStart();

	paralellWorker  = new ParalellWorker();
	QObject::connect(paralellWorker, SIGNAL(VideoFileListComplete(QStringList)), this,
			SLOT(onVideoFileListComplete(QStringList)));

	m_ParalellWorkerThread = new QThread();
	paralellWorker->moveToThread(m_ParalellWorkerThread);
	QObject::connect(m_ParalellWorkerThread, SIGNAL(started()), paralellWorker,
					SLOT(getVideoFileList()));
	m_ParalellWorkerThread->start();

}

void InfoListModel::checkVideosWaitingThumbnail()
{
	if(videosWaitingThumbnail.empty())
	{
		emit finishedThumbnailGeneration();
	}
	else
	{
		insertList(videosWaitingThumbnail);
		videosWaitingThumbnail.clear();
		saveData();
		m_producer->updateVideoList(this);
		emit consumed();
	}
}

void InfoListModel::consume(QString filename, QString path)
{
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		if (v["path"].toString() == path) {
			// add generated thumbnail to list model
			setValue(indexPath, "thumbURL", "file://" + filename);
			//when finished processing emit a consumed signal
			emit consumed();
			saveData();
			return;
		}
	}
	emit consumed();
}

void InfoListModel::getVideoFiles()
{
	QStringList result, newVideos;
	result = getVideoFileList();
	QSet<QString> set;

	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		set.insert(v["path"].toString());
	}

	for (QStringList::const_iterator i = result.begin(); i != result.end(); ++i) {
		bool videoExist = set.contains(*i);
		if(!videoExist)
		{
			if(!addedVideos.contains(*i))
			{
				newVideos.push_back(*i);
				addedVideos.insert(*i);
			}
		}

	}
	updateListWithDeletedVideos(result);
	if(!newVideos.isEmpty())
	{
		emit notifyObserver(newVideos);
	}
}

void InfoListModel::onVideoFileListComplete(QStringList result) {
	QStringList newVideos;
	QSet<QString> set;

	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		set.insert(v["path"].toString());
	}

	for (QStringList::const_iterator i = result.begin(); i != result.end(); ++i) {
		bool videoExist = set.contains(*i);
		if(!videoExist)
		{
			if(!addedVideos.contains(*i))
			{
				newVideos.push_back(*i);
				addedVideos.insert(*i);
			}
		}
	}
	updateListWithDeletedVideos(result);

	if(!newVideos.isEmpty())
	{
		emit notifyObserver(newVideos);
	} else {
		onAllMetadataRead();
	}

	observer->createWatcher();
}

void InfoListModel::clearAddedVideos()
{
	addedVideos.clear();
}

void InfoListModel::fileComplete(QString path)
{
	QStringList new_;
	new_<<(path);
	updateListWithAddedVideos(new_);
}

void InfoListModel::prepareToStart()
{
	QDir dir;
	if(!dir.exists(QDir::home().absoluteFilePath("thumbnails/")))
	{
		dir.mkpath("data/thumbnails/");
	}
	QFile file(m_file);
	if(!file.exists())
	{
		file.open(QIODevice::ReadWrite | QIODevice::Text);
	}
	load();
}

void InfoListModel::updateListWithAddedVideos(const QStringList& result)
{
	// Slight improvement to the video exists check that was below,
	QSet<QString> set;
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		set.insert(v["path"].toString());
	}

	for (QStringList::const_iterator i = result.begin(); i != result.end(); ++i) {
		if (!set.contains(*i)) {
			//add new video to json data
			QVariantMap val;
			val["path"] = *i;
			val["position"] = "0";
			//Get the last path component and set it as title. Might be changed in future to get title from metadata
			QStringList pathElements = i->split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
			val["title"] = pathElements[pathElements.size()-1];
			// Add the thumbnail URL to the JSON file
			val["thumbURL"] = "asset:///images/BlankThumbnail.png";
			// Add folder
			val["folder"] = folderFieldName(val["path"].toString());
			val["isWatched"] = false;
			insert(val);
			waitingVideosBuffer<<(*i);

			QString VideoDir = *i;
			VideoDir.truncate(VideoDir.lastIndexOf('/',-1,Qt::CaseSensitive));
			observer->addWatcher(VideoDir);
		}
	}
	readMetadatas();
}

void InfoListModel::updateListWithDeletedVideos(const QStringList& result)
 {
	QDir dir;
	QString thumbnailDir = dir.homePath() + "/thumbnails/";
	dir.cd(thumbnailDir);

	QSet<QString> result_set (result.toSet());

	QList<QVariantList> value;

	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v (data(indexPath).toMap());
		if (!result_set.contains(v["path"].toString())) {
			// if the video does not exist any more remote its thumbnail as well
			addedVideos.remove(v["path"].toString());
			value.push_back(indexPath);
		}
	}

	while(!value.isEmpty()) {
		QString tName = data(value.last()).toMap()["thumbURL"].toString();
		dir.remove(tName.mid(7, tName.length() - 7));
		removeAt(value.last());
		value.pop_back();
	}
}

InfoListModel::~InfoListModel()
{
	delete m_producer;
	delete m_producerThread;
	delete observer;
	delete m_mediaPlayerThread;
	delete reader;
    qDebug() << "Destroying InfoListModel object:" << this;
}

void InfoListModel::load()
{
    clear();
    bb::data::JsonDataAccess jda;
    QVariantList vList = jda.load(m_file).toList();
    insertList(vList);
    if (jda.hasError()) {
        bb::data::DataAccessError error = jda.error();
        qDebug() << m_file << "JSON loading error: " << error.errorType() << ": " << error.errorMessage();
    }
    else {
        qDebug() << m_file << "JSON data loaded OK!";
    }
}

void InfoListModel::saveData()
{
    bb::data::JsonDataAccess jda;
    QVariantList vList;
    for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
        vList.push_front(data(indexPath));
    }
    jda.save(QVariant(vList), m_file);
    if (jda.hasError()) {
        bb::data::DataAccessError error = jda.error();
        qDebug() << m_file << "JSON save error: " << error.errorType() << ": " << error.errorMessage();
    }
    else {
        qDebug() << m_file << "JSON data save OK!";
    }
}

void InfoListModel::readMetadatas()
{
	if(!waitingVideosBuffer.empty())
	{
		if(!m_mediaPlayerThread->isRunning())
		{
			m_mediaPlayerThread->start();
		}
		emit setData(waitingVideosBuffer);
		waitingVideosBuffer.clear();
	}
}

void InfoListModel::onMetadataReady(const QVariantMap& val)
{
	//Update the appropriate video info entry
	QString path = val[bb::multimedia::MetaData::Uri].toString();
	QVariantList indexPath = getVideoPosition(path);
	if(path.isEmpty())
	{
		return;
	}
	QVariantMap infoMap;
	infoMap["path"] = path;
	infoMap["position"] = "0";
	//Get the last path component and set it as title. Might be changed in future to get title from metadata
	QStringList pathElements = path.split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
	infoMap["title"] = pathElements[pathElements.size()-1];
	infoMap["thumbURL"] = "asset:///images/BlankThumbnail.png";
	infoMap["folder"] = folderFieldName(infoMap["path"].toString());
	infoMap["duration"] = val.value(bb::multimedia::MetaData::Duration).toString();
	infoMap["width"] = val.value(bb::multimedia::MetaData::Width).toString();
	infoMap["height"] = val.value(bb::multimedia::MetaData::Height).toString();
	infoMap["isWatched"] = false;
	updateItem(indexPath, infoMap);
	emit itemMetaDataAdded();
}

void InfoListModel::markAsDamaged(QString path)
{
	QVariantList indexPath = getVideoPosition(path);
	QVariantMap map = data(indexPath).toMap();
	map["duration"] = "-1";
	updateItem(indexPath, map);
	emit itemMetaDataAdded();
}

void InfoListModel::onAllMetadataRead()
{
    if(!m_producerThread->isRunning()) {
        m_producer->updateVideoList(this);
        m_producerThread->start();
    }
}

QVariant InfoListModel::value(QVariantList ix, const QString &fld_name)
{
    if(data(ix) != QVariant::Invalid) {
        return data(ix).toMap()[fld_name];
    }
    return QVariant::Invalid;
}

void InfoListModel::setValue(QVariantList ix, const QString& fld_name, const QVariant& val)
{
    // model data are organized in a list of dictionaries
    if(data(ix) != QVariant::Invalid) {
        QVariantMap v = data(ix).toMap();
        v[fld_name] = val;
        updateItem(ix, v);
    }
}


void InfoListModel::setSelectedIndex(QVariantList index)
{
	m_selectedIndex = index;
}

QString InfoListModel::getSelectedVideoPath()
{
	const QString flagName("path");
	QVariant v = value(m_selectedIndex, flagName);
	qDebug() <<"\n\nSelected Index = "<<m_selectedIndex<<"\n";
	return v.toString();
}

QString InfoListModel::getFormattedTime(int msecs)
{
    QString formattedTime;

    int hours = msecs/(1000*60*60);
    int minutes = (msecs-(hours*1000*60*60))/(1000*60);
    int seconds = (msecs-(minutes*1000*60)-(hours*1000*60*60))/1000;
    int milliseconds = msecs-(seconds*1000)-(minutes*1000*60)-(hours*1000*60*60);

    formattedTime.append(QString("%1").arg(hours, 2, 10, QLatin1Char('0')) + ":" +
                         QString( "%1" ).arg(minutes, 2, 10, QLatin1Char('0')) + ":" +
                         QString( "%1" ).arg(seconds, 2, 10, QLatin1Char('0')) + ":" +
                         QString( "%1" ).arg(milliseconds, 3, 10, QLatin1Char('0')));

    return formattedTime;
}

int InfoListModel::getWidth()
{
	const QString flagName("width");
	QVariant v = value(m_selectedIndex, flagName);
	int retValue =  v.toInt();
	return retValue;
}

int InfoListModel::getHeight()
{
	const QString flagName("height");
	QVariant v = value(m_selectedIndex, flagName);
	int retValue =  v.toInt();
	return retValue;
}

void InfoListModel::setVideoPosition(int pos)
{
	const QString flagName("position");
	setValue(m_selectedIndex, flagName, pos);
}

int InfoListModel::getVideoPosition()
{
	const QString flagName("position");
	QVariant v = data(m_selectedIndex).toMap()[flagName];
	int retValue =  v.toInt();
	return retValue;
}

QVariantList InfoListModel::getVideoPosition(QString item)
{
    for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath))
	{
		QVariantMap v = data(indexPath).toMap();
		if(v["path"].toString().compare(item) == 0)
		{
			return indexPath;
		}
	}
	return QVariantList();
}

QString InfoListModel::getVideoTitle()
{
	const QString flagName("title");
	QVariant v = value(m_selectedIndex, flagName);
	qDebug() << "\n\nSelected Index = " << m_selectedIndex << "\n";
	return v.toString();
}

QString InfoListModel::getVideoDuration()
{
	const QString flagName("duration");
	QVariant v = value(m_selectedIndex, flagName);
	qDebug() << "\n\nSelected Index = " << m_selectedIndex << "\n";
	return v.toString();
}

QVariantList InfoListModel::getSelectedIndex()
{
    return m_selectedIndex;
}

InfoListModel* InfoListModel::get()
{
	return this;
}

int InfoListModel::deleteVideos()
{
	int count = m_currentSelectionList.size();
	for (int i = 0; i < m_currentSelectionList.size(); i++)
	{
		QVariantList index = m_currentSelectionList[i];
		QVariantMap v = data(index).toMap();
		QFile::remove(v["path"].toString());
		QString tName = v["thumbURL"].toString();
		QFile::remove(tName.mid(7, tName.length() - 7));
		removeAt(index);

		for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			QVariantMap val = data(indexPath).toMap();
			if (val["folder"]=="0Favorites" && val["path"] == v["path"]) {
				removeAt(indexPath);
				count--;
			}
		}
	}
	saveData();
	return count;
}

QString InfoListModel::folderFieldName(QString path)
{
	QStringList pathElements = path.split('/', QString::SkipEmptyParts, Qt::CaseSensitive);

	if (pathElements[2] == "shared") {
		QString fName = pathElements[pathElements.length()-2];
		if(pathElements[3] == "videos")
			return QString("1Videos");
		if(pathElements[3] == "downloads")
			return QString("2Downloads");
		if(pathElements[3] == "camera")
			return QString("3Camera");
		return QString("4Other");
	} else if (pathElements[2] == "removable" && pathElements[3] == "sdcard") {
		return QString("5Media Card");
		/*
		QString folders = "";
		if(pathElements[4] == "videos") {
			folders = "5Media Card";
		} else if (pathElements[4] == "downloads") {
			folders = "6Media Card";
		} else if (pathElements[4] == "camera") {
			folders = "7Media Card";
		}
		if (folders != "") {
			for (int i=4; i<pathElements.length()-1; i++) {
				folders+="/" + pathElements[i];
			}
			return folders;
		}
        folders = "8Media Card";
		for (int i=4; i<pathElements.length()-1; i++) {
			folders+="/" + pathElements[i];
		}
		return folders;
		*/
	}
	return QString();
}

int InfoListModel::getIntIndex(QVariantList index)
{
    QVariantMap v = data(index).toMap();
    int result = 0;
    for(QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath))
    {
        QVariantMap map = data(indexPath).toMap();
        if(map == v)
            return result;
        result++;
    }
    return -1;
}

int InfoListModel::addToFavorites()
{
	QList<QVariantMap> folBuffer;
	for (int i = 0; i < m_currentSelectionList.size(); i++)
	{
		QVariantList index = m_currentSelectionList[i];
		QVariantMap val = data(index).toMap();

		bool isFavorite = false;
		for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			QVariantMap v = data(indexPath).toMap();
			if (v["folder"]=="0Favorites" && v["path"] == val["path"]) {
				isFavorite = true;
				break;
			}
		}
		if (!isFavorite) {
			folBuffer.push_front(val);
		}
	}

	for(int i = 0; i < folBuffer.size(); i++)
	{
		folBuffer[i]["folder"] = "0Favorites";
		insert(folBuffer[i]);
	}
	saveData();
	return folBuffer.size();
}

int InfoListModel::removeFromFavorites()
{
	QList<QString> notFavorites;
	int count = 0;
	for (int i = 0; i < m_currentSelectionList.size(); i++)
	{
		QVariantList index = m_currentSelectionList[i];
		QVariantMap v = data(index).toMap();
		if (v["folder"] == "0Favorites") {
			count++;
			removeAt(index);
		} else {
			notFavorites.push_front(v["path"].toString());
		}
	}

	for (int i = 0; i < notFavorites.size(); i++) {
		for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			QVariantMap val = data(indexPath).toMap();
			if (val["folder"] == "0Favorites" && val["path"] == notFavorites[i] ) {
				count++;
				removeAt(indexPath);
				break;
			}
		}
	}

	saveData();
	return count;
}

int InfoListModel::getButtonVisibility(QString folderName)
{
	bool folFound = false, nonFolFound=false;
	for(int i = 0; i < m_currentSelectionList.size();i++)
	{
		QVariantList index = m_currentSelectionList[i];
		QVariantMap v = data(index).toMap();
		if (v["folder"] == folderName)
			folFound = true;
		else
			nonFolFound = true;
	}
	if (folFound && nonFolFound)
		return 0;
	else if (nonFolFound)
		return 1;
	else
		return 2;
}

void InfoListModel::addToSelected(QVariantList index)
{
	m_currentSelectionList.push_back(index);
}

void InfoListModel::clearSelected()
{
	m_currentSelectionList.clear();
}

QVariantList InfoListModel::getFavorites()
{
	QVariantList favoriteVideos;

	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		if (v["folder"]=="0Favorites") {
			favoriteVideos.push_back(v);
		}
	}
	return favoriteVideos;
}

QVariantList InfoListModel::getFrameVideos()
{
	QVariantList favoriteVideos = getFavorites();

	if (favoriteVideos.length() == 0) {
		int i = 0;
		for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			favoriteVideos.push_back(data(indexPath).toMap());
			i++;
			if (i>=10) {
				break;
			}
		}
	}
	return favoriteVideos;
}

QVariantList InfoListModel::getRealIndex(QVariantList index)
{
	QVariantMap favorite = data(index).toMap();
	if (favorite["folder"] != "0Favorites") {
		return index;
	}
	QVariantList realIndex;
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		if (v["folder"] != "0Favorites" && v["path"] == favorite["path"]) {
			realIndex = indexPath;
			break;
		}
	}
	return realIndex;
}

QString InfoListModel::getFirstFolder()
{
	QVariantMap v = data(first()).toMap();
	return v["folder"].toString();
}

QString InfoListModel::getSelectedVideoThumbnail()
{
	const QString flagName("thumbURL");
	QVariant v = value(m_selectedIndex, flagName);
	QString retValue =  v.toString();
	return retValue;
}

void InfoListModel::markSelectedAsWatched()
{
	QVariantMap map = data(m_selectedIndex).toMap();
	map["isWatched"] = true;
	updateItem(m_selectedIndex, map);
}

void InfoListModel::prepareForPlay(QVariantList indexPath)
{
	if(!isPlayable(indexPath)) {
		reader->addToQueue(data(indexPath).toMap()["path"].toString());
	}
}

bool InfoListModel::isPlayable(QVariantList indexPath)
{
    QVariantMap map = data(indexPath).toMap();
    return map["duration"].toBool() || (map["duration"] == "0");
}
