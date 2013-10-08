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
#include <bb/system/phone/Phone>

#include "BpsEventHandler.hpp"
#include "exceptions.hpp"
#include "NuttyPlayer.hpp"
#include "utility.hpp"
#include "subtitleManager.hpp"
#include "infolistmodel.hpp"
#include "CustomSlider.hpp"
#include "Settings.hpp"
#include "CustomElapsedTimer.hpp"
#include "System.hpp"

using namespace bb::cascades;
using namespace utility;
using namespace exceptions;

/**
 * Directs the logs to the standard output.
 */

/*
void myMessageOutput(QtMsgType type, const char* msg)
{
    Lets keep this commented, since it affects the performance.
    fprintf(stdout, "%s\n", msg);
    fflush(stdout);
}
*/



Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);
/*
	#ifndef QT_NO_DEBUG
		qInstallMsgHandler(myMessageOutput);
	#endif
*/
    qmlRegisterType<CustomElapsedTimer>("customtimer", 1, 0, "CustomElapsedTimer");
    qmlRegisterType<QTimer>("bb.cascades", 1, 0, "QTimer");
    qmlRegisterType<SubtitleManager>("nuttyPlayer", 1, 0, "SubtitleManager");
    qmlRegisterType<BpsEventHandler>("bpsEventHandler", 1, 0, "BpsEventHandler");
    qmlRegisterType<InfoListModel>("nuttyPlayer", 1, 0, "InfoListModel");
    qmlRegisterType<CustomSlider>("nutty.slider", 1, 0, "CustomSlider");
    qmlRegisterType<Settings>("nuttyPlayer", 1, 0, "Settings");
    qmlRegisterType<bb::system::phone::Phone>("bb.system.phone", 1, 0, "Phone");
    qmlRegisterType<System>("system", 1, 0, "System");

    QTranslator translator;
    QString locale_string = QLocale().name();
    QString filename = QString( "VideoTest_%1" ).arg( locale_string );
    if (translator.load(filename, "app/native/qm")) {
    	app.installTranslator( &translator );
    }

  	// Create and load the QML file, using build patterns.
    new NuttyPlayer(&app);
    app.setAutoExit(false);

    return Application::exec();
}


