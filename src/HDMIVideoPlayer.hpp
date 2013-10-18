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
    Q_PROPERTY(bool stopped READ stopped NOTIFY stoppedChanged FINAL)
    Q_PROPERTY(int position READ position NOTIFY positionChanged FINAL)

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

    Q_INVOKABLE
    void seekToValue(QString value);

    Q_INVOKABLE
    void setVideoSize(int width, int height);

    Q_INVOKABLE
    int position();

    Q_INVOKABLE
    bool stopped();

signals:
    void playingChanged(bool);
    void pausedChanged(bool);
    void stoppedChanged(bool);
    void positionChanged();

private:
    void initExternalDisplay();
    void detroyWindow();
    void pushWindow2SecondScreen(screen_window_t screen_window);
    strm_dict_t* initDisplayRect(int width, int height);
    void computeVideoSize();
    char* videoOffset(int screenDim, int videoDim);

private:
    int m_screenSize[2];
    int m_videoSize[2];
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
    bool m_isStopped;
    int m_position;
};

#endif /* HDMIVIDEOPLAYER_H_ */
