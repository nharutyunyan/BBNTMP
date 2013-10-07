/*
 * CustomElapsedTimer.hpp
 *
 *  Created on: Հոկ 7, 2013
 *      Author: Trainee
 */

#ifndef CUSTOMELAPSEDTIMER_HPP_
#define CUSTOMELAPSEDTIMER_HPP_

#include <QElapsedTimer>
#include <QObject>

class CustomElapsedTimer : public QObject
{
  Q_OBJECT
   Q_PROPERTY(int interval READ interval NOTIFY intervalChanged FINAL)
private:
  QElapsedTimer timer;
  int m_interval;

public:
  CustomElapsedTimer(QObject* parent = 0);
    Q_INVOKABLE void start();
    Q_INVOKABLE void restart();
    int interval();
Q_SIGNALS:
  void intervalChanged();
};


#endif /* CUSTOMELAPSEDTIMER_HPP_ */
