


#include <QFileSystemWatcher>
#include <QStringList>
#include <QObject>
#include <QRunnable>
#include <map>

#include "utility.hpp"

class ParalellWorker : public QObject
{
	Q_OBJECT
public:
	ParalellWorker(QObject *parent = 0);
	virtual ~ParalellWorker();

	public slots:
	void getVideoFileList();

	signals:
	void VideoFileListComplete(QStringList);

};

