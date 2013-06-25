/*
 * Settings.cpp
 *
 *  Created on: June 25, 2013
 *      Author: Khartash
 */

#include "Settings.hpp"

Settings::Settings(QObject *parent) : QSettings(QSettings::IniFormat, QSettings::UserScope,
        QCoreApplication::instance()->organizationName(),
        QCoreApplication::instance()->applicationName(),
        parent)
{}

void Settings::setValue(const QString &key, const QVariant &value) {
    QSettings::setValue(key, value);
}

QVariant Settings::value(const QString &key, const QVariant &value) {
    return QSettings::value(key, value);
}
