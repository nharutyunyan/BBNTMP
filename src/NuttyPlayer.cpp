#include "NuttyPlayer.hpp"
#include "InfoListModel.hpp"

#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>

using namespace bb::cascades;

const int SPLASHSCREEN_INTERVAL_MIN = 4000;
const int SPLASHSCREEN_INTERVAL_MAX = 8000;

NuttyPlayer::NuttyPlayer(bb::cascades::Application *app)
: QObject(app),
root(NULL),
splashScreenMinimalIntervalElapsed(false),
thumbnailsGenerationFinished(false)
{
	 QTimer::singleShot(SPLASHSCREEN_INTERVAL_MIN, this,
	            SLOT(onSplashscreenMinimalIntervalElapsed()));
	 QTimer::singleShot(SPLASHSCREEN_INTERVAL_MAX, this,
	            SLOT(onSplashscreenMaximalIntervalElapsed()));
    // create scene document from main.qml asset
    // set parent to created document to ensure it exists for the whole application lifetime
    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);

    qml->setContextProperty("application", app);

    InfoListModel* model = new InfoListModel(this);
    qml->setContextProperty("infoListModel", model);

    // create root object for the UI
    root = qml->createRootObject<AbstractPane>();
}

void NuttyPlayer::onThumbnailsGenerationFinished() {
	thumbnailsGenerationFinished = true;
    // set created root object as a scene
    if (splashScreenMinimalIntervalElapsed)
        Application::instance()->setScene(root);
}

void NuttyPlayer::onSplashscreenMinimalIntervalElapsed() {
    splashScreenMinimalIntervalElapsed = true;
    // set created root object as a scene
    if (thumbnailsGenerationFinished)
    	Application::instance()->setScene(root);
}

void NuttyPlayer::onSplashscreenMaximalIntervalElapsed() {
    // In case somehow we are still waiting for the response simply start the scene
	if (!thumbnailsGenerationFinished)
        Application::instance()->setScene(root);
}
