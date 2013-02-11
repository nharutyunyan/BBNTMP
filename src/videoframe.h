/*
 * videoframe.h
 *
 *  Created on: 07/02/2013
 *      Author: lkarapetyan
 */

#ifndef VIDEOFRAME_H_
#define VIDEOFRAME_H_

#include <inttypes.h>
#include <vector>

struct VideoFrame
{
    VideoFrame()
    : width(0), height(0), lineSize(0) {}

    VideoFrame(int width, int height, int lineSize)
    : width(width), height(height), lineSize(lineSize) {}

    int width;
    int height;
    int lineSize;

    std::vector<uint8_t> frameData;
};

#endif /* VIDEOFRAME_H_ */
