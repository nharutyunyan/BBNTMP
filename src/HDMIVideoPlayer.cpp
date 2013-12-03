/*
 * HdmiVideoPlayer.cpp
 *
 *  Created on: Aug 28, 2013
 *      Author: martin
 */

#include "HDMIVideoPlayer.hpp"
#include <stdlib.h>
#include <sys/stat.h>
#include <QDebug>

#include <mm/renderer.h>
#include <bps/mmrenderer.h>
#include <bps/screen.h>
#include <errno.h>
#include <sys/strm.h>

// I/O devices
static int app_id = 0;
static const char *video_device_url_template = "screen:?winid=%s&wingrp=%s";
static const char *window_id_name_template = "videosampleVideoWindowId_%d";
static const char *window_group_name_template = "videosamplewindowgroup_%d";  // Window group name
char window_id_name[PATH_MAX];
char window_group_name[PATH_MAX];
char video_device_url[PATH_MAX];

static const char *audio_device_url = "audio:default";

// Name of video context
char video_context_name[PATH_MAX];
static const char *video_context_name_template = "samplevideocontextname_%d";

// TODO: Detect when the video ends

void initWindowIds() {
    int rc;
    srand(1);
    app_id = rand();

    rc = snprintf(video_context_name, PATH_MAX, video_context_name_template, app_id);
    if (rc >= PATH_MAX) {
        fprintf(stderr, "Video context name too long\n");
    }

    rc = snprintf(window_id_name, PATH_MAX, window_id_name_template, app_id);
    if (rc >= PATH_MAX) {
        fprintf(stderr, "Window ID name too long\n");
    }

    rc = snprintf(window_group_name, PATH_MAX, window_group_name_template, app_id);
    if (rc >= PATH_MAX) {
        fprintf(stderr, "Video Window Group name too long\n");
    }

    rc = snprintf(video_device_url, PATH_MAX, video_device_url_template, window_id_name, window_group_name);
    if (rc >= PATH_MAX) {
        fprintf(stderr, "Video device name too long\n");
    }
}


HDMIVideoPlayer::HDMIVideoPlayer(QObject* parent) :
    QObject(parent),
    m_screenContext(NULL),
    m_screenWindow(NULL),
    m_videoWindow(NULL),
    m_mmrConnection(0),
    m_mmrContext(0),
    m_videoDeviceOutputId(-1),
    m_audioDeviceOutputId(-1),
    m_isPlaying(false),
    m_isPaused(false),
    m_isStopped(true) {

    memset(m_screenSize, 0, sizeof(m_screenSize));
}

HDMIVideoPlayer::~HDMIVideoPlayer() {
    qDebug() << "HDMIVideoPlayer::~HDMIVideoPlayer *********************";
    if(m_mmrConnection != 0) {
        stop();
    }

    detroyWindow();
}

void HDMIVideoPlayer::onConnectionChanged(bool connected) {
    if (connected) {
        qDebug() << "Secondary Display Connected ...";
    } else {
        qDebug() << "Secondary Secondary Disconnected...";
        stop();
    }
}

void HDMIVideoPlayer::play(const QString & videoURL) {
    strm_dict_t* dict = NULL;

    if(m_isPlaying) {
        //stop();
    }

    qDebug() << "play videoURL:" << videoURL;

    if(m_screenContext == 0) {
        initWindowIds();
        initExternalDisplay();
    }

    /*
     * Start the playback.
     */
    if (mmr_input_attach(m_mmrContext, videoURL.toStdString().c_str(), "track") != 0) {
        qDebug() << "mmr_input_attach failed";
        return;
    }

    if (mmr_play(m_mmrContext) != 0) {
        qDebug() << "mmr_play failed";
        return;
    }

    /* Do some work to make the aspect ratio correct.
     */
    computeVideoSize();
    dict = initDisplayRect(m_videoSize[0], m_videoSize[1]);
    if (NULL == dict) {
        qDebug() << "initDisplayRect failed";
        return;
    }

    if (mmr_output_parameters(m_mmrContext, m_videoDeviceOutputId, dict) != 0) {
        qDebug() << "mmr_output_parameters failed";
        return;
    }

     /* Note that we allocated memory for the dictionary, but the call to
      * mmr_output_parameters() deallocates that memory even on failure.
      */
    dict = NULL;

    m_isPlaying = true;
    emit playingChanged(m_isPlaying);
}

void HDMIVideoPlayer::initExternalDisplay() {
    /*
     * Create the window used for video output.
     */
    if (screen_create_context(&m_screenContext, SCREEN_APPLICATION_CONTEXT) != 0) {
        return;
    }

    if (screen_create_window(&m_screenWindow, m_screenContext) != 0) {
        screen_destroy_context(m_screenContext);
        return;
    }

    if (screen_create_window_group(m_screenWindow, window_group_name) != 0) {
        return;
    }

    // Move the Window to the 2nd screen if it is active
    pushWindow2SecondScreen(m_screenWindow);

    int format = SCREEN_FORMAT_RGBA8888;
    if (screen_set_window_property_iv(m_screenWindow, SCREEN_PROPERTY_FORMAT, &format) != 0) {
        return;
    }

    int usage = SCREEN_USAGE_NATIVE;
    if (screen_set_window_property_iv(m_screenWindow, SCREEN_PROPERTY_USAGE, &usage) != 0) {
        return;
    }

    // screen_fill does not work on the HDMI screen if we do not set SCREEN_PROPERTY_BUFFER_SIZE
    if (screen_set_window_property_iv(m_screenWindow, SCREEN_PROPERTY_BUFFER_SIZE, m_screenSize) != 0) {
        qDebug() << "SCREEN_PROPERTY_BUFFER_SIZE failed";
        return;
    }

    if (screen_create_window_buffers(m_screenWindow, 1) != 0) {
        qDebug() << "screen_create_window_buffers failed";
        return;
    }

    /*
     * Configure mm-renderer.
     */
    m_mmrConnection = mmr_connect(NULL);
    if (m_mmrConnection == NULL) {
        return;
    }

    m_mmrContext = mmr_context_create(m_mmrConnection, video_context_name, 0, S_IRWXU|S_IRWXG|S_IRWXO);
    if (m_mmrContext == NULL) {
        qDebug() << "mmr_context_create failed";
        return;
    }

    /*
     * Configure video and audio output.
     */
    m_videoDeviceOutputId = mmr_output_attach(m_mmrContext, video_device_url, "video");
    if (m_videoDeviceOutputId == -1) {
        return;
    }

    m_audioDeviceOutputId = mmr_output_attach(m_mmrContext, audio_device_url, "audio");
    if (m_audioDeviceOutputId == -1) {
        return;
    }

    // Get the render buffer
    screen_buffer_t temp_buffer[1];
    if (screen_get_window_property_pv(m_screenWindow, SCREEN_PROPERTY_RENDER_BUFFERS, (void**)temp_buffer) != 0) {
        return;
    }

    // Fill the buffer with with Macadamian Orange
    // TODO: Could we display the Macadamian logo in the background?
    int fill_attributes[3] = {SCREEN_BLIT_COLOR, 0xff000000, SCREEN_BLIT_END};
    if (screen_fill(m_screenContext, temp_buffer[0], fill_attributes) != 0) {
        return;
    }

    // Make the window visible
    int temp_rectangle[4] = {0, 0, m_screenSize[0], m_screenSize[1]};
    if (screen_post_window(m_screenWindow, temp_buffer[0], 1, temp_rectangle, 0) != 0) {
        return;
    }

    // Prevent the backlight from going off
    int idle_mode = SCREEN_IDLE_MODE_KEEP_AWAKE;
    if (screen_set_window_property_iv(m_screenWindow, SCREEN_PROPERTY_IDLE_MODE, &idle_mode) != 0) {
        return;
    }

    bps_initialize();
    subscribe(screen_get_domain());
    subscribe(mmrenderer_get_domain());
    screen_request_events(m_screenContext);
    mmrenderer_request_events(video_context_name, 0, 0);
}

void HDMIVideoPlayer::pushWindow2SecondScreen(screen_window_t screen_window) {
    int displayCount;

    screen_get_context_property_iv(m_screenContext, SCREEN_PROPERTY_DISPLAY_COUNT, &displayCount); // Get Display count
    if(displayCount > 1) { // If there is more than 1 display

        screen_display_t *screen_dpy = (screen_display_t *)calloc(displayCount, sizeof(screen_display_t));
        screen_get_context_property_pv(m_screenContext, SCREEN_PROPERTY_DISPLAYS, (void **) screen_dpy); // Get the displays

        int active = 0;
        screen_get_display_property_iv(screen_dpy[1], SCREEN_PROPERTY_ATTACHED, &active);
        if(active) {
            // If the secondary display is attached
            qDebug() << "2nd display active";
            screen_set_window_property_pv(screen_window, SCREEN_PROPERTY_DISPLAY, (void **) &screen_dpy[1]); // Set the Window on the 2nd display
            screen_get_display_property_iv(screen_dpy[1], SCREEN_PROPERTY_SIZE, m_screenSize);
        } else {
            screen_get_display_property_iv(screen_dpy[0], SCREEN_PROPERTY_SIZE, m_screenSize);
        }

        if(m_screenSize[0] < m_screenSize[1]) {
            int tmp = m_screenSize[1];
            m_screenSize[1] = m_screenSize[0];
            m_screenSize[0] = tmp;
        }

        qDebug() << "m_screenSize " << m_screenSize[0] << "x" << m_screenSize[1];
        free(screen_dpy);
    }
}

strm_dict_t* HDMIVideoPlayer::initDisplayRect(int width, int height) {
    char buffer[16];
    strm_dict_t *dict = strm_dict_new();

    if (NULL == dict) {
        return NULL;
    }

    //fullscreen is the default.
    dict = strm_dict_set(dict, "video_dest_x", videoOffset(m_screenSize[0], m_videoSize[0]));
    if (NULL == dict)
        goto fail;
    dict = strm_dict_set(dict, "video_dest_y", videoOffset(m_screenSize[1], m_videoSize[1]));
    if (NULL == dict)
        goto fail;
    dict = strm_dict_set(dict, "video_dest_w", itoa(width, buffer, 10));
    if (NULL == dict)
        goto fail;
    dict = strm_dict_set(dict, "video_dest_h", itoa(height, buffer, 10));
    if (NULL == dict)
        goto fail;

    return dict;

fail:
    strm_dict_destroy(dict);
    return NULL;
}

void HDMIVideoPlayer::event(bps_event_t *event) {

    if (event == NULL) {
        return;
    }

    if (bps_event_get_domain(event) == screen_get_domain()) {
        screen_event_t screen_event = screen_event_get_event(event);
        int event_type;
        screen_get_event_property_iv(screen_event, SCREEN_PROPERTY_TYPE, &event_type);

        qDebug() << "screen_get_domain event_type:" << event_type;
        if (event_type == SCREEN_EVENT_CREATE) {
            int rc;

            screen_window_t newWindow;
            rc = screen_get_event_property_pv(screen_event, SCREEN_PROPERTY_WINDOW, (void**)&newWindow);
            if (rc != 0) {
                qDebug() << "screen_get_event_property(WINDOW) failed";
                return;
            }

            char id[256];
            rc = screen_get_window_property_cv(newWindow, SCREEN_PROPERTY_ID_STRING, 256, id);
            if (rc != 0) {
                qDebug() << "screen_get_window_property(ID) failed";
                return;
            }

            qDebug() << "window id:" << id;

            if(strncmp(id, window_id_name, strlen(window_id_name)) == 0) {
                // The video window was created
                // We need to push it to the 2nd screen, and move it up the z-order
                qDebug() << "SCREEN_EVENT_CREATE";

                m_videoWindow = newWindow;
                pushWindow2SecondScreen(newWindow);

                int screen_val = 1;
                if (screen_set_window_property_iv(newWindow, SCREEN_PROPERTY_ZORDER, &screen_val) != 0) {
                    qDebug() << "screen_set_window_property(ZORDER) failed";
                    return;
                }

                screen_val = 1;
                if (screen_set_window_property_iv(newWindow, SCREEN_PROPERTY_VISIBLE, &screen_val) != 0) {
                    qDebug() << "screen_set_window_property(VISIBLE) failed";
                    return;
                }

                rc = screen_flush_context(m_screenContext, SCREEN_WAIT_IDLE);
                if (rc != 0) {
                    qDebug() << "Warning: Failed to flush";
                }
            }
        }
    }
    if (bps_event_get_code(event) == MMRENDERER_STATUS_UPDATE) {
        m_position = QString(mmrenderer_event_get_position(event)).toInt();
        emit positionChanged();
    }
    if (bps_event_get_code(event) == MMRENDERER_STATE_CHANGE) {
        if(mmrenderer_event_get_state(event) == MMR_STOPPED)
            m_isStopped = true;
        else
            m_isStopped = false;
        emit stoppedChanged(m_isStopped);
    }
}

void HDMIVideoPlayer::stop() {
    // TODO: Is there a way to fully clear the screen, yet be able to play a 2nd video after?
    qDebug() << "************* stop *****************";
    m_isPlaying = false;
    emit playingChanged(m_isPlaying);

    if (mmr_stop(m_mmrContext) != 0) {
        qDebug() << "mmr_stop Failed";
    }

    if (mmr_output_detach(m_mmrContext, m_audioDeviceOutputId) != 0) {
        qDebug() << "mmr_output_detach audio Failed";
        // Might get MMR_ERROR_UNSUPPORTED_OPERATION(7), just ignore
        const mmr_error_info_t* error = mmr_error_info( m_mmrContext );
        qDebug() << "Error " << error->error_code << " type:" << error->extra_type << ":"
                 << error->extra_value << " extra:" << error->extra_text;
    }

    if (mmr_output_detach(m_mmrContext, m_videoDeviceOutputId) != 0) {
        qDebug() << "mmr_output_detach video Failed";
    }

    int screen_val = false;
    if (screen_set_window_property_iv(m_videoWindow, SCREEN_PROPERTY_VISIBLE, &screen_val) != 0) {
        qDebug() << "screen_set_window_property(HIDDEN) video failed";
        return;
    }

    int rc = screen_flush_context(m_screenContext, SCREEN_WAIT_IDLE);
    if (rc != 0) {
        qDebug() << "Warning: Failed to flush";
    }
}

void HDMIVideoPlayer::detroyWindow() {
    if (m_mmrContext != 0 && mmr_context_destroy(m_mmrContext) != 0) {
        qDebug() << "mmr_context_destroy Failed";
    }

    m_mmrContext = 0;
    m_videoDeviceOutputId = -1;
    m_audioDeviceOutputId = -1;

    mmr_disconnect(m_mmrConnection);
    m_mmrConnection = 0;

    if (screen_stop_events(m_screenContext) != 0) {
        qDebug() << "screen_stop_events Failed";
    } else {
        qDebug() << "screen_stop_events Success";
    }

    unsubscribe(screen_get_domain());
    bps_shutdown();

    if (m_screenWindow != NULL && screen_destroy_window(m_screenWindow) != 0) {
        qDebug() << "screen_destroy_window Failed";
    }

    if (m_screenContext != NULL && screen_destroy_context(m_screenContext) != 0) {
        qDebug() << "screen_destroy_context Failed";
    }

    m_screenContext = 0;
    m_screenWindow = 0;
}

void HDMIVideoPlayer::pause(bool pause) {

    qDebug() << "************* pause *****************";
    // Set the speed to 0 to pause the video initially
    if (mmr_speed_set(m_mmrContext, pause ? 0 : 1000) != 0) {
        qDebug() << "mmr_set_speed(0) failed";
        return;
    }

    m_isPaused = pause;
    emit pausedChanged(m_isPaused);
}

void HDMIVideoPlayer::seekToValue(QString value)
{
    value.truncate(value.indexOf('.'));
    mmr_seek(m_mmrContext, value.toAscii().data());
    m_position = value.toInt();
    emit positionChanged();
}

void HDMIVideoPlayer::computeVideoSize()
{
    float coefX = (float)((float)m_screenSize[0] / (float)m_videoSize[0]);
    float coefY = (float)((float)m_screenSize[1] / (float)m_videoSize[1]);
    if(coefX > coefY) {
        m_videoSize[0] *= coefY;
        m_videoSize[1] *= coefY;
    } else {
        m_videoSize[0] *= coefX;
        m_videoSize[1] *= coefX;
    }
    qDebug() << "Video Window Size : " << m_videoSize[0] << "x" << m_videoSize[1];
}

void HDMIVideoPlayer::setVideoSize(int width, int height)
{
    m_videoSize[0] = width;
    m_videoSize[1] = height;
}

char* HDMIVideoPlayer::videoOffset(int screenDim, int videoDim)
{
    return QString::number((screenDim - videoDim) / 2).toLocal8Bit().data();
}

int HDMIVideoPlayer::position()
{
    return m_position;
}

bool HDMIVideoPlayer::stopped()
{
    return m_isStopped;
}
