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

const int InfoListModel::MAX_FAVORITE_NUMBER = 10;
const int InfoListModel::MIN_FAVORITE_NUMBER = 2;

//TODO: Move the data handling (storage/loading) into separate module  - DataManager
//View model should be simple, and just keep the list for Views
MovieDecoder InfoListModel::s_movieDecoder;

QStringList const InfoListModel::getVideoFileList(const QString& dir) {
	QStringList filters, result;

	//BB10 presumably supported formats: 3GP, 3GP2, ASF, AVI, F4V, M4V, MKV, MOV, MP4, MPEG4, WMV
	filters << ".avi" << ".mp4" << ".3gp" << ".3g2" << ".asf" << ".wmv"
			<< ".mov" << ".m4v" << ".f4v" << ".mkv"; //these are the formats the don't crash the app.

	if(dir != "")
	{
		FileSystemUtility::getEntryList(dir, filters, result, false);
	}
	else
	{
		//Phone storage
		FileSystemUtility::getEntryList("/accounts/1000/shared/videos", filters, result, true);
		FileSystemUtility::getEntryList("/accounts/1000/shared/camera", filters, result, true);
		FileSystemUtility::getEntryList("/accounts/1000/shared/downloads", filters, result, true);

		//SD card storage
		if(QDir("/accounts/1000/removable/sdcard").exists())
				FileSystemUtility::getEntryList("/accounts/1000/removable/sdcard", filters, result, true);
	}

	return result;
}

InfoListModel::InfoListModel(QObject* parent)
: m_selectedIndex(QVariantList())
, m_file(QDir::home().absoluteFilePath("videoInfoList.json"))
, m_retryAttempts(0)
{
    setSortingKeys(QStringList() << "folder" << "title");
    setGrouping(ItemGrouping::ByFullValue);

    qDebug() << "Creating InfoListModel object:" << this;
    setParent(parent);
    m_producer = new Producer();
	//QObject::connect(this, SIGNAL(consumed()), m_producer, SLOT(produce()));
	QObject::connect(m_producer, SIGNAL(produced(QString, QString)), this,
			SLOT(consume(QString, QString)));

	m_ParalellWorkerThread = new QThread();

	m_producer->moveToThread(m_ParalellWorkerThread);


	//when producer thread is started, start to produce
	QObject::connect(this, SIGNAL(produce(QString,int)), parent,
					SLOT(loadingIndicatorStart()));
	QObject::connect(this, SIGNAL(produce(QString,int)), m_producer,
			SLOT(produce(QString,int)));
	QObject::connect(m_producer, SIGNAL(finishedCurrentVideos()), this,
					SLOT(checkVideosWaitingThumbnail()));

	QObject::connect(this, SIGNAL(finishedThumbnailGeneration()), parent,
				SLOT(onThumbnailsGenerationFinished()));

	m_observer = new Observer(this);
	QObject::connect(this, SIGNAL(notifyObserver(QStringList)), m_observer,
					SLOT(setNewVideos(const QStringList&)));
	QObject::connect(this, SIGNAL(notifyObserver(QStringList)), parent,
					SLOT(loadingIndicatorStart()));

	m_observer->createWatcher();

	m_reader = new MetaDataReader();
	m_reader->moveToThread(m_ParalellWorkerThread);
	QObject::connect(this, SIGNAL(setData(QString)), m_reader, SLOT(setData(QString)));
	QObject::connect(m_reader, SIGNAL(metadataReady(QVariantMap)), this, SLOT(onMetadataReady(QVariantMap)));
	QObject::connect(m_reader, SIGNAL(allMetaDataRead()), this, SLOT(onAllMetadataRead()));
	QObject::connect(m_reader, SIGNAL(videoNotSupported(QString)), this, SLOT(markAsDamaged(QString)));

	m_paralellWorker  = new ParalellWorker();
	QObject::connect(m_paralellWorker, SIGNAL(VideoFileListComplete(QStringList,QString)), this,
			SLOT(onVideoFileListComplete(QStringList,QString)));

	m_paralellWorker->moveToThread(m_ParalellWorkerThread);
	QObject::connect(this, SIGNAL(videoFilesListNeeded(QString)), m_paralellWorker,
			SLOT(getVideoFileList(QString)));

	m_ParalellWorkerThread->start();

	prepareToStart();

	getVideoFiles();

}

void InfoListModel::consume(QString filename, QString path)
{
	m_videosWaitingThumbnail.remove(path);

	if(filename != "")
	{
		for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			QVariantMap v = data(indexPath).toMap();
			if (v["path"].toString() == path) {
				// add generated thumbnail to list model
				setValue(indexPath, "thumbURL", "file://" + filename);
				saveData();
			}
		}
	}
	else
		m_videosFailedThumbnail.insert(path);

	if(m_videosWaitingThumbnail.size() == 0)
	{
		if(m_videosFailedThumbnail.size() > 0 && m_retryAttempts < 2)
		{
			updateVideoList();
			++m_retryAttempts;
		}
		else
			emit finishedThumbnailGeneration();
	}
}

void InfoListModel::getVideoFiles(QString dir)
{
	emit videoFilesListNeeded(dir);
}

void InfoListModel::onVideoFileListComplete(QStringList result, QString dir)
{
	QStringList newVideos;
	QSet<QString> set;

	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		set.insert(v["path"].toString());
		if (v["duration"].toString()=="") {

			qDebug() << "readMetadata - " << v["path"].toString();
			readMetadata(v["path"].toString());
		}
	}

	for (QStringList::const_iterator i = result.begin(); i != result.end(); ++i) {
		bool videoExist = set.contains(*i);
		if(!videoExist)
		{
			if(!m_addedVideos.contains(*i))
			{
				newVideos.push_back(*i);
				m_addedVideos.insert(*i);
			}
		}
	}

	updateListWithDeletedVideos(result, dir);
	checkSubtitle();

	if(!newVideos.isEmpty())
	{
		emit notifyObserver(newVideos);
	} else {
		//onAllMetadataRead();
	}
}

int InfoListModel::addRemoteVideos(QStringList newVideos)
{
	QSet<QString> existingVideos;
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			QVariantMap v = data(indexPath).toMap();
			existingVideos.insert(v["path"].toString());
	}

	QStringList results;
	for (int i=0; i< newVideos.length(); ++i) {
		if (!existingVideos.contains(newVideos[i])) {
			results.append(newVideos[i]);
			QVariantMap val;
			val["path"] = newVideos[i];
			val["position"] = "0";
			//Get the last path component and set it as title. Might be changed in future to get title from metadata
			QStringList pathElements = newVideos[i].split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
			val["title"] = pathElements[pathElements.size()-1];
			// Add the thumbnail URL to the JSON file
			val["thumbURL"] = "asset:///images/BlankThumbnail.png";
			// Add folder
			val["folder"] = folderFieldName(val["path"].toString());
			val["isWatched"] = false;
			insert(val);
			readMetadata(newVideos[i]);
		}
	}
	saveData();

	return results.count();
}

int InfoListModel::addNewVideosManually(QStringList newVideos)
{
	QSet<QString> existingVideos;
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		existingVideos.insert(v["path"].toString());
	}

	QStringList results;
	QStringList remoteResults;


	for (int i=0; i< newVideos.length(); ++i) {
		QStringList pathElements = newVideos[i].split('/', QString::SkipEmptyParts, Qt::CaseSensitive);

		if (!existingVideos.contains(newVideos[i])) {
			if (isLocal(newVideos[i])) {
				results.append(newVideos[i]);
			} else {
				remoteResults.append(newVideos[i]);
			}
		}
	}

	if (results.count()>0) {
		emit notifyObserver(results);
	}
	if (remoteResults.count()>0) {
		addRemoteVideos(remoteResults);
	}

	return results.count() + remoteResults.count();
}

void InfoListModel::clearAddedVideos()
{
	m_addedVideos.clear();
}

void InfoListModel::fileComplete(QString path)
{

	// Slight improvement to the video exists check that was below,
	QSet<QString> set;
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		set.insert(v["path"].toString());
	}

	if (!set.contains(path)) {
		//add new video to json data
		QVariantMap val;
		val["path"] = path;
		val["position"] = "0";
		//Get the last path component and set it as title. Might be changed in future to get title from metadata
		QStringList pathElements = path.split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
		val["title"] = pathElements[pathElements.size()-1];
		// Add the thumbnail URL to the JSON file
		val["thumbURL"] = "asset:///images/BlankThumbnail.png";
		// Add folder
		val["folder"] = folderFieldName(val["path"].toString());
		val["isWatched"] = false;
		val["haveSubtitle"] = false;
		insert(val);

		QString VideoDir = path;
		VideoDir.truncate(VideoDir.lastIndexOf('/',-1,Qt::CaseSensitive));
		m_observer->addWatcher(VideoDir);

		readMetadata(path);
	}

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

void InfoListModel::updateListWithDeletedVideos(const QStringList& result, const QString& scanDir)
 {
	QDir dir;
	QString thumbnailDir = dir.homePath() + "/thumbnails/";
	dir.cd(thumbnailDir);

	QSet<QString> result_set (result.toSet());

	QList<QVariantList> value;

	QStringList filesToRemove;

	for(QSet<QString>::const_iterator it = m_addedVideos.begin(); it != m_addedVideos.end(); ++it)
	{
		QFileInfo fileInfo(*it);
		if((scanDir == "" || scanDir == fileInfo.path()) && !result.contains(*it))
			filesToRemove << *it;
	}

	QVariantList indexPath;

	for(QVariantList beforeIndexPath = last(); !beforeIndexPath.isEmpty() && !filesToRemove.isEmpty();)
	{
		indexPath = beforeIndexPath;
		beforeIndexPath = before(indexPath);

		QVariantMap v (data(indexPath).toMap());
		QString path = v["path"].toString();
		if(filesToRemove.contains(path))
		{
			m_addedVideos.remove(path);
			removeAt(indexPath);
			QString thumbnailName = v["thumbURL"].toString();
			dir.remove(thumbnailName.mid(7, thumbnailName.length() - 7));
			//filesToRemove.removeOne(path);
		}
	}
}

InfoListModel::~InfoListModel()
{
	delete m_ParalellWorkerThread;
	delete m_producer;
	delete m_observer;
	delete m_reader;
    qDebug() << "Destroying InfoListModel object:" << this;
}

void InfoListModel::load()
{
    clear();
    bb::data::JsonDataAccess jda;
    QVariantList vList = jda.load(m_file).toList();
    if (jda.hasError()) {
        bb::data::DataAccessError error = jda.error();
        //qDebug() << m_file << "JSON loading error: " << error.errorType() << ": " << error.errorMessage();
    }
    else {
        //qDebug() << m_file << "JSON data loaded OK!";
    }

    insertList(vList);

    m_addedVideos.clear();
    for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath))
    {
    	m_addedVideos.insert(data(indexPath).toMap()["path"].toString());
    }
    updateVideoList();
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

void InfoListModel::readMetadata(QString path)
{
	emit setData(path);
}

void InfoListModel::onMetadataReady(QVariantMap val)
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

	QString subtitlePath = path;
	subtitlePath.truncate(subtitlePath.lastIndexOf('.',-1,Qt::CaseSensitive));
	subtitlePath.append(".srt");
	if (QFile::exists(subtitlePath)) {
		infoMap["haveSubtitle"] = true;
	} else {
		infoMap["haveSubtitle"] = false;
	}

	updateItem(indexPath, infoMap);
	saveData();
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
	m_retryAttempts = 0;
    updateVideoList();
}

void InfoListModel::updateVideoList()
{
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath))
	{
		QVariantMap v = data(indexPath).toMap();

		if( v["thumbURL"].value<QString>() == "asset:///images/BlankThumbnail.png" &&
				!m_videosWaitingThumbnail.contains(v["path"].toString()) &&
					isLocal(v["path"].toString()) )
		{
		    v["indexPath"] = indexPath;
			//m_result.insert(v);
		    m_videosWaitingThumbnail.insert(v["path"].toString());
		    emit produce(v["path"].toString(), v["duration"].toString().toULongLong()/1000);
		}
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

		QString subtitleFilePath = v["path"].toString();
		subtitleFilePath.truncate(subtitleFilePath.lastIndexOf('.',-1,Qt::CaseSensitive));
		subtitleFilePath.append(".srt");
		if (QFile::exists(subtitleFilePath)) {
			QFile::remove(subtitleFilePath);
		}

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

	if (pathElements[2] == "removable" && pathElements[3] == "sdcard") {
		return QString("4Media Card");
	} else if (pathElements[2] == "shared") {
		QString fName = pathElements[pathElements.length()-2];
		if(pathElements[3] == "videos")
			return QString("1Videos");
		if(pathElements[3] == "downloads")
			return QString("2Downloads");
		if(pathElements[3] == "camera")
			return QString("3Camera");
		return QString("5" + pathElements[3]);

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
	} else {
		return QString("6Other");
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
	if (favoriteVideos.length() < MIN_FAVORITE_NUMBER) {
		for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
			if(!favoriteVideos.contains(data(indexPath)))
			    favoriteVideos.push_back(data(indexPath).toMap());
			if (favoriteVideos.length() >= MAX_FAVORITE_NUMBER) {
				break;
			}
		}
	}
	return favoriteVideos;
}

QVariantList InfoListModel::getFavoriteIndex(QVariantList index)  // It will return favorite index for real video if it has or it will return the real index for favorite video
{
	QVariantMap favorite = data(index).toMap();
	if (favorite["folder"] == "0Favorites") {
		return index;
	}
	QVariantList realIndex;
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		if (v["folder"] == "0Favorites" && v["path"] == favorite["path"]) {
			realIndex = indexPath;
			break;
		}
	}
	return realIndex;
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
	if (map["isWatched"] == false) {
		map["isWatched"] = true;
		updateItem(m_selectedIndex, map);

		QVariantList index;
		if (map["folder"] == "0Favorites") {
			index = getRealIndex(m_selectedIndex);
		} else {
			index = getFavoriteIndex(m_selectedIndex);
		}
		if (m_selectedIndex != index) {
			map = data(index).toMap();
			map["isWatched"] = true;
			updateItem(index, map);
		}
	}
}

void InfoListModel::prepareForPlay(QVariantList indexPath)
{
	if(!isPlayable(indexPath)) {
		m_reader->addToQueue(data(indexPath).toMap()["path"].toString());
	}
}

bool InfoListModel::isPlayable(QVariantList indexPath)
{
    QVariantMap map = data(indexPath).toMap();
    return map["duration"] != "-1";
}

QVariantList InfoListModel::getIndex(QString path)
{
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		if (v["path"] == path) {
			return indexPath;
		}
	}
	return QVariantList();
}

bool InfoListModel::isLocal(QString path)
{
	QStringList pathElements = path.split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
    return ( (pathElements[2] == "removable" && pathElements[3] == "sdcard") ||
			 (pathElements[2] == "shared" && (pathElements[3] == "videos" ||
											  pathElements[3] == "downloads" ||
											  pathElements[3] == "camera")) );
}

void InfoListModel::checkSubtitle(QString path)
{
	for (QVariantList indexPath = first(); !indexPath.isEmpty(); indexPath = after(indexPath)) {
		QVariantMap v = data(indexPath).toMap();
		if (path == "" || v["path"].toString() == path) {
			QString subtitlePath = v["path"].toString();
			subtitlePath.truncate(subtitlePath.lastIndexOf('.',-1,Qt::CaseSensitive));
			subtitlePath.append(".srt");
			if (QFile::exists(subtitlePath) != v["haveSubtitle"].toBool()) {
				v["haveSubtitle"] = QFile::exists(subtitlePath);
				updateItem(indexPath,v);
			}
			if (v["path"].toString() == path)
				return;
		}
	}
}

