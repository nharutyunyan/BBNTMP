#ifndef WINDOW_HPP
#define WINDOW_HPP

/**
 * @file window.hpp
 * @brief Holder for UI widget implementation
 */

#include <QtCore/QObject>

namespace bb { namespace cascades { class Application; }}

class PlayerWindow : public QObject
{
    Q_OBJECT

public:
    PlayerWindow(bb::cascades::Application* app);
};

#endif
