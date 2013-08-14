/*
 * HDMIScreen.h
 *
 *  Created on: August 6, 2013
 *      Author: Khartash
 */

#ifndef HDMISCREEN_HPP_
#define HDMISCREEN_HPP_

#include <bb/device/DisplayInfo>
#include <bb/cascades/Application>

using namespace bb::device;
using namespace bb::cascades;

class QObject;
class QThread;

class HDMIScreen : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool connection READ connection NOTIFY connectionChanged FINAL)

public:
    HDMIScreen(Application* app, QObject *parent = 0);
    virtual ~HDMIScreen();

    bool connection();

public slots:
    void setConnection(bool);
signals:
    void connectionChanged(bool);

private:
    DisplayInfo* secondaryDisplay;
    bool m_connection;
};

#endif /* HDMISCREEN_H_ */
