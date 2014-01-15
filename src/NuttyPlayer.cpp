#include "NuttyPlayer.hpp"
#include "HDMIScreen.hpp"
#include "HDMIVideoPlayer.hpp"
#include "Settings.hpp"
#include "BbmAppShare.hpp"
#include "ApplicationInfo.hpp"
#include "SubtitleArrayDataModel.h"

#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/device/DisplayInfo>
#include <bb/cascades/ActivityIndicator>
#include <bb/cascades/Container>
#include <bb/cascades/SceneCover>

using namespace bb::cascades;
using namespace bb::system;

const int SPLASHSCREEN_INTERVAL_MIN = 1000;
const int SPLASHSCREEN_INTERVAL_MAX = 3000;

const QString UUID = "8929e8d9-8ab0-43d7-8945-83e702a1dec0";

void passAppVersion(QmlDocument *qml) {
    QString version = ApplicationInfo::getApplicationVersion();

    QDeclarativePropertyMap* appProperties = new QDeclarativePropertyMap;
    appProperties->insert("version", QVariant(version));
    qml->setContextProperty("AppInfo", appProperties);
}

NuttyPlayer::NuttyPlayer(bb::cascades::Application *app)
: QObject(app),
root(NULL),
splashScreenMinimalIntervalElapsed(false),
thumbnailsGenerationFinished(false),
isMinimized(false),
invokedVideo("")
{
	 QTimer::singleShot(SPLASHSCREEN_INTERVAL_MIN, this,
	            SLOT(onSplashscreenMinimalIntervalElapsed()));
	 QTimer::singleShot(SPLASHSCREEN_INTERVAL_MAX, this,
	            SLOT(onSplashscreenMaximalIntervalElapsed()));
    // create scene document from main.qml asset
    // set parent to created document to ensure it exists for the whole application lifetime
    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);

    qmlRegisterType<SubtitleArrayDataModel>("nuttyPlayer", 1, 0, "SubtitleArrayDataModel");

    model = new InfoListModel(this);
    qml->setContextProperty("infoListModel", model);

	qml->setContextProperty("application", app);
	qml->setContextProperty("nuttyplayer", this);

	passScreenDimensionsToQml(qml);

	HDMIScreen* hdmi = new HDMIScreen(app);
	qml->setContextProperty("HDMIScreen", hdmi);
	HDMIVideoPlayer* hdmiPlayer = new HDMIVideoPlayer(app);
	qml->setContextProperty("HDMIPlayer", hdmiPlayer);

	// Connect the HDMI screen to the HDMI player to that it can initialize the
	// HDMI Screen
	bool result = connect (hdmi, SIGNAL(connectionChanged(bool)) , hdmiPlayer, SLOT(onConnectionChanged(bool)));
	Q_ASSERT(result);

	// create root object for the UI
	root = qml->createRootObject<AbstractPane>();
	qml->setContextProperty("_appShare", new BbmAppShare(this, UUID));
	qml->setContextProperty("infoListModel", model);

	passAppVersion(qml);

	// Check for videos on the phone in the model
	onVideoUpdateNotification();

	connect(Application::instance(), SIGNAL(thumbnail()), this, SLOT(onThumbnail()));
	connect(Application::instance(), SIGNAL(awake()), this, SLOT(onAwake()));

	connect(model, SIGNAL(itemsChanged(bb::cascades::DataModelChangeType::Type, QSharedPointer< bb::cascades::DataModel::IndexMapper)),
	  this, SLOT(onVideoUpdateNotification()));
	connect(model, SIGNAL(itemAdded(QVariantList)), this, SLOT(onVideoUpdateNotification()));
	connect(model, SIGNAL(itemRemoved(QVariantList)), this, SLOT(onVideoUpdateNotification()));
}

void NuttyPlayer::onInvoke(const bb::system::InvokeRequest& invoke)
{
    InvokeManager invokeManager;
    if (invokeManager.startupMode() == ApplicationStartupMode::InvokeApplication && invokedVideo == "") {
    	invokedVideo = invoke.uri().toLocalFile();
    } else {
    	invokedVideo = invoke.uri().toLocalFile();
        emit invoked();
    }
}

QString NuttyPlayer::getInvokedVideo() {
	return invokedVideo;
}


void NuttyPlayer::loadingIndicatorStart()
{
	QObject *loadingIndicator = root->findChild<QObject*>("LoadingIndicator");
	if (loadingIndicator)
		((bb::cascades::ActivityIndicator*)loadingIndicator)->start();
}

void NuttyPlayer::loadingIndicatorStop()
{
	QObject *loadingIndicator = root->findChild<QObject*>("LoadingIndicator");
	if (loadingIndicator)
		((bb::cascades::ActivityIndicator*)loadingIndicator)->stop();
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
	loadingIndicatorStop();

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
    QmlDocument *qmlCover = NULL;
    bool isEnabled = false;
    isMinimized = true;

    if(settings.value("inPlayerView").value<bool>()) {
		qmlCover = QmlDocument::create("asset:///minimizedPlayerView.qml").parent(this);
		isEnabled = true;
    } else {
    	QVariantList favorites = model->getFrameVideos();
    	if (favorites.length()!= 0) {
			qmlCover = QmlDocument::create("asset:///minimizedMovieGrid.qml").parent(this);
			isEnabled = true;
    	}
    }
	if (isEnabled && qmlCover != NULL && !qmlCover->hasErrors() ) {
		passScreenDimensionsToQml(qmlCover);
		qmlCover->setContextProperty("infoListModel", model);
        Container *coverContainer = qmlCover->createRootObject<Container>();
        SceneCover *sceneCover = SceneCover::create().content(coverContainer);
        Application::instance()->setCover(sceneCover);
	}

}

void NuttyPlayer::onAwake() {
	if (isMinimized) {
		model->getVideoFiles();
		isMinimized = false;
	}
    Application::instance()->setCover(0);
}
