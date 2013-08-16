/*
 * Screenshot.cpp
 *
 *  Created on: August 15, 2013
 *      Author: Khartash
 */

#include "Screenshot.hpp"

#include <screen/screen.h>

#include <bb/cascades/Application>
#include <bb/cascades/core/window.h>
using namespace bb::cascades;


Screenshot::Screenshot(QObject* parent) : QObject(parent) {
}

Screenshot::~Screenshot() {
}

int Screenshot::makeScreenShot() {
    /* Variables for setting up taking a screenshot. */
    screen_pixmap_t screen_pix;
    screen_buffer_t screenshot_buf;

    char *screenshot_ptr = NULL;
    int screenshot_stride = 0;

    screen_context_t screenshot_ctx;
    // Create contect
    int rc = screen_create_context(&screenshot_ctx, SCREEN_APPLICATION_CONTEXT);
    if (rc) {
        perror("screen_create_context");
        return EXIT_FAILURE;
    }

    // Get display count
    int count = 0;
    rc = screen_get_context_property_iv(screenshot_ctx, SCREEN_PROPERTY_DISPLAY_COUNT, &count);
    if (rc) {
        perror("screen_get_context_property_iv: SCREEN_PROPERTY_DISPLAY_COUNT");
        return EXIT_FAILURE;
    }

    // Read application main window
    screen_window_t screenshot_win = (screen_window_t) Application::instance()->mainWindow()->handle();
    // Read window size
    int size[2];
    rc = screen_get_window_property_iv(screenshot_win, SCREEN_PROPERTY_BUFFER_SIZE, size);
    if (rc) {
        perror("screen_get_window_property_iv: SCREEN_PROPERTY_BUFFER_SIZE");
        return EXIT_FAILURE;
    }

    // Create pixmap.
    rc = screen_create_pixmap(&screen_pix, screenshot_ctx);
    if (rc) {
        perror("screen_create_pixmap");
        return EXIT_FAILURE;
    }

    /* Set Usage Flags. */
    int usage = SCREEN_USAGE_READ | SCREEN_USAGE_NATIVE;
    rc = screen_set_pixmap_property_iv(screen_pix, SCREEN_PROPERTY_USAGE, &usage);
    if (rc) {
        perror("screen_get_window_property_iv");
        return EXIT_FAILURE;
    }

    /* Set format. */
    int format = SCREEN_FORMAT_RGBA8888;
    rc = screen_set_pixmap_property_iv(screen_pix, SCREEN_PROPERTY_FORMAT, &format);
    if (rc) {
        perror("screen_set_pixmap_property_iv: SCREEN_PROPERTY_FORMAT");
        return EXIT_FAILURE;
    }

    // Set pixmap buffer size
    rc = screen_set_pixmap_property_iv(screen_pix, SCREEN_PROPERTY_BUFFER_SIZE, size);
    if (rc) {
        perror("screen_set_pixmap_property_iv: SCREEN_PROPERTY_BUFFER_SIZE");
        return EXIT_FAILURE;
    }

    // Create pixmap buffer and get handle to the buffer.
    rc = screen_create_pixmap_buffer(screen_pix);
    if (rc) {
        perror("screen_create_pixmap_buffer");
        return EXIT_FAILURE;
    }

    rc = screen_get_pixmap_property_pv(screen_pix, SCREEN_PROPERTY_RENDER_BUFFERS, (void**) &screenshot_buf);
    if (rc) {
        perror("screen_get_pixmap_property_pv: SCREEN_PROPERTY_RENDER_BUFFERS");
        return EXIT_FAILURE;
    }

    // Get a pointer to the buffer.
    rc = screen_get_buffer_property_pv(screenshot_buf, SCREEN_PROPERTY_POINTER, (void**) &screenshot_ptr);
    if (rc) {
        perror("screen_get_buffer_property_pv: SCREEN_PROPERTY_POINTER");
        return EXIT_FAILURE;
    }

    // Get the stride
    rc = screen_get_buffer_property_iv(screenshot_buf, SCREEN_PROPERTY_STRIDE, &screenshot_stride);
    if (rc) {
        perror("screen_get_buffer_property_pv: SCREEN_PROPERTY_STRIDE");
        return EXIT_FAILURE;
    }

    // Take the window screenshot.
    rc = screen_read_window(screenshot_win, screenshot_buf, 0, NULL, 0);
    if (rc) {
        perror("screen_read_window");
        return EXIT_FAILURE;
    }

    // Write the screenshot buffer to a bitmap file
    if (!writePNGFile(size, screenshot_ptr, screenshot_stride)) {
        return EXIT_FAILURE;
    }

    // Perform necessary UI Framework (Screen) clean-up.
    screen_destroy_pixmap(screen_pix);

    return EXIT_SUCCESS;
}

bool Screenshot::writePNGFile(const int size[], const char* screenshot_ptr, const int screenshot_stride) {
    QString strFormat = "PNG";
    int nWidth = size[0];
    int nHeight = size[1];

    QImage *img = new QImage(nWidth, nHeight, QImage::Format_ARGB32);
    unsigned char *tmp = img->bits();
    unsigned int stride = img->bytesPerLine();
    const unsigned int pitch = 4;
    const unsigned int wp = nWidth * pitch;
    unsigned int initial_stride_size = 0;
    unsigned int new_stride_size = 0;

    for (int i = 0; i < nHeight; i++) {
        initial_stride_size = i * screenshot_stride;
        new_stride_size = i * stride;
        for (unsigned int j = 0; j < wp; j += pitch) {
            tmp[new_stride_size + j] = screenshot_ptr[initial_stride_size + j];
            tmp[new_stride_size + j + 1] = screenshot_ptr[initial_stride_size + j + 1];
            tmp[new_stride_size + j + 2] = screenshot_ptr[initial_stride_size + j + 2];
            tmp[new_stride_size + j + 3] = screenshot_ptr[initial_stride_size + j + 3];
        }
    }
    bool bResult = img->save(QDir::home().absoluteFilePath("screenshot.png"), strFormat.toAscii());
    if (!bResult) {
        // unable to take screenshot
    }
    delete img;
    return true;
}

QString Screenshot::getFilename() {
   return QDir::home().absoluteFilePath("screenshot.png");
}
