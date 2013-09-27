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

MovieDecoder VideoThumbnailer::movieDecoder;

void VideoThumbnailer::generateThumbnail(const QString& videoFile, const string& outputFile, AVFormatContext* pAvContext)
{
    PngWriter pngWriter (outputFile);
    generateThumbnail(videoFile, pngWriter, outputFile, pAvContext);
}

void VideoThumbnailer::generateThumbnail(const QString& videoFile, PngWriter& pngWriter, const std::string& outputFile, AVFormatContext* pAvContext)
{
	Q_UNUSED(outputFile);

    movieDecoder.setContext(pAvContext);
    try
    {
    	movieDecoder.initialize(videoFile);
    }
    catch (exception& e)
    {
    	// don't try to generate thumbnail if this is not a valid video file!
    	throw(e);
    	return;
    }
    movieDecoder.decodeVideoFrame();

    try
    {
    	// Seek to 20% on the video
        int secondToSeekTo = movieDecoder.getDuration(videoFile) * SEEK_PERCENTAGE / 100;
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
