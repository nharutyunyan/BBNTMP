/*
 * subtitleManager.h
 *
 *  Created on: Jan 23, 2013
 *      Author: Narek
 */
/**
 * @file subtitleManager.h
 * @brief Implemetns the subtitle related functionality.
 */

#ifndef SUBTITLEMANAGER_H_
#define SUBTITLEMANAGER_H_

#include <QObject>
#include <QVector>
#include <QUrl>

struct SubtitleEntry;
/**
 * @brief class SubtitleManager
 * @details The class holds the subtitle support mechanism. It is being instantiated in qml, which provides track position updates.
 *          The routine updates the 'text' property according to the position.
 */
class SubtitleManager : public QObject
{
	Q_OBJECT
public:
	SubtitleManager(QObject* parent = 0);

	/**
	 * @brief Current text (subtitle) to display.
	 * @details The appropriate UI control will use this property to display the text
	 */
	Q_PROPERTY(QString text READ text NOTIFY textChanged);

	QString text() { return m_currentText; }

	    /**
		 * @brief Finds and updates the text according to the current track pos
		 * @param pos  Position in msecs of the current track.
		 */
		Q_INVOKABLE void handlePositionChanged(uint pos);
		/**
		 * @brief Finds srt file and loads it
		 * @details The search of srt file is based on video file name.
		 * @param videoResourceUrl  Path to vide file
		 * @return returns true if the file is found, otherwise returns false
		 */
		Q_INVOKABLE bool setSubtitleForVideo(QUrl videoResourceUrl);

		/**
		 * @brief Seeks correct index for subtitle entry according to the pos.
		 * @param pos  Position in msecs of the current track.
		 */
		Q_INVOKABLE void seek(uint pos);

signals:
	void textChanged();


private:
	void load(QString fileName);
	void parseTimesLine(const QString&, uint& start, uint& end);

	QString m_currentText;
	QVector<SubtitleEntry> m_entries;
	QString m_textEntries;

	int m_currentEntryIndex;
	bool m_loaded;
};


struct SubtitleEntry
{
	uint startTime;
	uint endTime;
	uint textStartPos;
	uint textEndPos;
};

#endif /* SUBTITLEMANAGER_H_ */
