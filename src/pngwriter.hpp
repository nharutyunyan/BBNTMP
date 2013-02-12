/*
 * pngwriter.hpp
 *
 *  Created on: 07/02/2013
 *      Author: lkarapetyan
 */

#ifndef PNGWRITER_HPP_
#define PNGWRITER_HPP_

#include <inttypes.h>
#include <png.h>
#include <string>

class PngWriter
{
public:
	PngWriter(const std::string& outputFile);
	~PngWriter();

	void writeFrame(uint8_t** rgbData, int width, int height);

private:
	FILE*          filePtr_;
	png_structp    pngPtr_;
	png_infop      infoPtr_;

private:
    void init();
};

#endif /* PNGWRITER_HPP_ */
