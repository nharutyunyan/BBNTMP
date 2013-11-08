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
#include <QDir>
#include <bb/data/JsonDataAccess>
#include <fstream>

extern "C" {
#include <libswscale/swscale.h>
}

static const int THUMBNAIL_SIZE=380;
static const bool MAINTAIN_ASPECT_RATIO = true;

MovieDecoder::MovieDecoder(const QString& filename, AVFormatContext* pavContext)
: videoDuration(-1)
, videoStream(-1)
, pFormatContext(pavContext)
, pVideoCodecContext(0)
, pVideoCodec(0)
, pVideoStream(0)
, pFrame(0)
, pFrameBuffer(0)
, pPacket(0)
, allowSeek(true)
{
    initialize(filename);
}

MovieDecoder::MovieDecoder()
: videoStream(-1)
, pFormatContext(0)
, pVideoCodecContext(0)
, pVideoCodec(0)
, pVideoStream(0)
, pFrame(0)
, pFrameBuffer(0)
, pPacket(0)
, allowSeek(true)
{}

MovieDecoder::~MovieDecoder()
{
	destroy();
}

void MovieDecoder::setContext(AVFormatContext *pavContext)
{
    pFormatContext = pavContext;
}

void MovieDecoder::initialize(const QString& filename)
{
    av_register_all();
    avcodec_register_all();

    QString inputFile = filename == "-" ? "pipe:" : filename;

    if(filename.startsWith("rtsp://"))
    	allowSeek = false;
    else
    	allowSeek = true;

    QFile::remove(QDir::home().absoluteFilePath("templn"));
    QString linkName = QDir::homePath() + '/' + "templn";
    QFile::link(filename, linkName);

	if (avformat_open_input(&pFormatContext, linkName.toStdString().c_str(), 0, 0) != 0)
	{
		destroy();
		throw std::logic_error(std::string("Could not open input file: ") + filename.toStdString());
	}

    // This code helps to generate thumbnail for the .avi video files.
    // It successfully generated them on the simulator but crashed on the device.
//	if (avformat_find_stream_info(pFormatContext, 0) < 0)
//	{
//		destroy();
//		throw std::logic_error(std::string("Could not find stream information"));
//	}
    initializeVideo();
    pFrame = avcodec_alloc_frame();
    setVideosDuration(linkName);
}

void MovieDecoder::destroy()
{
    if (pVideoCodecContext)
    {
        avcodec_close(pVideoCodecContext);
        pVideoCodecContext = 0;
    }


    if (pFormatContext)
    {
        avformat_close_input(&pFormatContext);
    }

    if (pPacket)
    {
        av_free_packet(pPacket);
        delete pPacket;
        pPacket = 0;
    }

    if (pFrame)
    {
        av_free(pFrame);
        pFrame = 0;
    }

    if (pFrameBuffer)
    {
        av_free(pFrameBuffer);
        pFrameBuffer = 0;
    }

    videoStream = -1;
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
    if (!allowSeek)
    {
        return;
    }

    int64_t timestamp = AV_TIME_BASE * static_cast<int64_t>(timeInSeconds);

    if (timestamp < 0)
    {
        timestamp = 0;
    }

    int ret = av_seek_frame(pFormatContext, -1, timestamp, 0);
    if (ret >= 0)
    {
        avcodec_flush_buffers(pFormatContext->streams[videoStream]->codec);
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
    } while ((!gotFrame || !pFrame->key_frame) && keyFrameAttempts < 200);

    if (gotFrame == 0)
    {
        throw std::logic_error("Seeking in video failed");
    }
}

_int64 MovieDecoder::getVideosDuration()
{
	return videoDuration;
}

void MovieDecoder::setVideosDuration(const QString& path)
{
	AVInputFormat* format = pFormatContext->iformat;
	std::string extension( format->name);
	std::string::size_type pos = extension.find(",");
	if(pos != std::string::npos)
		extension = extension.substr(0,pos);
		if(extension == "avi" )
		{
		    int time_delay_between_frames;
			int number_of_frame;

			 QFile tempFile(path);
			 tempFile.open(QIODevice::ReadOnly);
			 tempFile.seek(32);
			 tempFile.read((char*)&time_delay_between_frames,4);
			 tempFile.seek(48);
			 tempFile.read((char*)&number_of_frame,4);

			videoDuration = (_int64)time_delay_between_frames * number_of_frame /1000;
		}
		else if(extension == "asf")
		{
			videoDuration = static_cast<double>(pFormatContext->streams[videoStream]->duration) * static_cast<double>(pVideoCodecContext->ticks_per_frame) / static_cast<double>(pVideoCodecContext->time_base.den);
		}
		else if(extension == "mov")
		{
			videoDuration = pFormatContext->duration / 1000;
		}
		else {
			videoDuration = 0;
		}
}

int MovieDecoder::getDuration(const QString& videoFile)
{
    if (pFormatContext)
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
    		if (v["path"].toString().compare(videoFile) == 0)
    		{
    			//found the video, now get the duration!
    			unsigned long long int duration = v["duration"].toString().toULongLong();
    			return duration/1000;
    		}
    	}
    }

    return 0;
}

int MovieDecoder::getWidth()
{
	decodeVideoFrame();
	return pVideoCodecContext->width;
}

int MovieDecoder::getHeight()
{
	return pVideoCodecContext->height;
}

void MovieDecoder::getScaledVideoFrame(VideoFrame& videoFrame)
{
    if (pFrame->interlaced_frame)
    {
        avpicture_deinterlace((AVPicture*) pFrame, (AVPicture*) pFrame, pVideoCodecContext->pix_fmt,
                              pVideoCodecContext->width, pVideoCodecContext->height);
    }

    int scaledWidth, scaledHeight;
    convertAndScaleFrame(PIX_FMT_RGB24, scaledWidth, scaledHeight);

    videoFrame.width = scaledWidth;
    videoFrame.height = scaledHeight;
    videoFrame.lineSize = pFrame->linesize[0];

    videoFrame.frameData.clear();
    videoFrame.frameData.resize(videoFrame.lineSize * videoFrame.height);
    memcpy((&(videoFrame.frameData.front())), pFrame->data[0], videoFrame.lineSize * videoFrame.height);
}

void MovieDecoder::initializeVideo()
{
    for (unsigned int i = 0; i < pFormatContext->nb_streams; ++i)
    {
        if (pFormatContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            pVideoStream = pFormatContext->streams[i];
            videoStream = i;
            break;
        }
    }

    if (videoStream == -1)
    {
        throw std::logic_error("Could not find video stream");
    }

    pVideoCodecContext = pFormatContext->streams[videoStream]->codec;
    pVideoCodec = avcodec_find_decoder(pVideoCodecContext->codec_id);

    if (pVideoCodec == 0)
    {
    	fprintf(stderr, "Codec is not found :((((((");
        // set to NULL, otherwise avcodec_close(pVideoCodecContext) crashes
        pVideoCodecContext = 0;
        throw std::logic_error("Video Codec not found");
    }

    pVideoCodecContext->workaround_bugs = 1;

	if (avcodec_open2(pVideoCodecContext, pVideoCodec, 0) < 0)
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

    if (pPacket !=0)
    {
        av_free_packet(pPacket);
        delete pPacket;
    }

    pPacket = new AVPacket();

    while (framesAvailable && !frameDecoded && (attempts++ < 1000))
    {
        framesAvailable = av_read_frame(pFormatContext, pPacket) >= 0;
        if (framesAvailable)
        {
            frameDecoded = pPacket->stream_index == videoStream;
            if (!frameDecoded)
            {
                av_free_packet(pPacket);
            }
        }
    }

    return frameDecoded;
}

bool MovieDecoder::decodeVideoPacket()
{
	if (pPacket->stream_index != videoStream)
	{
		return false;
	}

    avcodec_get_frame_defaults(pFrame);

    int frameFinished;

    int bytesDecoded = avcodec_decode_video2(pVideoCodecContext, pFrame, &frameFinished, pPacket);
    if (bytesDecoded < 0)
    {
        throw std::logic_error("Failed to decode video frame: bytesDecoded < 0");
    }

    return frameFinished > 0;
}

void MovieDecoder::convertAndScaleFrame(PixelFormat format, int& scaledWidth, int& scaledHeight)
{
    calculateDimensions(scaledWidth, scaledHeight);

    SwsContext* scaleContext = sws_getContext(pVideoCodecContext->width, pVideoCodecContext->height,
                                              pVideoCodecContext->pix_fmt, scaledWidth, scaledHeight,
                                              format, SWS_BICUBIC, 0, 0, 0);
    if (0 == scaleContext)
    {
        throw std::logic_error("Failed to create resize context");
    }

    AVFrame* convertedFrame = NULL;
    uint8_t* convertedFrameBuffer = NULL;

    createAVFrame(&convertedFrame, &convertedFrameBuffer, scaledWidth, scaledHeight, format);

    sws_scale(scaleContext, pFrame->data, pFrame->linesize, 0, pVideoCodecContext->height,
              convertedFrame->data, convertedFrame->linesize);
    sws_freeContext(scaleContext);

    av_free(pFrame);
    av_free(pFrameBuffer);
    pFrame = convertedFrame;
    pFrameBuffer  = convertedFrameBuffer;
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
        int srcWidth            = pVideoCodecContext->width;
        int srcHeight           = pVideoCodecContext->height;
        int ascpectNominator    = pVideoCodecContext->sample_aspect_ratio.num;
        int ascpectDenominator  = pVideoCodecContext->sample_aspect_ratio.den;

        if (ascpectNominator != 0 && ascpectDenominator != 0)
        {
            srcWidth = srcWidth * ascpectNominator / ascpectDenominator;
        }

        if (srcWidth > srcHeight)
        {
            destWidth  = static_cast<int>(static_cast<float>(THUMBNAIL_SIZE) / srcHeight * srcWidth);
            destHeight = THUMBNAIL_SIZE;
        }
        else
        {
            destWidth  = THUMBNAIL_SIZE;
            destHeight = static_cast<int>(static_cast<float>(THUMBNAIL_SIZE) / srcWidth * srcHeight);
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

