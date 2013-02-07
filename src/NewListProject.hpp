#ifndef NewListProject_HPP_
#define NewListProject_HPP_

#include <QObject>

namespace bb { namespace cascades { class Application; }}

/*
 * Application pane object
 *
 * Use this object to create and init app UI, to create context objects, to register the new meta types etc.
 */
class NewListProject : public QObject
{
    Q_OBJECT

public:
    NewListProject(bb::cascades::Application *app);
    virtual ~NewListProject() {}
};

#endif /* NewListProject_HPP_ */
