// List with context menu project template
#include "mylistmodel.hpp"
#include <iostream.h>

#include <QFile>
#include <Qdir>
#include <Qtextstream>
#include <iostream>


#include <QVariantList>
#include "utility.hpp"


#include <bb/data/JsonDataAccess>

using namespace bb::cascades;
using namespace utility;

MyListModel::MyListModel(QObject* parent)
: bb::cascades::QVariantListDataModel()
, m_selectedIndex(0)
{
	m_file = QDir::home().absoluteFilePath("videoInfoList.json");
    qDebug() << "Creating MyListModel object:" << this;
    setParent(parent);
    load();
}

MyListModel::~MyListModel()
{
    qDebug() << "Destroying MyListModel object:" << this;
}

void MyListModel::load()
{
    bb::data::JsonDataAccess jda;
    m_list = jda.load(m_file).value<QVariantList>();
    if (jda.hasError()) {
        bb::data::DataAccessError error = jda.error();
        qDebug() << m_file << "JSON loading error: " << error.errorType() << ": " << error.errorMessage();
    }
    else {
        qDebug() << m_file << "JSON data loaded OK!";
        append(m_list);
    }
}

void MyListModel::saveData()
{
    bb::data::JsonDataAccess jda;
    QString buffer;
    jda.saveToBuffer(m_list, &buffer);
   // qDebug() << "BUFFER - " << buffer;
    jda.save(m_list, m_file);
    if (jda.hasError()) {
        bb::data::DataAccessError error = jda.error();
        qDebug() << m_file << "JSON save error: " << error.errorType() << ": " << error.errorMessage();
    }
    else {
        qDebug() << m_file << "JSON data save OK!";
    }
}

QVariant MyListModel::value(int ix, const QString &fld_name)
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

void MyListModel::setValue(int ix, const QString& fld_name, const QVariant& val)
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

void MyListModel::setSelectedIndex(int index)
{
	m_selectedIndex = index;
}

QString MyListModel::getSelectedVideoPath()
{
	const QString flagName("path");
	QVariant v = value(m_selectedIndex, flagName);
	std::cout<<"\n\nSelected Index = "<<m_selectedIndex<<"\n";
	return v.toString();
}

QString MyListModel::getNextVideoPath(void)
{
	++m_selectedIndex;
	if(m_selectedIndex >= size())
	{
		m_selectedIndex = 0;
	}
	return getSelectedVideoPath();
}

QString MyListModel::getPreviousVideoPath(void)
{
	--m_selectedIndex;
	if(m_selectedIndex < 0)
	{
		m_selectedIndex = size() - 1;
	}
	return getSelectedVideoPath();
}

QString MyListModel::getFormattedTime(int msecs)
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

void MyListModel::setVideoPosition(int pos)
{
	const QString flagName("position");
	setValue(m_selectedIndex, flagName, pos);
}

int MyListModel::getVideoPosition()
{
	const QString flagName("position");
	QVariant v = value(m_selectedIndex, flagName);
	int retValue =  v.toInt();
	return retValue;
}
