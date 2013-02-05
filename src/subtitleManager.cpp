/*
 * subtitleManager.cpp
 *
 *  Created on: Jan 23, 2013
 *      Author: Narek
 */

#include "subtitleManager.hpp"
#include <QDebug>
#include <QFile>
#include <QStringList>
#include <QTime>
#include <stdio.h>

SubtitleManager::SubtitleManager(QObject* parent): QObject(parent), m_currentText("")
{
	m_currentEntryIndex = 0;
	m_loaded = false;
}

bool SubtitleManager::setSubtitleForVideo(QUrl videoResourceUrl)
{
	QString videoPath = videoResourceUrl.path();
	QString path = videoPath.left(videoPath.lastIndexOf('.')) + ".srt";
	fflush(stdout);
	QFile srtFile (path);
	if(srtFile.exists())
	{
		load(path);
		return true;
	}
	return false;
}

void SubtitleManager::handlePositionChanged(uint pos)
{
	if (!m_loaded)
     return;

	if (pos >= m_entries[m_currentEntryIndex].startTime && pos <= m_entries[m_currentEntryIndex].endTime)
	{
	     QString newText = m_textEntries.mid(m_entries[m_currentEntryIndex].textStartPos,
		 	                              m_entries[m_currentEntryIndex].textEndPos - m_entries[m_currentEntryIndex].textStartPos);
	     if(m_currentText != newText)
	     {
	    	 m_currentText = newText;
	    	 emit textChanged();
	     }
	}
	else if (pos > m_entries[m_currentEntryIndex].endTime)
	{
		if (m_currentEntryIndex < m_entries.size() -1)
		  ++m_currentEntryIndex;
		m_currentText = " "; //hiding the text
		emit textChanged();
	}
	else if (pos < m_entries[m_currentEntryIndex].startTime)
	{
		m_currentText = " ";
		emit textChanged();
	}
}

void SubtitleManager::load(QString fileName)
{
	if (m_loaded)//Reset
	{
		//clear the displayed text
		m_currentText = " ";
		emit textChanged();
		m_currentEntryIndex = 0;
		m_entries.clear();
		m_textEntries.clear();
	}

	QFile in(fileName);
	if(!in.open(QIODevice::ReadOnly))
	{
		qDebug() << "Unable to open subtitle file " <<fileName <<"\n";
	}
	unsigned int textPos = 0;
	while(!in.atEnd())
	{
		SubtitleEntry entry;
		QString line = in.readLine();
		//Just checking ID. No need to be kept so far.
		bool ok = true;
		line.toUInt(&ok);
	    if (!ok)
	    {
	    	qDebug() << "Invalid format of subtitles file \n";
	    	return;
	    }

		line = in.readLine(); //Start, End
		parseTimesLine(line, entry.startTime, entry.endTime);
		entry.textStartPos = textPos;
		//Get texts line by line. Read while the line is not empty
		line = in.readLine();
		while(!in.atEnd() && line.contains(QRegExp("\\w")))
		{
			m_textEntries += line;
			textPos += line.size();
			line = in.readLine();
		}
		entry.textEndPos = textPos;
		m_entries.push_back(entry);
	}
    m_loaded = true;
}

void SubtitleManager::parseTimesLine(const QString& input, uint& start, uint & end)
{
    QStringList tokens = input.split(" --> ");
    if(tokens.size() != 2)
    {
    	qDebug() <<QString("Invalid time line %1 in srt file \n").arg(input);
    	return;
    }
    QTime startTime = QTime::fromString(tokens[0], "hh:mm:ss,zzz");
    QString endTimeStr = tokens[1];

    endTimeStr = endTimeStr.left(endTimeStr.indexOf(',') + 4); //Skipping characters at the end \n, \r , etc..
    QTime endTime   = QTime::fromString(endTimeStr, "hh:mm:ss,zzz");

    start = startTime.hour() * 3600 * 1000 + startTime.minute() * 60 * 1000 + startTime.second() * 1000  + startTime.msec();
    end   = endTime.hour() * 3600 * 1000 + endTime.minute() * 60 * 1000 + endTime.second() * 1000  + endTime.msec();
}

//Using linear search, since the data is not big and the performance is not affected.
void SubtitleManager::seek(uint pos)
{
	if (!m_loaded)
	  return;

	while(1) //loop till return
	{
		if ( pos >= m_entries[m_currentEntryIndex].startTime && pos <= m_entries[m_currentEntryIndex].endTime)
			break;
		else if ( pos < m_entries[m_currentEntryIndex].startTime)
		{
			if (m_currentEntryIndex == 0)
				return;
			else
			{
				--m_currentEntryIndex;
				//Not in any entry range, but current entry is the needed one
				if(pos > m_entries[m_currentEntryIndex].endTime)
					break;
			}
		}
		else if ( pos > m_entries[m_currentEntryIndex].endTime)
		{
			if (m_currentEntryIndex == m_entries.size()-1) //last index
				break;
			else
			{
				++m_currentEntryIndex;
				//Not in any entry range, but current entry is the needed one
				if (pos < m_entries[m_currentEntryIndex].startTime)
					break;
			}
		}
	}
	//update the text
	handlePositionChanged(pos);
}
