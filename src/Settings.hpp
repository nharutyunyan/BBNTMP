/*
 * Settings.hpp
 *
 *  Created on: June 25, 2013
 *      Author: Khartash
 */

#ifndef SETTINGS_HPP_
#define SETTINGS_HPP_
#include <QSettings>
#include <QCoreApplication>

class Settings : public QSettings {
    Q_OBJECT
public:
    Settings(QObject *parent = 0);

    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);

    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = QVariant());
};

#endif /* SETTINGS_HPP_ */
