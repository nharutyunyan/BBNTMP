/**
 * @file main.cpp
 * @brief Contains main - the entry point function implementation
 */

#include <bb/cascades/Application>
#include <bb/cascades/QListDataModel>

#include <bb/cascades/ListView>
#include <QVariantList>

#include "window.hpp"
#include "player.hpp"
#include "exceptions.hpp"
#include "utility.hpp"

#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/cascades/AbstractPane>


using namespace bb::cascades;
using namespace utility;
using namespace exceptions;


//TODO for testing purposes only
/*ListView* getListView()
{
	ListView *pListView = new ListView();
	pListView->setDataModel(new QListDataModel<QString>(entries));
	return pListView;
}*/




int main(int argc, char **argv)
{
    Application app(argc, argv);

    QTranslator translator;
    QString locale_string = QLocale().name();
    QString filename = QString( "VideoTest_%1" ).arg( locale_string );
    if (translator.load(filename, "app/native/qm")) {
    	app.installTranslator( &translator );
    }


    //PlayerWindow mainWindow;
	// Create and load the QML file, using build patterns.
    Player player;


    try
    {
    	QStringList result;
		QStringList filters;
		filters << "*.mp4";
		filters << "*.avi";
		bool b = FileSystemUtility::getEntryListR("/accounts/1000/shared/videos", filters, result);

		if(b)
		{
			//TODO for now let's play the first found video
			QString firstVideo = result[0];
    		player.setVideoPath(firstVideo);
		}else{
			QmlDocument *qml = QmlDocument::create("asset:///videoSheet.qml").parent(&player);

			// create root object for the UI
			AbstractPane *root = qml->createRootObject<AbstractPane>();
			// set created root object as a scene
			app.setScene(root);
		}
    }
    catch(const exception& e)
    {
    	//do corresponding job
    }

    return Application::exec();
}


