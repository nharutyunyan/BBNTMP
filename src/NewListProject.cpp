#include "NewListProject.hpp"
#include "infolistmodel.hpp"

#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>

using namespace bb::cascades;

NewListProject::NewListProject(bb::cascades::Application *app)
: QObject(app)
{
    // register the MyListModel C++ type to be visible in QML
    qmlRegisterType<InfoListModel>("com.rim.example.custom", 1, 0, "InfoListModel");

    // create scene document from main.qml asset
    // set parent to created document to ensure it exists for the whole application lifetime
    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);

    qml->setContextProperty("application", app);

    // create root object for the UI
    AbstractPane *root = qml->createRootObject<AbstractPane>();
    // set created root object as a scene
    app->setScene(root);
}
