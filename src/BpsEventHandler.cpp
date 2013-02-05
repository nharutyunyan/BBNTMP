/*
 * BpsEventHandler.cpp
 *
 *  Created on: 04/02/2013
 *      Author: lkarapetyan
 */

#include <bps/audiomixer.h>
#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>

#include "BpsEventHandler.hpp"
#include "NewListProject.hpp"

BpsEventHandler::BpsEventHandler(QObject* parent)
: QObject(parent)
{
    subscribe(navigator_get_domain());
    subscribe(audiomixer_get_domain());
    bps_initialize();
    navigator_request_events(0);
    audiomixer_request_events(0);
}

BpsEventHandler::~BpsEventHandler() {
    bps_shutdown();
}

void BpsEventHandler::event( bps_event_t *event ) {
    int domain = bps_event_get_domain(event);
    // un-comment this code if there are navigation events to be handled
    /*if (domain == navigator_get_domain()) {
        int code = bps_event_get_code(event);
        switch(code) {
        case AUDIO:
            break;
        default:
            break;
        }
    }*/
    if (domain == audiomixer_get_domain()) {
    	if (AUDIOMIXER_INFO == bps_event_get_code(event)) {
    		// The system volume value has been changed.
    		// Synchronize the volume slider value with the system volume value
    	  	float speaker_volume;
    	    audiomixer_get_output_level(AUDIOMIXER_OUTPUT_SPEAKER, &speaker_volume);
    	    emit speakerVolumeChanged(speaker_volume);
    		}
    	}
}

void BpsEventHandler::sliderValueChanged(float sliderValue)
{
	// The volume slider value has been changed
	// Synchronize the system volume value with the volume slider value
	audiomixer_set_output_level(AUDIOMIXER_OUTPUT_SPEAKER, sliderValue);
}
