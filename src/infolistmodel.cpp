// List with context menu project template
#include "infoListModel.hpp"
#include <iostream.h>

#include <QFile>
#include <Qdir>
#include <Qtextstream>
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


inline const static QStringList getVideoFileList() {
	QStringList filters, result;

	filters <<  "*.avi" <<  "*.mp4" << "*.m4v"  <<"*.mov"  << "*.3gp" << "*.3gp2";

	FileSystemUtility::getEntryListR("/accounts/1000/shared/videos", filters, result);
	FileSystemUtility::getEntryListR("/accounts/1000/shared/camera", filters, result);
	FileSystemUtility::getEntryListR("/accounts/1000/shared/downloads", filters, result);
	return result;
}


InfoListModel::InfoListModel(QObject* parent)
: m_selectedIndex(QVariantList())
, m_file(QDir::home().absoluteFilePath("videoInfoList.json"))
{
    setSortingKeys(QStringList() << "folder");
    setGrouping(ItemGrouping::ByFullValue);

    qDebug() << "Creating InfoListModel object:" << this;
    setParent(parent);
    m_producer = new Producer(this);
	QObject::connect(this, SIGNAL(consumed()), m_producer, SLOT(produce()));
	QObject::connect(m_producer, SIGNAL(produced(QString, QVariantList)), this,
			SLOT(consume(QString, QVariantList)));

    m_producerThread  = new QThread();
	m_producer->moveToThread(m_producerThread);

	//when producer thread is started, start to produce
	QObject::connect(m_producerThread, SIGNAL(started()), m_producer,
			SLOT(produce()));
	QObject::connect(m_producer, SIGNAL(finishedCurrentVideos()), this,
					SLOT(checkVideosWaitingThumbnail()));

	QObject::connect(this, SIGNAL(finishedThumbnailGeneration()), m_producerThread,
			SLOT(quit()));
	QObject::connect(this, SIGNAL(finishedThumbnailGeneration()), parent,
				SLOT(onThumbnailsGenerationFinished()));
	observer = new Observer(this);
	QObject::connect(this, SIGNAL(notifyObserver(QStringList)), observer,
					SLOT(setNewVideos(QStringList)));
	m_mediaPlayerThread = new QThread();
	reader = new MetaDataReader();
	reader->moveToThread(m_mediaPlayerThread);
	QObject::connect(reader, SIGNAL(metadataReady(const QVariantMap& )), this, SLOT(onMetadataReady(const QVariantMap& )));
	QObject::connect(this, SIGNAL(setData(QStringList )), reader, SLOT(setData(QStringList )));
	getVideoFiles();
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

void InfoListModel::consume(QString filename, QVariantList index)
{
	if (index.length() == 0)
	{
		emit consumed();
		return;
	}
	//process that data
	// add generated thumbnail to list model
	setValue(index, "thumbURL", "file://" + filename);
	//when finished processing emit a consumed signal
	emit consumed();
	saveData();
}

void InfoListModel::getVideoFiles(const QString& path)
{
	QStringList filters, result, newVideos;
	filters <<  "*.avi" <<  "*.mp4";
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
	if(newVideos.isEmpty())
	{
			updateListWithDeletedVideos(result);
			m_producer->updateVideoList(this);
			onAllMetadataRead();
	}
	else
	{
		emit notifyObserver(newVideos);
	}
}

void InfoListModel::fileComplate(QString path)
{
	QStringList new_;
	new_<<(path);
	updateListWithAddedVideos(new_);
}

void InfoListModel::getVideoFiles()
{
	// need to create the folder for thumbnails here
	QDir dir;
	if(!dir.exists(QDir::home().absoluteFilePath("thumbnails/")))
	{
		dir.mkpath("data/thumbnails/");
	}
	try {
		QStringList result (getVideoFileList());
		QFile file(m_file);
		if (!file.exists()) {
			if (file.open(QIODevice::ReadWrite | QIODevice::Text)) {
				QTextStream stream(&file);
				stream << "[]" << endl;
				updateListWithAddedVideos(result);
				file.close();
			}
			saveData();
			load();
			onAllMetadataRead();
		}
		else
		{
			load();
			updateVideoList();
			onAllMetadataRead();
		}
	} catch (const exception& e) {
		//do corresponding job
	}
}

void InfoListModel::insertVideos(QVariantList newVideos)
{
	if(m_producerThread->isRunning())
	{
		videosWaitingThumbnail.append(newVideos);
	}
	else
	{
		videosWaitingThumbnail.append(newVideos);
		insertList(videosWaitingThumbnail);
		videosWaitingThumbnail.clear();
		saveData();
		onAllMetadataRead();
	}
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
			val["folder"] = folderFieldName(pathElements[pathElements.size() - 2]);
			bool durationIsCorrect = true;
			movieDecoder.setContext(0);
			try{
				movieDecoder.initialize(i->toStdString());
				_int64 duration = movieDecoder.getVideosDuration();

				if(duration != 0)
				{
					val["duration"] = duration;
				}
				else
				{
					durationIsCorrect = false;
				}
				val["width"] = movieDecoder.getWidth();
				val["height"] = movieDecoder.getHeight();
				if(durationIsCorrect)
				{
					QVariantList list;
					list<<(val);
					insertVideos(list);
				}
				else
					waitingVideosBuffer<<(*i);
			}
			catch (...){
				// invalid video! just skip this file.
			}

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
		dir.remove(data(value.last()).toMap()["thumbURL"].toString());
		removeAt(value.last());
		value.pop_back();
	}
}

void InfoListModel::updateVideoList()
 {
	QStringList result (getVideoFileList());
	updateListWithAddedVideos(result);
	updateListWithDeletedVideos(result);
}

InfoListModel::~InfoListModel()
{
	delete m_producer;
	delete m_producerThread;
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
	infoMap["folder"] = folderFieldName(pathElements[pathElements.size() - 2]);
	infoMap["duration"] = val.value(bb::multimedia::MetaData::Duration).toString();
	infoMap["width"] = val.value(bb::multimedia::MetaData::Width).toString();
	infoMap["height"] = val.value(bb::multimedia::MetaData::Height).toString();
	QVariantList list;
	list<<(infoMap);
	insertVideos(list);
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

QVariantList InfoListModel::getSelectedIndex()
{
    return m_selectedIndex;
}

InfoListModel* InfoListModel::get()
{
	return this;
}

void InfoListModel::deleteVideos()
{
	for (int i = 0; i < m_currentSelectionList.size(); i++)
	{
		QVariantList index = m_currentSelectionList[i];
		QVariantMap v = data(index).toMap();
		QFile::remove(v["path"].toString());
		removeAt(index);
	}
	saveData();
}

QString InfoListModel::folderFieldName(QString fName)
{
    if(!fName.compare("videos"))
        return QString("1Videos");

    if(!fName.compare("downloads"))
        return QString("2Downloads");

    if(!fName.compare("camera"))
        return QString("3Camera");

    return QString("4Other");
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


void InfoListModel::toggleFolder(QString folderName)
{
    QList<QVariantMap> folBuffer;
	for (int i = 0; i < m_currentSelectionList.size(); i++)
	{
		QVariantList index = m_currentSelectionList[i];
		QVariantMap v = data(index).toMap();
		QString test = v["path"].toString();
		if(v["folder"] != folderName)
		{
			v["folder"] = folderName;
		}
		else
		{
			QString path = v["path"].toString();
			QStringList pathElements = path.split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
			v["folder"] = folderFieldName(pathElements[pathElements.size() - 2]);
		}
		// We remove the node because we will reinsert it once the buffer is full
		removeAt(index);
		folBuffer.push_front(v);
	}
	for(int i = 0; i < folBuffer.size();i++)
	{
		insert(folBuffer[i]);
	}
	saveData();
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
