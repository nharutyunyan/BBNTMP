// List with context menu project template
#include "infoListModel.hpp"
#include <iostream.h>

#include <QFile>
#include <Qdir>
#include <Qtextstream>
#include <iostream>


#include <QVariantList>
#include "utility.hpp"
#include "videothumbnailer.hpp"
#include "producer.hpp"


#include <bb/data/JsonDataAccess>

using namespace bb::cascades;
using namespace utility;

//TODO: Move the data handling (storage/loading) into separate module  - DataManager
//View model should be simple, and just keep the list for Views

InfoListModel::InfoListModel(QObject* parent)
: bb::cascades::QVariantListDataModel()
, m_selectedIndex(0)
{
	m_file = QDir::home().absoluteFilePath("videoInfoList.json");
    qDebug() << "Creating InfoListModel object:" << this;
    setParent(parent);


    int start = 0;
    getVideoFiles(start);

    m_producer = new Producer(m_list, start);

	QObject::connect(this, SIGNAL(consumed()), m_producer, SLOT(produce()));
	QObject::connect(m_producer, SIGNAL(produced(QString, int)), this,
			SLOT(consume(QString, int)));

    m_producerThread  = new QThread();
	m_producer->moveToThread(m_producerThread);

	//when producer thread is started, start to produce
	QObject::connect(m_producerThread, SIGNAL(started()), m_producer,
			SLOT(produce()));

	QObject::connect(m_producer, SIGNAL(finished()), m_producerThread,
			SLOT(quit()));
	QObject::connect(m_producer, SIGNAL(finished()), parent,
				SLOT(onThumbnailsGenerationFinished()));
}

void InfoListModel::consume(QString data, int index)
{
	//process that data
	// add generated thumbnail to list model
	setValue(index, "thumbURL", data);
	//when finished processing emit a consumed signal
	emit consumed();
}

void InfoListModel::getVideoFiles(int& startIndex)
{
	// need to create the folder for thumbnails here
	QDir dir;
	if(!dir.exists(QDir::home().absoluteFilePath("thumbnails/")))
	{
		dir.mkpath("data/thumbnails/");
	}
	try {
		QStringList result;
		QStringList filters;
		filters << "*.mp4";
		filters << "*.avi";
		FileSystemUtility::getEntryListR("/accounts/1000/shared/videos",
				filters, result);

		QFile file(m_file);
		if (!file.exists()) {
			if (file.open(QIODevice::ReadWrite | QIODevice::Text)) {
				QTextStream stream(&file);
				stream << "[]" << endl;
				for (int i = 0; i < result.size(); ++i) {
					QVariantMap val;
					val["path"] = result[i];
					val["position"] = "0";
					//Get the last path component and set it as title. Might be changed in future to get title from metadata
					QStringList pathElements = result[i].split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
					val["title"] = pathElements[pathElements.size()-1];
					// Add the thumbnail URL to the JSON file
					val["thumbURL"] = "asset:///images/play.png";//finalFileName;

					m_list.append(val);
				}
				file.close();
			}
			saveData();
			load();
			readMetadatas(result);
			append(m_list);
		}
		else
		{
			load();
			startIndex = m_list.size();
			updateVideoList();
			readMetadatas(result);
		}
	} catch (const exception& e) {
		//do corresponding job
	}
}

void InfoListModel::updateListWithAddedVideos(const QStringList& result)
{
	QVariantList videos;
	for (int i = 0; i < result.size(); ++i) {
		bool videoExist = false;
		for (int ix = 0; ix < m_list.size(); ++ix) {
			QVariantMap v = m_list[ix].toMap();
			if (v["path"].toString().compare(result[i]) == 0) {
				videoExist = true;
				break;
			}
		}
		if (!videoExist) {
			//add new video to json data
			QVariantMap val;
			val["path"] = result[i];
			val["position"] = "0";
			//Get the last path component and set it as title. Might be changed in future to get title from metadata
			QStringList pathElements = result[i].split('/', QString::SkipEmptyParts, Qt::CaseSensitive);
			val["title"] = pathElements[pathElements.size()-1];
			// Add the thumbnail URL to the JSON file
			val["thumbURL"] = "asset:///images/play.png";

			videos.append(val);
		}
	}
	m_list.append(videos);
}

void InfoListModel::updateListWithDeletedVideos(const QStringList& result)
 {
	QDir dir;
	QString thumbnailDir = dir.homePath() + "/thumbnails/";
	dir.cd(thumbnailDir);
	QVariantList index;
	for (int ix = 0; ix < m_list.size(); ++ix) {
		bool videoExist = false;
		QVariantMap v = m_list[ix].toMap();
		for (int i = 0; i < result.size(); ++i) {
			if (v["path"].toString().compare(result[i]) == 0) {
				videoExist = true;
				break;
			}
		}
		if (!videoExist) {
			// if the video does not exist any more remote its thumbnail as well
			dir.remove(v["thumbURL"].toString());
			index.append(ix);
		}
	}
	for (int j = 0; j < index.size(); ++j) {
		//remove deleted video from json data
		m_list.erase(m_list.begin() + index[j].toInt());
	}
}

void InfoListModel::updateVideoList()
 {
	QStringList result;
	QStringList filters;
	QVariantList videos;
	filters << "*.mp4";
	filters << "*.avi";
	FileSystemUtility::getEntryListR("/accounts/1000/shared/videos", filters, result);
	updateListWithAddedVideos(result);
	updateListWithDeletedVideos(result);
	append(m_list);
}

void InfoListModel::refresh()
{
	clear();
	append(m_list);
}

InfoListModel::~InfoListModel()
{
	m_list.clear();
	delete m_producer;
	delete m_producerThread;
    qDebug() << "Destroying InfoListModel object:" << this;
}

void InfoListModel::load()
{
    bb::data::JsonDataAccess jda;
    m_list = jda.load(m_file).value<QVariantList>();
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
    jda.save(m_list, m_file);
    if (jda.hasError()) {
        bb::data::DataAccessError error = jda.error();
        qDebug() << m_file << "JSON save error: " << error.errorType() << ": " << error.errorMessage();
    }
    else {
        qDebug() << m_file << "JSON data save OK!";
    }
}

void InfoListModel::readMetadatas(QStringList videoFiles)
{
	MetaDataReader* reader = new MetaDataReader(this);
	if (!reader)
	{
		qDebug() << "ERROR: Can't allocate memory for MetadataReader \n";
		return;
	}

	connect(reader, SIGNAL(metadataReady(const QVariantMap&)), this, SLOT(onMetadataReady(const QVariantMap&)));
	connect(reader, SIGNAL(allMetadataRead()), this, SLOT(onAllMetadataRead()));
	reader->addMetadataReadRequest(videoFiles);
}

void InfoListModel::onMetadataReady(const QVariantMap& data)
{
	//Update the appropriate video info entry
	QString path = data[bb::multimedia::MetaData::Uri].toString();
	if(path.isEmpty())
	{
		qDebug() << "Error: No uri in metadata \n";
		return;
	}

	bool changed = false;

	for(QVariantList::iterator it = m_list.begin(); it != m_list.end(); ++it)
	{
		if(path == (*it).toMap()["path"].toString())
		{
			QVariantMap infoMap = (*it).toMap();
			//Set only needed fields : title, duration
			QString titleInMD = data.value("title").toString();
			if(!titleInMD.isEmpty() && infoMap.value(bb::multimedia::MetaData::Title).toString() != titleInMD)
			{
				infoMap[bb::multimedia::MetaData::Title] = titleInMD;
				changed = true;
			}

			QString duration = data.value(bb::multimedia::MetaData::Duration).toString();
			if (!duration.isEmpty() && infoMap.value("duration").toString() != duration)
			{
				infoMap["duration"] = duration;
				changed = true;
			}
			//Update the list
			(*it) = infoMap;
			break;
		}
	}

	//Save and reload the new list
	if (changed)
	{
		saveData();
		refresh();
	}
}

void InfoListModel::onAllMetadataRead()
{
    m_producerThread->start();
}

QVariant InfoListModel::value(int ix, const QString &fld_name)
{
    QVariant ret;
    // model data are organized in a list of dictionaries
    if(ix >= 0 && ix < size()) {
        // get dictionary on index
        QVariantMap curr_val = QVariantListDataModel::value(ix).toMap();
        ret = curr_val.value(fld_name);
    }
    return ret;
}

void InfoListModel::setValue(int ix, const QString& fld_name, const QVariant& val)
{
    // model data are organized in a list of dictionaries
    if(ix >= 0 && ix < size()) {
        // get dictionary on index
        QVariantMap curr_val = QVariantListDataModel::value(ix).value<QVariantMap>();
        // set dictionary value for key fld_name
        curr_val[fld_name] = val;
        // replace updated dictionary in array
        replace(ix, curr_val);
        m_list[ix].setValue(curr_val);
    }
}


void InfoListModel::setSelectedIndex(int index)
{
	m_selectedIndex = index;
}

QString InfoListModel::getSelectedVideoPath()
{
	const QString flagName("path");
	QVariant v = value(m_selectedIndex, flagName);
	std::cout<<"\n\nSelected Index = "<<m_selectedIndex<<"\n";
	return v.toString();
}

QString InfoListModel::getNextVideoPath(void)
{
	++m_selectedIndex;
	if(m_selectedIndex >= size())
	{
		m_selectedIndex = 0;
	}
	return getSelectedVideoPath();
}

QString InfoListModel::getPreviousVideoPath(void)
{
	--m_selectedIndex;
	if(m_selectedIndex < 0)
	{
		m_selectedIndex = size() - 1;
	}
	return getSelectedVideoPath();
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

void InfoListModel::setVideoPosition(int pos)
{
	const QString flagName("position");
	setValue(m_selectedIndex, flagName, pos);
}

int InfoListModel::getVideoPosition()
{
	const QString flagName("position");
	QVariant v = value(m_selectedIndex, flagName);
	int retValue =  v.toInt();
	return retValue;
}

QString InfoListModel::getVideoTitle()
{
	const QString flagName("title");
	QVariant v = value(m_selectedIndex, flagName);
	std::cout << "\n\nSelected Index = " << m_selectedIndex << "\n";
	return v.toString();
}

InfoListModel* InfoListModel::get()
{
	return this;
}
