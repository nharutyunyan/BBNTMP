/*
 * videothumbnailer.hpp
 *
 *  Created on: 06/02/2013
 *      Author: lkarapetyan
 */

#ifndef VIDEOTHUMBNAILER_HPP_
#define VIDEOTHUMBNAILER_HPP_

#include <string>

#include "moviedecoder.hpp"
#include "pngwriter.hpp"

class VideoThumbnailer
{
public:
    VideoThumbnailer(){}
    ~VideoThumbnailer(){}

    void generateThumbnail(const std::string& videoFile, const std::string& outputFile,AVFormatContext* pAvContext = 0);

private:
    void generateThumbnail(const std::string& videoFile, PngWriter& pngWriter, AVFormatContext* pAvContext = NULL);
};

#endif /* VIDEOTHUMBNAILER_HPP_ */
