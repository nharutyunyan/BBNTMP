/*
 * CustomElapsedTimer.cpp
 *
 *  Created on: Հոկ 7, 2013
 *      Author: Trainee
 */

#include <QDebug>
#include "CustomElapsedTimer.hpp"

CustomElapsedTimer::CustomElapsedTimer(QObject* parent) :  QObject(parent), m_interval(0)
{}

void CustomElapsedTimer::start()
{
  timer.start();
}

void CustomElapsedTimer::restart()
{
  m_interval = timer.restart() ;
  emit intervalChanged();
}

int CustomElapsedTimer::interval()
{
  return m_interval;
}

