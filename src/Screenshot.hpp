/*
 * Screenshot.hpp
 *
 *  Created on: August 15, 2013
 *      Author: Khartash
 */

#ifndef SCREENSHOT_HPP_
#define SCREENSHOT_HPP_
#include <QObject>

class Screenshot : public QObject {
	Q_OBJECT

public:
	Screenshot(QObject* parent = 0);
	virtual ~Screenshot();
	Q_INVOKABLE int makeScreenShot();

	bool writePNGFile(const int size[], const char* screenshot_ptr, const int screenshot_stride);

	Q_INVOKABLE QString getFilename();
};

#endif /* SCREENSHOT_HPP_ */
