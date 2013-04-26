#include "NuttyPlayer.hpp"
#include "InfoListModel.hpp"

#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>

using namespace bb::cascades;

NuttyPlayer::NuttyPlayer(bb::cascades::Application *app)
: QObject(app)
{
    // create scene document from main.qml asset
    // set parent to created document to ensure it exists for the whole application lifetime
    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);

    qml->setContextProperty("application", app);

    InfoListModel* model = new InfoListModel(this);
    qml->setContextProperty("infoListModel", model);

    // create root object for the UI
    AbstractPane *root = qml->createRootObject<AbstractPane>();
    // set created root object as a scene
    app->setScene(root);
}
