#ifndef NuttyPlayer_HPP_
#define NuttyPlayer_HPP_

#include <QObject>
#include <bb/system/InvokeManager>
#include <bb/system/InvokeRequest>

#include "infolistmodel.hpp"

namespace bb {
    namespace cascades {
        class Application;
        class AbstractPane;
        class QmlDocument;
    }
}
/*
 * Application pane object
 *
 * Use this object to create and init app UI, to create context objects, to register the new meta types etc.
 */
class NuttyPlayer : public QObject
{
    Q_OBJECT

public:
    NuttyPlayer(bb::cascades::Application *app);
    virtual ~NuttyPlayer() {}
    void passScreenDimensionsToQml(bb::cascades::QmlDocument *qml);

    Q_INVOKABLE QString getInvokedVideo();

public slots:
    void onSplashscreenMinimalIntervalElapsed();
    void onSplashscreenMaximalIntervalElapsed();
    void onThumbnailsGenerationFinished();
    void onThumbnail();
    void onAwake();
    void onVideoUpdateNotification();
    void loadingIndicatorStart();
    void loadingIndicatorStop();
    void onInvoke(const bb::system::InvokeRequest&);
    signals:
    	void invoked();


private:
    bb::cascades::AbstractPane *root;
    bool splashScreenMinimalIntervalElapsed;
    bool thumbnailsGenerationFinished;
    bool isMinimized;
    InfoListModel* model;
    QString invokedVideo;
};

#endif /* NuttyPlayer_HPP_ */
