/**
 * @file main.cpp
 * @brief Contains main - the entry point function implementation
 */

#include <bb/cascades/Application>
#include <bb/cascades/QListDataModel>

#include <bb/cascades/ListView>
#include <QVariantList>

#include "NewListProject.hpp"
#include "exceptions.hpp"
#include "utility.hpp"
#include "subtitleManager.hpp"

#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/cascades/AbstractPane>
#include <iostream>


using namespace bb::cascades;
using namespace utility;
using namespace exceptions;


/**
 * Directs the logs to the standard output.
 */

void myMessageOutput(QtMsgType type, const char* msg)
{
    //Lets keep this commented, since it affects the performance.
//    fprintf(stdout, "%s\n", msg);
//    fflush(stdout);
}

int main(int argc, char **argv)
{
    Application app(argc, argv);
    qInstallMsgHandler(myMessageOutput);
    qmlRegisterType<QTimer>("bb.cascades", 1, 0, "QTimer");
    qmlRegisterType<SubtitleManager>("nuttyPlayer", 1, 0, "SubtitleManager");


    QTranslator translator;
    QString locale_string = QLocale().name();
    QString filename = QString( "VideoTest_%1" ).arg( locale_string );
    if (translator.load(filename, "app/native/qm")) {
    	app.installTranslator( &translator );
    }


    try
    {
    	QStringList result;
		QStringList filters;
		filters << "*.mp4";
		filters << "*.avi";
		FileSystemUtility::getEntryListR("/accounts/1000/shared/videos", filters, result);

		QString filename = QDir::home().absoluteFilePath("videoInfoList.json");
		QFile file(filename);
        //TODO: Change this. Though, this will be removed when we get proper handling of video info list
		//(but,even sample data generation can be changed to not create json manually)
		if ( file.open(QIODevice::WriteOnly | QIODevice::Text) )
		{
			QTextStream stream( &file );
			stream << "[" << endl;
			for(int i = 0; i < result.size(); ++i){
				stream << "{" << "\"path\":" << '\"' << result[i] << "\"}";
				if(i != result.size()-1 ) {
					stream << ",\n";
				}
			}
			stream << "]" << endl;
			file.close();
		}
    }
    catch(const exception& e)
    {
    	//do corresponding job
    }

	// Create and load the QML file, using build patterns.

    new NewListProject(&app);

    return Application::exec();
}


