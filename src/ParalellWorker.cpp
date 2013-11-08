

#include "ParalellWorker.hpp"
#include "infolistmodel.hpp"

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
	QStringList  result = InfoListModel::getVideoFileList();
	emit VideoFileListComplete(result);
}

