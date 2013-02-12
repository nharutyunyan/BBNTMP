/*
 * videothumbnailer.cpp
 *
 *  Created on: 06/02/2013
 *      Author: lkarapetyan
 */

#include "videothumbnailer.hpp"
#include "stringoperations.hpp"

#include <cassert>
#include <cfloat>
#include <iostream>
#include <sys/stat.h>

using namespace std;

static const int SEEK_PERCENTAGE = 20;

void VideoThumbnailer::generateThumbnail(const string& videoFile, const string& outputFile, AVFormatContext* pAvContext)
{
    PngWriter* pngWriter = new PngWriter(outputFile);
    generateThumbnail(videoFile, *pngWriter, pAvContext);
    delete pngWriter;
}

void VideoThumbnailer::generateThumbnail(const std::string& videoFile, PngWriter& pngWriter, AVFormatContext* pAvContext)
{
    MovieDecoder movieDecoder(videoFile, pAvContext);
    movieDecoder.decodeVideoFrame(); //before seeking, a frame has to be decoded

    try
    {
    	// Seek to 20% on the video
        int secondToSeekTo = movieDecoder.getDuration() * SEEK_PERCENTAGE / 100;
        movieDecoder.seek(secondToSeekTo);
    }
    catch (exception& e)
    {
        std::cerr << e.what() << ", will use first frame" << std::endl;
        //seeking failed, try the first frame again
        movieDecoder.destroy();
        movieDecoder.initialize(videoFile);
        movieDecoder.decodeVideoFrame();
     }

    VideoFrame  videoFrame;

    movieDecoder.getScaledVideoFrame(videoFrame);

    vector<uint8_t*> rowPointers;
    for (int i = 0; i < videoFrame.height; ++i)
    {
        rowPointers.push_back(&(videoFrame.frameData[i * videoFrame.lineSize]));
    }

    pngWriter.writeFrame(&(rowPointers.front()), videoFrame.width, videoFrame.height);
}
