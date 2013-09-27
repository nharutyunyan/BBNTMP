/*
 * HDMIScreen.cpp
 *
 *  Created on: August 6, 2013
 *      Author: Khartash
 */

#include "HDMIScreen.hpp"
#include <qdebug>

HDMIScreen::HDMIScreen(Application* app, QObject *parent) : QObject(parent) {
    secondaryDisplay = new DisplayInfo(DisplayInfo::secondaryDisplayId(), app);
    m_connection = secondaryDisplay->isAttached();
    // If we are already connected the HDMI then call the slot directly
    if ( secondaryDisplay->isAttached() ) {
        qDebug() << "secondary display name is "
                 << secondaryDisplay->displayName();
        qDebug() << "secondary display size is "
                 << secondaryDisplay->pixelSize().width()
                 << ", " << secondaryDisplay->pixelSize().height();
        setConnection(true);
    }

    // setup signal/slot for changed in the connection
    connect(secondaryDisplay, SIGNAL(attachedChanged(bool)), this, SLOT(setConnection(bool)));
}

HDMIScreen::~HDMIScreen() {
}

void HDMIScreen::setConnection(bool isConnected) {
    if(m_connection == isConnected)
        return;
    m_connection = isConnected;
    emit connectionChanged(m_connection);
}

bool HDMIScreen::connection() {
    return m_connection;
}
