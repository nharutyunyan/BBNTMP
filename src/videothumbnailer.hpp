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

    bool generateThumbnail(const QString& videoFile, const std::string& outputFile,AVFormatContext* pAvContext = 0);

private:
    bool generateThumbnail(const QString& videoFile, PngWriter& pngWriter, const std::string& outputFile, AVFormatContext* pAvContext = NULL);
    static MovieDecoder movieDecoder;
};

#endif /* VIDEOTHUMBNAILER_HPP_ */
