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
#include <sys/strm.h>
#include <mm/renderer.h>
#include <bb/AbstractBpsEventHandler>

/**
 * This class handles playback of the video over the 2nd screen
 * It works over HDMI or Miracast
 * It can continue to play the video while the app is in the background
 * It handles both the audio and the video
 * The UI does not need to display anything other than the playback state, and controls
 */
class HDMIVideoPlayer: public QObject, public bb::AbstractBpsEventHandler  {
    Q_OBJECT

    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged FINAL)
    Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged FINAL)

public:
    HDMIVideoPlayer(QObject* parent);
    virtual ~HDMIVideoPlayer();

    void event(bps_event_t *event);

public slots:
    void onConnectionChanged(bool);

    bool playing() {return m_isPlaying;}
    bool paused() {return m_isPaused;}

    Q_INVOKABLE
    void play(const QString & videoURL);

    Q_INVOKABLE
    void stop();

    /**
     * @param pause: false to resume
     */
    Q_INVOKABLE
    void pause(bool pause);

signals:
	void playingChanged(bool);
	void pausedChanged(bool);

private:
    void initExternalDisplay();
    void detroyWindow();
    void pushWindow2SecondScreen(screen_window_t screen_window);
    strm_dict_t* initDisplayRect(int width, int height);

private:
    int m_screenSize[2];
    screen_context_t m_screenContext;
    screen_window_t m_screenWindow;
    screen_window_t m_videoWindow;
    // Renderer variables
    mmr_connection_t* m_mmrConnection;
    mmr_context_t*    m_mmrContext;

    // I/O variables
    int  m_videoDeviceOutputId;
    int  m_audioDeviceOutputId;
    bool m_isPlaying;
    bool m_isPaused;
};

#endif /* HDMIVIDEOPLAYER_H_ */
