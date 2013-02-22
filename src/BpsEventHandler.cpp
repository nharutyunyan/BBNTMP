/*
 * BpsEventHandler.cpp
 *
 *  Created on: 04/02/2013
 *      Author: lkarapetyan
 */

#include <bps/audiomixer.h>
#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <iostream>

#include "BpsEventHandler.hpp"

BpsEventHandler::BpsEventHandler(QObject* parent)
: QObject(parent)
{
    subscribe(navigator_get_domain());
    subscribe(audiomixer_get_domain());
    bps_initialize();
    navigator_request_events(0);
    navigator_stop_swipe_start();
    audiomixer_request_events(0);
}

BpsEventHandler::~BpsEventHandler()
{
    bps_shutdown();
}

void BpsEventHandler::event( bps_event_t *event )
{
    int domain = bps_event_get_domain(event);
    // handle navigator events
    if (domain == navigator_get_domain())
    {
    	if(NAVIGATOR_SWIPE_DOWN == bps_event_get_code(event))
    	{
    		emit showVideoScrollBar();
    	}

    	int code = navigator_event_get_window_state(event);
    	switch(code)
    	{
    	case NAVIGATOR_WINDOW_THUMBNAIL:
    		// The video window has been minimized.
    		// Notify to stop the video if it is playing
    		emit videoWindowStateChanged(true);
    		break;
    	case NAVIGATOR_WINDOW_FULLSCREEN:
    		// The video window has been minimized.
    		// Notify to start playing the paused video
    		emit videoWindowStateChanged(false);
    		break;
    	}
    }

    // handle audiomixer events
    if (domain == audiomixer_get_domain())
    {
    	if (AUDIOMIXER_INFO == bps_event_get_code(event))
    	{
    		// The system volume value has been changed.
    		// Synchronize the volume slider value with the system volume value
    	  	float speaker_volume;
    	    audiomixer_get_output_level(AUDIOMIXER_OUTPUT_SPEAKER, &speaker_volume);
    	    emit speakerVolumeChanged(speaker_volume);
    	}
    }
}

void BpsEventHandler::onVolumeValueChanged(float volumeValue)
{
	// The volume slider value has been changed
	// Synchronize the system volume value with the volume slider value
	audiomixer_set_output_level(AUDIOMIXER_OUTPUT_SPEAKER, volumeValue);
}

float BpsEventHandler::getVolume()
{
	float oldVolume;
	audiomixer_get_output_level(AUDIOMIXER_OUTPUT_SPEAKER, &oldVolume);
	return oldVolume;;
}
