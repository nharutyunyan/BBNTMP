

#include "ParalellWorker.hpp"

#include <QStringList>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QThread>

using namespace utility;

ParalellWorker::ParalellWorker(QObject *parent) : QObject(parent) {
}

ParalellWorker::~ParalellWorker() {
}

void ParalellWorker::getVideoFileList() {
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

	emit VideoFileListComplete(result);
}

