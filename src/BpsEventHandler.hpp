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
    Q_INVOKABLE void onVolumeSliderValueChanged(float volumeSliderValue);

signals:
  	void speakerVolumeChanged(float speakerVolume);
};

#endif /* BPSEVENTHANDLER_HPP_ */
