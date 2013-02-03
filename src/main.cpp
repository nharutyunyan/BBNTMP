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


	// Create and load the QML file, using build patterns.

    new NewListProject(&app);

    try
    {
    	QStringList result;
		QStringList filters;
		filters << "*.mp4";
		filters << "*.avi";
		FileSystemUtility::getEntryListR("/accounts/1000/shared/videos", filters, result);

		//TODO hard-coded paths must be changed to dynamic.
		QString filename="/accounts/1000/appdata/com.example.VideoTest.testDev_e_VideoTestfba284dc/app/native/assets/mydata.json";
		QFile file(filename);

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

    return Application::exec();
}


