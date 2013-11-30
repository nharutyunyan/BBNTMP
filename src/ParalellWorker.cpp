

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

void ParalellWorker::getVideoFileList(QString dir) {
	QStringList  result = InfoListModel::getVideoFileList(dir);
	emit VideoFileListComplete(result, dir);
}

