/*
 * moviedecoder.cpp
 *
 *  Created on: 07/02/2013
 *      Author: lkarapetyan
 */

#include "moviedecoder.hpp"

#include <algorithm>
#include <iostream>
#include <QVariantList>
#include <Qdir>
#include <bb/data/JsonDataAccess>

extern "C" {
#include <libswscale/swscale.h>
}

static const int THUMBNAIL_SIZE=200;
static const bool MAINTAIN_ASPECT_RATIO = true;

MovieDecoder::MovieDecoder(const std::string& filename, AVFormatContext* pavContext)
: videoStream_(-1)
, pFormatContext_(pavContext)
, pVideoCodecContext_(0)
, pVideoCodec_(0)
, pVideoStream_(0)
, pFrame_(0)
, pFrameBuffer_(0)
, pPacket_(0)
, allowSeek_(true)
{
    initialize(filename);
}

MovieDecoder::~MovieDecoder()
{
	destroy();
}

void MovieDecoder::initialize(const std::string& filename)
{
    av_register_all();
    avcodec_register_all();

    std::string inputFile = filename == "-" ? "pipe:" : filename;

    allowSeek_ = filename.find("rtsp://") != 0;

	if (avformat_open_input(&pFormatContext_, inputFile.c_str(), 0, 0) != 0)
	{
		destroy();
		throw std::logic_error(std::string("Could not open input file: ") + filename);
	}

    // This code helps to generate thumbnail for the .avi video files.
    // It successfully generated them on the simulator but crashed on the device.
//	if (avformat_find_stream_info(pFormatContext_, 0) < 0)
//	{
//		destroy();
//		throw std::logic_error(std::string("Could not find stream information"));
//	}
    initializeVideo();
    pFrame_ = avcodec_alloc_frame();
}

void MovieDecoder::destroy()
{
    if (pVideoCodecContext_)
    {
        avcodec_close(pVideoCodecContext_);
        pVideoCodecContext_ = 0;
    }


    if (pFormatContext_)
    {
        avformat_close_input(&pFormatContext_);
    }

    if (pPacket_)
    {
        av_free_packet(pPacket_);
        delete pPacket_;
        pPacket_ = 0;
    }

    if (pFrame_)
    {
        av_free(pFrame_);
        pFrame_ = 0;
    }

    if (pFrameBuffer_)
    {
        av_free(pFrameBuffer_);
        pFrameBuffer_ = 0;
    }

    videoStream_ = -1;
}

void MovieDecoder::decodeVideoFrame()
{
    bool frameFinished = false;

    while(!frameFinished && getVideoPacket())
    {
        frameFinished = decodeVideoPacket();
    }
    if (!frameFinished)
    {
        throw std::logic_error("decodeVideoFrame() failed: frame not finished");
    }
}

void MovieDecoder::seek(int timeInSeconds)
{
    if (!allowSeek_)
    {
        return;
    }

    int64_t timestamp = AV_TIME_BASE * static_cast<int64_t>(timeInSeconds);

    if (timestamp < 0)
    {
        timestamp = 0;
    }

    int ret = av_seek_frame(pFormatContext_, -1, timestamp, 0);
    if (ret >= 0)
    {
        avcodec_flush_buffers(pFormatContext_->streams[videoStream_]->codec);
    }
    else
    {
        throw std::logic_error("Seeking in video failed");
    }

    int keyFrameAttempts = 0;
    bool gotFrame = 0;

    do
    {
        int count = 0;
        gotFrame = 0;

        while (!gotFrame && count < 20)
        {
            getVideoPacket();
            try
            {
                gotFrame = decodeVideoPacket();
            }
            catch(std::logic_error&) {}
            ++count;
        }

        ++keyFrameAttempts;
    } while ((!gotFrame || !pFrame_->key_frame) && keyFrameAttempts < 200);

    if (gotFrame == 0)
    {
        throw std::logic_error("Seeking in video failed");
    }
}

int MovieDecoder::getDuration(const std::string& videoFile)
{
    if (pFormatContext_)
    {
    	bb::data::JsonDataAccess jda;
    	QString m_file = QDir::home().absoluteFilePath("videoInfoList.json");
    	QVariantList m_list = jda.load(m_file).value<QVariantList>();
    	if (jda.hasError())
    	{
    		bb::data::DataAccessError error = jda.error();
    		qDebug() << m_file << "JSON loading error: " << error.errorType() << ": " << error.errorMessage();
    	}
    	else
    	{
    		qDebug() << m_file << "JSON data loaded OK!";
    	}

    	QVariantList index;
    	for (int ix = 0; ix < m_list.size(); ++ix)
    	{
    		QVariantMap v = m_list[ix].toMap();
    		if (v["path"].toString().compare(videoFile.c_str()) == 0)
    		{
    			//found the video, now get the duration!
    			unsigned long long int duration = v["duration"].toString().toULongLong();
    			return duration/1000;
    		}
    	}
    }

    return 0;
}

void MovieDecoder::getScaledVideoFrame(VideoFrame& videoFrame)
{
    if (pFrame_->interlaced_frame)
    {
        avpicture_deinterlace((AVPicture*) pFrame_, (AVPicture*) pFrame_, pVideoCodecContext_->pix_fmt,
                              pVideoCodecContext_->width, pVideoCodecContext_->height);
    }

    int scaledWidth, scaledHeight;
    convertAndScaleFrame(PIX_FMT_RGB24, scaledWidth, scaledHeight);

    videoFrame.width = scaledWidth;
    videoFrame.height = scaledHeight;
    videoFrame.lineSize = pFrame_->linesize[0];

    videoFrame.frameData.clear();
    videoFrame.frameData.resize(videoFrame.lineSize * videoFrame.height);
    memcpy((&(videoFrame.frameData.front())), pFrame_->data[0], videoFrame.lineSize * videoFrame.height);
}

void MovieDecoder::initializeVideo()
{
    for (unsigned int i = 0; i < pFormatContext_->nb_streams; ++i)
    {
        if (pFormatContext_->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            pVideoStream_ = pFormatContext_->streams[i];
            videoStream_ = i;
            break;
        }
    }

    if (videoStream_ == -1)
    {
        throw std::logic_error("Could not find video stream");
    }

    pVideoCodecContext_ = pFormatContext_->streams[videoStream_]->codec;
    pVideoCodec_ = avcodec_find_decoder(pVideoCodecContext_->codec_id);

    if (pVideoCodec_ == 0)
    {
    	fprintf(stderr, "Codec is not found :((((((");
        // set to NULL, otherwise avcodec_close(pVideoCodecContext_) crashes
        pVideoCodecContext_ = 0;
        throw std::logic_error("Video Codec not found");
    }

    pVideoCodecContext_->workaround_bugs = 1;

	if (avcodec_open2(pVideoCodecContext_, pVideoCodec_, 0) < 0)
    {
		fprintf(stderr, "Successfully opened video codec...");
        throw std::logic_error("Could not open video codec");
    }
}

bool MovieDecoder::getVideoPacket()
{
    bool framesAvailable = true;
    bool frameDecoded = false;

    int attempts = 0;

    if (pPacket_ !=0)
    {
        av_free_packet(pPacket_);
        delete pPacket_;
    }

    pPacket_ = new AVPacket();

    while (framesAvailable && !frameDecoded && (attempts++ < 1000))
    {
        framesAvailable = av_read_frame(pFormatContext_, pPacket_) >= 0;
        if (framesAvailable)
        {
            frameDecoded = pPacket_->stream_index == videoStream_;
            if (!frameDecoded)
            {
                av_free_packet(pPacket_);
            }
        }
    }

    return frameDecoded;
}

bool MovieDecoder::decodeVideoPacket()
{
	if (pPacket_->stream_index != videoStream_)
	{
		return false;
	}

    avcodec_get_frame_defaults(pFrame_);

    int frameFinished;

    int bytesDecoded = avcodec_decode_video2(pVideoCodecContext_, pFrame_, &frameFinished, pPacket_);
    if (bytesDecoded < 0)
    {
        throw std::logic_error("Failed to decode video frame: bytesDecoded < 0");
    }

    return frameFinished > 0;
}

void MovieDecoder::convertAndScaleFrame(PixelFormat format, int& scaledWidth, int& scaledHeight)
{
    calculateDimensions(scaledWidth, scaledHeight);

    SwsContext* scaleContext = sws_getContext(pVideoCodecContext_->width, pVideoCodecContext_->height,
                                              pVideoCodecContext_->pix_fmt, scaledWidth, scaledHeight,
                                              format, SWS_BICUBIC, 0, 0, 0);
    if (0 == scaleContext)
    {
        throw std::logic_error("Failed to create resize context");
    }

    AVFrame* convertedFrame = NULL;
    uint8_t* convertedFrameBuffer = NULL;

    createAVFrame(&convertedFrame, &convertedFrameBuffer, scaledWidth, scaledHeight, format);

    sws_scale(scaleContext, pFrame_->data, pFrame_->linesize, 0, pVideoCodecContext_->height,
              convertedFrame->data, convertedFrame->linesize);
    sws_freeContext(scaleContext);

    av_free(pFrame_);
    av_free(pFrameBuffer_);
    pFrame_ = convertedFrame;
    pFrameBuffer_  = convertedFrameBuffer;
}

void MovieDecoder::calculateDimensions(int& destWidth, int& destHeight)
{
	// The thumbnail size will be 350xABC, where ABC will be decided automatically based on the aspect Ratio
    if (!MAINTAIN_ASPECT_RATIO)
    {
        destWidth = THUMBNAIL_SIZE;
        destHeight = THUMBNAIL_SIZE;
    }
    else
    {
        int srcWidth            = pVideoCodecContext_->width;
        int srcHeight           = pVideoCodecContext_->height;
        int ascpectNominator    = pVideoCodecContext_->sample_aspect_ratio.num;
        int ascpectDenominator  = pVideoCodecContext_->sample_aspect_ratio.den;

        if (ascpectNominator != 0 && ascpectDenominator != 0)
        {
            srcWidth = srcWidth * ascpectNominator / ascpectDenominator;
        }

        if (srcWidth > srcHeight)
        {
            destWidth  = THUMBNAIL_SIZE;
            destHeight = static_cast<int>(static_cast<float>(THUMBNAIL_SIZE) / srcWidth * srcHeight);
        }
        else
        {
            destWidth  = static_cast<int>(static_cast<float>(THUMBNAIL_SIZE) / srcHeight * srcWidth);
            destHeight = THUMBNAIL_SIZE;
        }
    }
}

void MovieDecoder::createAVFrame(AVFrame** pAvFrame, uint8_t** pFrameBuffer, int width, int height, PixelFormat format)
{
    *pAvFrame = avcodec_alloc_frame();

    int numBytes = avpicture_get_size(format, width, height);
    *pFrameBuffer = reinterpret_cast<uint8_t*>(av_malloc(numBytes));
    avpicture_fill((AVPicture*) *pAvFrame, *pFrameBuffer, format, width, height);
}

