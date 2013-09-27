/*
 * HdmiVideoPlayer.h
 *
 *  Created on: Aug 28, 2013
 *      Author: martin
 */

#ifndef HDMIVIDEOPLAYER_H_
#define HDMIVIDEOPLAYER_H_

#include <QObject>
#include <screen/screen.h>

class HDMIVideoPlayer: public QObject  {
    Q_OBJECT

public:
    HDMIVideoPlayer(QObject* parent);
    virtual ~HDMIVideoPlayer();
    void initExternalDisplay();

signals:
    void hdmiScreenInitialized(QString);

public slots:
    void onConnectionChanged(bool);

private:
    screen_context_t m_screenContextPrimary;
    screen_context_t m_screenContextSecondary;
    screen_window_t m_screenWindowSecondary;
};

#endif /* HDMIVIDEOPLAYER_H_ */
