#ifndef PLAYER_HPP
#define PLAYER_HPP

/**
 * @file player.hpp
 * @brief Contains the implementation of video player functionality
 */

#include <QtCore/QObject>

#include <mm/renderer.h>
#include <bps/bps.h>
#include <bps/screen.h>
#include <stdlib.h>

#include <bb/multimedia/MediaPlayer>

namespace bb { namespace cascades { class AbstractPane; }}
namespace bb { namespace cascades { class Sheet; }}
namespace bb { namespace cascades { class Slider; }}
namespace bb { namespace cascades { class Container; }}
namespace bb { namespace multimedia { class MediaPlayer; }}


class Player : public QObject
{
    Q_OBJECT

public:
    Player();
    void runPlayer(const QString&);
    ~Player();

    Q_INVOKABLE QString getVideoPath(void);
    Q_INVOKABLE QString getNextVideoPath(void);
    Q_INVOKABLE QString getPreviousVideoPath(void);
    Q_INVOKABLE QString getFormattedTime(int msecs);

    void setVideoPaths(QStringList videoPaths);
    void setCurrentVideoIndex(int index);

public slots:
	void playbackCompleted();

private:
    void connectToMMR();
    void configureAudioVideo();
    void startPlayback(const QString&);
    void handleKeyboardEvents();
    void detachFromMMR();
    void createWindow();
    void makeWindowVisible();
    void destroyScreen();


    clock_t mStartTime;
    int errorCode;

    // Renderer variables
	mmr_connection_t*   mmr_connection;
    mmr_context_t*      mmr_context;

    // Screen variables
    screen_context_t    screen_context;
    screen_window_t     screen_window;

	// I/O variables
	int                 video_device_output_id;
	int                 audio_device_output_id;

	// I/O devices
	static const char *video_device_url;
	static const char *audio_device_url;
	static const char *window_group_name;

	bb::cascades::Sheet* mVideoSheet;
	bb::cascades::Slider* mSlider;
	bb::cascades::AbstractPane *mRoot;

	int mCurrentVideoIndex;
	QStringList mVideoPaths;

};

#endif /* PLAYER_HPP */
