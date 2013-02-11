/**
 * @file main.cpp
 * @brief Contains main - the entry point function implementation
 */

#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/ListView>
#include <bb/cascades/QListDataModel>
#include <bb/cascades/QmlDocument>
#include <iostream>
#include <QVariantList>

#include "BpsEventHandler.hpp"
#include "exceptions.hpp"
#include "NewListProject.hpp"
#include "utility.hpp"
#include "subtitleManager.hpp"
#include "mylistmodel.hpp"

using namespace bb::cascades;
using namespace utility;
using namespace exceptions;

/**
 * Directs the logs to the standard output.
 */
void myMessageOutput(QtMsgType type, const char* msg)
{
    //Lets keep this commented, since it affects the performance.
    fprintf(stdout, "%s\n", msg);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    Application app(argc, argv);
    qInstallMsgHandler(myMessageOutput);
    qmlRegisterType<QTimer>("bb.cascades", 1, 0, "QTimer");
    qmlRegisterType<SubtitleManager>("nuttyPlayer", 1, 0, "SubtitleManager");
    qmlRegisterType<BpsEventHandler>("bpsEventHandler", 1, 0, "BpsEventHandler");
    qmlRegisterType<InfoListModel>("nuttyPlayer", 1, 0, "InfoListModel");

    QTranslator translator;
    QString locale_string = QLocale().name();
    QString filename = QString( "VideoTest_%1" ).arg( locale_string );
    if (translator.load(filename, "app/native/qm")) {
    	app.installTranslator( &translator );
    }

  	// Create and load the QML file, using build patterns.
    new NewListProject(&app);
    app.setAutoExit(false);

    return Application::exec();
}


