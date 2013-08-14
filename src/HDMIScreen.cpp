/*
 * HDMIScreen.cpp
 *
 *  Created on: August 6, 2013
 *      Author: Khartash
 */

#include "HDMIScreen.hpp"

HDMIScreen::HDMIScreen(Application* app, QObject *parent) : QObject(parent) {
    secondaryDisplay = new DisplayInfo(DisplayInfo::secondaryDisplayId(), app);
    m_connection = secondaryDisplay->isAttached();
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
