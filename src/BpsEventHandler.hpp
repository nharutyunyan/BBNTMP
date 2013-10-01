/*
 * BpsEventHandler.hpp
 *
 *  Created on: 04/02/2013
 *      Author: lkarapetyan
 */

#include <bb/Application>
#include <bb/AbstractBpsEventHandler>
#include <bps/bps.h>
#include <bps/navigator.h>
#include <QObject>

#ifndef BPSEVENTHANDLER_HPP_
#define BPSEVENTHANDLER_HPP_

class BpsEventHandler: public QObject, public bb::AbstractBpsEventHandler {
    Q_OBJECT
public:
    explicit BpsEventHandler(QObject* parent = 0);
    virtual ~BpsEventHandler();


    virtual void event(bps_event_t *event);
    Q_INVOKABLE void onVolumeValueChanged(float volumeSliderValue);
    Q_INVOKABLE float getVolume();
    Q_INVOKABLE void startVibration(int intensity, int duration);

signals:
  	void speakerVolumeChanged(float speakerVolume);
  	void videoWindowStateChanged(bool isMinimized); // pass isMinimized true if the app is minimized
  	                                                // if it is fullscreen pass false
  	void deviceLockStateChanged(bool isLocked); // pass isLocked true if the device is locked
      	  	  	  	  	  	  	  	  	  	   // if it is unlocked pass false
  	void showVideoScrollBar();
    void windowInactive();
    void windowActive();
};

#endif /* BPSEVENTHANDLER_HPP_ */
