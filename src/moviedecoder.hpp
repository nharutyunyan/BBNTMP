/*
 * moviedecoder.hpp
 *
 *  Created on: 07/02/2013
 *      Author: lkarapetyan
 */

#ifndef MOVIEDECODER_HPP_
#define MOVIEDECODER_HPP_

#include <string>

// include math.h otherwise it will get included
// by avformat.h and cause duplicate definition
// errors because of C vs C++ functions
#include <math.h>
extern "C" {
#define UINT64_C uint64_t
#define INT64_C int64_t
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
}

#include "videoframe.h"

struct VideoFrame;

class MovieDecoder
{
public:
    MovieDecoder(const std::string& filename, AVFormatContext* pavContext = 0);
    ~MovieDecoder();
    MovieDecoder();

    void initialize(const std::string& filename);
    void destroy();
    void decodeVideoFrame();
    void seek(int timeInSeconds);
    int getDuration(const std::string& videoFile);
    void getScaledVideoFrame(VideoFrame& videoFrame);
    int getWidth();
    int getHeight();
    void setContext(AVFormatContext* pavContext);
    _int64 getVideosDuration();
    void setVideosDuration(std::string);

private:
    void initializeVideo();
    bool getVideoPacket();
    bool decodeVideoPacket();
    void convertAndScaleFrame(PixelFormat format, int& scaledWidth, int& scaledHeight);
    void calculateDimensions(int& destWidth, int& destHeight);
    void createAVFrame(AVFrame** pAvFrame, uint8_t** pFrameBuffer, int width, int height, PixelFormat format);

private:
    _int64              videoDuration;
    int             	videoStream;
    AVFormatContext*	pFormatContext;
    AVCodecContext* 	pVideoCodecContext;
    AVCodec*            pVideoCodec;
    AVStream*           pVideoStream;
    AVFrame*			pFrame;
    uint8_t*			pFrameBuffer;
    AVPacket*       	pPacket;
    bool                allowSeek;
};


#endif /* MOVIEDECODER_HPP_ */
