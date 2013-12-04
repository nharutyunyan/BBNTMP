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
#include <QDebug>

using namespace std;

static const float SEEK_PERCENTAGE = 0.2;

MovieDecoder VideoThumbnailer::movieDecoder;

bool VideoThumbnailer::generateThumbnail(const QString& videoFile, const string& outputFile, int duration, AVFormatContext* pAvContext)
{
    PngWriter pngWriter (outputFile);
    return generateThumbnail(videoFile, pngWriter, outputFile, duration, pAvContext);
}

bool VideoThumbnailer::generateThumbnail(const QString& videoFile, PngWriter& pngWriter, const std::string& outputFile, int duration, AVFormatContext* pAvContext)
{
	Q_UNUSED(outputFile);

    movieDecoder.setContext(pAvContext);
    try
    {
    	movieDecoder.initialize(videoFile);
    }
    catch (exception& e)
    {
    	return false;
    }
    movieDecoder.decodeVideoFrame();

    try
    {
    	// Seek to 20% on the video
        int secondToSeekTo = duration * SEEK_PERCENTAGE;
        if (secondToSeekTo == 0)
        	qDebug()<<"!!videoFile: "<<videoFile;
        movieDecoder.seek(secondToSeekTo);
    }
    catch (exception& e)
    {
        qDebug() << e.what() << ", will use first frame";
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

    return true;
}
