/*
 * HdmiVideoPlayer.cpp
 *
 *  Created on: Aug 28, 2013
 *      Author: martin
 */

#include "HDMIVideoPlayer.hpp"
#include <stdlib.h>
#include <QDebug>

HDMIVideoPlayer::HDMIVideoPlayer(QObject* parent) :
QObject(parent),
m_screenContextPrimary(NULL),
m_screenContextSecondary(NULL),
m_screenWindowSecondary(NULL) {
}

HDMIVideoPlayer::~HDMIVideoPlayer() {
}

void HDMIVideoPlayer::onConnectionChanged(bool connected) {
    if (connected) {
        initExternalDisplay();
        qDebug() << "Secondary Display Connected ...";
        emit hdmiScreenInitialized("screenWindowID");
    } else {
        // TODO: Cleanup if needed
        qDebug() << "Secondary Secondary Disconnected...";
    }
}

void HDMIVideoPlayer::initExternalDisplay() {

    int displayCount;
    // Merge with https://github.com/blackberry/NDK-Samples/tree/master/VideoWindow

    int rect[4] = { 0, 0,0,0 };
    screen_create_context(&m_screenContextPrimary, SCREEN_APPLICATION_CONTEXT);
    screen_get_context_property_iv(m_screenContextPrimary, SCREEN_PROPERTY_DISPLAY_COUNT, &displayCount);
    if ( displayCount > 1 )
    {
        screen_display_t *screen_dpy = (screen_display_t *)calloc(displayCount, sizeof(screen_display_t));
        screen_get_context_property_pv(m_screenContextPrimary, SCREEN_PROPERTY_DISPLAYS, (void **) screen_dpy);
        int active = 0;
        screen_get_display_property_iv(screen_dpy[1], SCREEN_PROPERTY_ATTACHED, &active);
        screen_create_context(&m_screenContextSecondary, SCREEN_APPLICATION_CONTEXT);
        screen_get_context_property_pv(m_screenContextSecondary, SCREEN_PROPERTY_DISPLAYS, (void **) screen_dpy);
        screen_create_window(&m_screenWindowSecondary, m_screenContextSecondary);
        screen_set_window_property_pv(m_screenWindowSecondary, SCREEN_PROPERTY_DISPLAY, (void **) &screen_dpy[1]);

        int usage = SCREEN_USAGE_NATIVE;
        // SCREEN_PROPERTY_ID_STRING

        QString id = "screenWindowID";
        screen_set_window_property_cv(m_screenWindowSecondary, SCREEN_PROPERTY_ID_STRING, id.length(), "screenWindowID");
        screen_set_window_property_iv(m_screenWindowSecondary, SCREEN_PROPERTY_USAGE, &usage);
        screen_get_display_property_iv(screen_dpy[1], SCREEN_PROPERTY_SIZE, rect + 2);
        screen_set_window_property_iv(m_screenWindowSecondary, SCREEN_PROPERTY_BUFFER_SIZE, rect + 2);
        screen_create_window_buffers(m_screenWindowSecondary, 2);
        screen_buffer_t screen_buf[2];
        screen_get_window_property_pv(m_screenWindowSecondary, SCREEN_PROPERTY_RENDER_BUFFERS, (void **) screen_buf);
        screen_get_display_property_iv(screen_dpy[1], SCREEN_PROPERTY_SIZE, rect + 2);
        // Colour the secondary screen with Macadamian Orange
        int bg[] = { SCREEN_BLIT_COLOR, 0xffE85623, SCREEN_BLIT_END };
        screen_fill(m_screenContextSecondary, screen_buf[0], bg);
        screen_post_window(m_screenWindowSecondary, screen_buf[0], 1, rect, 0);
        free(screen_dpy);
    }
}
