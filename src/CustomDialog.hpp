/*
 * deleteDialog.hpp
 *
 *  Created on: Aug 22, 2013
 *      Author: sbaribeau
 */
#include <bb/system/SystemDialog>
#include <QString>

#ifndef CUSTOMDIALOG_HPP_
#define CUSTOMDIALOG_HPP_


class CustomDialog : public bb::system::SystemDialog
{
	Q_OBJECT
public:
	CustomDialog();
	Q_INVOKABLE void showCustom(QString, QString, QString);
};


#endif /* CUSTOMDIALOG_HPP_ */
