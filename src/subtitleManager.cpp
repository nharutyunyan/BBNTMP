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
#include <algorithm>

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
		return load(path);
	}
	return false;
}

bool SubtitleManager::load(QString fileName)
{
	if (m_loaded)//Reset
	{
		//clear the displayed text
		setCurrentText(" ");
		m_currentEntryIndex = 0;
		m_entries.clear();
		m_textEntries.clear();
		m_loaded = false;
	}

	QFile theFile(fileName);
	if(!theFile.open(QIODevice::ReadOnly | QIODevice::Text))
	{
		qDebug() << "Unable to open subtitle file " <<fileName <<"\n";
		return false;
	}
	QTextStream in(&theFile); // prevents app freeze when invalid srt
	unsigned int textPos = 0;
	int invalidLineCounter = 0;
	// If we can't find a valid timestamp line after a while, assume the file is corrupt or wrong format
	// This avoids spending too much time trying to read it
	while(!in.atEnd() && invalidLineCounter < 20)
	{
		SubtitleEntry entry;
		QString line = in.readLine();
		if(!line.contains(" --> "))
		{
			invalidLineCounter++;
			continue;
		}
		if(!parseTimesLine(line, entry.startTime, entry.endTime))
		{
			invalidLineCounter++;
			continue;
		}
		// Since we found a timestamp, reset this counter
		invalidLineCounter = 0;

		entry.textStartPos = textPos;
		//Get texts line by line. Read while the line is not empty
		line = in.readLine();
		while(!in.atEnd() && line.contains(QRegExp("\\w")))
		{
			line = normalizeLine(line);
			m_textEntries += line;
			textPos += line.size();
			line = in.readLine();
		}
		entry.textEndPos = textPos;
		m_entries.push_back(entry);
	}
	if (invalidLineCounter >= 20)
		m_loaded = false;
	else
		m_loaded = true;
    return m_loaded;
}

bool SubtitleManager::parseTimesLine(const QString& input, uint& start, uint & end)
{
    QStringList tokens = input.split(" --> ");
    if(tokens.size() != 2)
    {
    	qDebug() <<QString("Invalid time line %1 in srt file \n").arg(input);
    	return false;
    }
    QTime startTime = QTime::fromString(tokens[0], "hh:mm:ss,zzz");
    QString endTimeStr = tokens[1];

    endTimeStr = endTimeStr.left(endTimeStr.indexOf(',') + 4); //Skipping characters at the end \n, \r , etc..
    QTime endTime   = QTime::fromString(endTimeStr, "hh:mm:ss,zzz");

    start = startTime.hour() * 3600 * 1000 + startTime.minute() * 60 * 1000 + startTime.second() * 1000  + startTime.msec();
    end   = endTime.hour() * 3600 * 1000 + endTime.minute() * 60 * 1000 + endTime.second() * 1000  + endTime.msec();
    if(start > end)
        return false;
    return true;
}

// Finds the appropriate subtitle for the current timestamp (O[n] worst case, O[1] usually)
void SubtitleManager::seek(uint pos)
{
	if (!m_loaded) return;

	// Pos is before the current subtitle (sought backwards)
	if (pos < m_entries[m_currentEntryIndex].startTime)
	{
		// We're after the previous sub, thus between two sentences (or before the first sub), show nothing
		if (m_currentEntryIndex == 0 || pos > m_entries[m_currentEntryIndex-1].endTime)
		{
			setCurrentText(" ");
			return;
		}
		// Else, we must go back one or more sentences
		else
		{
			m_currentEntryIndex = std::max(m_currentEntryIndex-1,0);
			seek(pos);
			return;
		}
	}
	// Pos is after the current subtitle (sought forward)
	if (pos > m_entries[m_currentEntryIndex].endTime)
	{
		// We're before the next sub, thus between two sentences (or after the final sub), show nothing
		if (m_currentEntryIndex+1 == m_entries.size()-1 || pos < m_entries[m_currentEntryIndex+1].startTime)
		{
			setCurrentText(" ");
			return;
		}
		// Else, we must go forward one or more sentences
		else
		{
			m_currentEntryIndex = std::min(m_currentEntryIndex+1,m_entries.size()-1);
			seek(pos);
			return;
		}
	}
	// If we get here, it means we're at the right sub, change if needed!
    QString newText = m_textEntries.mid(m_entries[m_currentEntryIndex].textStartPos,
	 	                              m_entries[m_currentEntryIndex].textEndPos - m_entries[m_currentEntryIndex].textStartPos);
    if(newText.mid(newText.size()-1) == "\n"){
    	newText = newText.mid(0, newText.size() - sizeof('\n'));
    }
    setCurrentText(newText);
}

// Set text and emit a signal if it changed
void SubtitleManager::setCurrentText(QString text)
{
	if (m_currentText != text)
	{
		m_currentText = text;
		emit textChanged();
	}
}

QString SubtitleManager::normalizeLine(QString line)
{
	if(line.contains("<font color=\"")) {
        line.replace("<font color=\"","<p style=\"color:",Qt::CaseSensitive);
        line.replace("</font>","</p>",Qt::CaseSensitive);
	} else if (line.contains("<font color=")) {
        line.replace("<font color=","<p style=\"color:",Qt::CaseSensitive);
        line.insert(line.indexOf(QRegExp("#[A-Fa-f0-9]{6}"),0) + 7,"\"");
        line.replace("</font>","</p>",Qt::CaseSensitive);
	}
	return line;
}
