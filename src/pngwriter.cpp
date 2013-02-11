/*
 * pngwriter.cpp
 *
 *  Created on: 07/02/2013
 *      Author: lkarapetyan
 */

#include "pngwriter.hpp"
#include <png.h>

PngWriter::PngWriter(const std::string& outputFile)
: filePtr_(0)
, pngPtr_(0)
, infoPtr_(0)
{
    init();
	filePtr_ = outputFile == "-" ? stdout : fopen(outputFile.c_str(), "wb");

	if (!filePtr_)
    {
       throw std::logic_error(std::string("Failed to open output file: ") + outputFile);
    }

    png_init_io(pngPtr_, filePtr_);
}

PngWriter::~PngWriter()
{
    if (filePtr_)
    {
        fclose(filePtr_);
    }
	png_destroy_write_struct(&pngPtr_, &infoPtr_);
}

void PngWriter::init()
{
    pngPtr_ = png_create_write_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
	if (!pngPtr_)
	{
		throw std::logic_error("Failed to create png write structure");
	}

	infoPtr_ = png_create_info_struct(pngPtr_);
	if (!infoPtr_)
    {
		png_destroy_write_struct(&pngPtr_, (png_infopp) NULL);
		throw std::logic_error("Failed to create png info structure");
	}
}

void PngWriter::writeFrame(uint8_t** rgbData, int width, int height)
{
    if (setjmp(png_jmpbuf(pngPtr_)))
	{
		throw std::logic_error("Writing png file failed");
	}

	png_set_IHDR(pngPtr_, infoPtr_, width, height, 8,
				 PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE,
				 PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
    png_set_rows(pngPtr_, infoPtr_, rgbData);
    png_write_png(pngPtr_, infoPtr_, 0, 0);
}
