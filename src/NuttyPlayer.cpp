#include "NuttyPlayer.hpp"
#include "HDMIScreen.hpp"
#include "Settings.hpp"
#include "Screenshot.hpp"

#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/device/DisplayInfo>
#include <bb/cascades/ActivityIndicator>
#include <bb/cascades/Container>
#include <bb/cascades/SceneCover>

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
    qml->setContextProperty("nuttyplayer", this);

    model = new InfoListModel(this);
    qml->setContextProperty("infoListModel", model);

    passScreenDimensionsToQml(qml);
    HDMIScreen* hdmi = new HDMIScreen(app);
    qml->setContextProperty("HDMIScreen", hdmi);

    // create root object for the UI
    root = qml->createRootObject<AbstractPane>();

	// Check for videos on the phone in the model
	onVideoUpdateNotification();

    // Start the busy animation
    QObject *loadingIndicator = root->findChild<QObject*>("LoadingIndicator");
    if (loadingIndicator)
    	((bb::cascades::ActivityIndicator*)loadingIndicator)->start();

    connect(Application::instance(), SIGNAL(thumbnail()), this, SLOT(onThumbnail()));
    connect(Application::instance(), SIGNAL(awake()), this, SLOT(onAwake()));


	connect(model, SIGNAL(itemsChanged(bb::cascades::DataModelChangeType::Type, QSharedPointer< bb::cascades::DataModel::IndexMapper)),
		  this, SLOT(onVideoUpdateNotification()));
	connect(model, SIGNAL(itemAdded(QVariantList)), this, SLOT(onVideoUpdateNotification()));
	connect(model, SIGNAL(itemRemoved(QVariantList)), this, SLOT(onVideoUpdateNotification()));
}


void NuttyPlayer::onVideoUpdateNotification() {
    // Check for videos on the phone in the model

	Container *noVidLab_cont = root->findChild<Container*>("noVidLabel_obj");

	if(noVidLab_cont) {
		if(model->size() != 0)
			noVidLab_cont->setProperty("visible", false);
		else
			noVidLab_cont->setProperty("visible", true);
	}
}


void NuttyPlayer::onThumbnailsGenerationFinished() {
	thumbnailsGenerationFinished = true;

    // Stop the busy animation.  This may happen before the loading screen ends
    QObject *loadingIndicator = root->findChild<QObject*>("LoadingIndicator");
    if (loadingIndicator)
    	((bb::cascades::ActivityIndicator*)loadingIndicator)->stop();

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

void NuttyPlayer::passScreenDimensionsToQml(bb::cascades::QmlDocument *qml){
    // Tell qml what the size of our device screen is to adjust scaling as needed
    bb::device::DisplayInfo display;

    int width = display.pixelSize().width();
    int height = display.pixelSize().height();

    QDeclarativePropertyMap* displayProperties = new QDeclarativePropertyMap;

    // invert them because the code uses landscape dimensions and display.pixelSize() provides portrait dimensions
    displayProperties->insert("width", QVariant(height));
    displayProperties->insert("height", QVariant(width));

    qml->setContextProperty("displayInfo", displayProperties);
}

void NuttyPlayer::onThumbnail() {
    Settings settings;
    if(!settings.value("inPlayerView").value<bool>()) {
        return;
    }
    QmlDocument *qmlCover = QmlDocument::create("asset:///minimizedPlayerView.qml").parent(this);
    if (!qmlCover->hasErrors()) {
        Container *coverContainer = qmlCover->createRootObject<Container>();
        SceneCover *sceneCover = SceneCover::create().content(coverContainer);
        Application::instance()->setCover(sceneCover);
    }
}

void NuttyPlayer::onAwake() {
    Application::instance()->setCover(0);
}
