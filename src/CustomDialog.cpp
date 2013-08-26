/*
 * deleteDialog.cpp
 *
 *  Created on: Aug 22, 2013
 *      Author: sbaribeau
 */
#include "CustomDialog.hpp"

CustomDialog::CustomDialog()
: bb::system::SystemDialog("confirm","custom","cancel")
{
	//this->autoUpdateEnabled = true;
}

void CustomDialog::showCustom(QString confirm, QString custom, QString cancel)
{
	confirmButton()->setLabel(confirm);
	customButton()->setLabel(custom);
	cancelButton()->setLabel(cancel);
	bb::system::SystemDialog::show();
}
