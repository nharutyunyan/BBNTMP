#ifndef NuttyPlayer_HPP_
#define NuttyPlayer_HPP_

#include <QObject>

namespace bb { namespace cascades { class Application; }}

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
};

#endif /* NuttyPlayer_HPP_ */
