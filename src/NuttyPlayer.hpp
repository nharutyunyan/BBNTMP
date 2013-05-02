#ifndef NuttyPlayer_HPP_
#define NuttyPlayer_HPP_

#include <QObject>

namespace bb {
    namespace cascades {
        class Application;
        class AbstractPane;
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

public slots:
    void onSplashscreenMinimalIntervalElapsed();
    void onSplashscreenMaximalIntervalElapsed();
    void onThumbnailsGenerationFinished();

private:
    bb::cascades::AbstractPane *root;
    bool splashScreenMinimalIntervalElapsed;
    bool thumbnailsGenerationFinished;
};

#endif /* NuttyPlayer_HPP_ */
