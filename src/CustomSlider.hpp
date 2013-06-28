/*
 * NuttySlider.h
 *
 *  Created on: Jan 27, 2013
 *      Author: bmnatsakanyan
 */

// TODO Clean up

#ifndef CUSTOMSLIDER_H_
#define CUSTOMSLIDER_H_

#include <bb/cascades/CustomControl>
#include <bb/cascades/Image>
#include <QSize>

namespace bb {
    namespace cascades {
        class Container;
        class ImageView;
        class AbsoluteLayoutProperties;
        class LongPressEvent;
        class ImageTracker;
    }
}

class QTimer;

using namespace bb::cascades;

class CustomSlider : public bb::cascades::CustomControl {
    Q_OBJECT

    Q_PROPERTY(float value READ value WRITE setValue NOTIFY valueChanged FINAL)
    Q_PROPERTY(float preferredHeight READ preferredHeight FINAL)
    Q_PROPERTY(float fromValue READ fromValue WRITE setFromValue NOTIFY fromValueChanged FINAL)
    Q_PROPERTY(float toValue READ toValue WRITE setToValue NOTIFY toValueChanged FINAL)
    Q_PROPERTY(float immediateValue READ immediateValue NOTIFY immediateValueChanged FINAL)
    Q_PROPERTY(float x READ x NOTIFY xChanged FINAL)
    Q_PROPERTY(bool dragging READ dragging WRITE setDragging NOTIFY draggingChanged FINAL)
    Q_PROPERTY(QSize handleSize READ handleSize NOTIFY handleSizeChanged FINAL)

public:
    CustomSlider(Container* parent = 0);
    virtual ~CustomSlider(){}

    float value() const;
    float fromValue() const;
    float toValue() const;
    float immediateValue() const;
    float x() const;
    bool dragging() const;
    Q_INVOKABLE float handleLocalX() const;
    Q_INVOKABLE void setLongPressEnabled(bool enabled);

public Q_SLOTS:
    void setValue(float value);
    void setFromValue(float value);
    void setToValue(float value);
    void setDragging(bool draggingState);
    void resetValue();
    void setUpdateInterval(int interval);
    void onHandleLongPressed(bb::cascades::LongPressEvent* event);
    float fromPosXToValue(float positionX) const;
    float fromValueToPosX(float value) const;
    void onHandleImageSizeChanged(int width, int height);
    QSize handleSize() const;

Q_SIGNALS:
    void preferredWidthChanged(float width);
    void valueChanged(float value);
    void fromValueChanged(float value);
    void toValueChanged(float value);
    void immediateValueChanged(float value);
    void xChanged(float x);
    void draggingChanged(bool draggingState);
    void handleLongPressed(float positionX);
    void handleReleased();
    void move(float windowX);
    void press(float windowX);
    void handleSizeChanged(QSize size);

private Q_SLOTS:
    void handleLayoutFrameUpdated(QRectF frame);
    void sliderHandleTouched(bb::cascades::TouchEvent* event);
    void progressBarTouched(bb::cascades::TouchEvent* event);
    void updateHandlePositionX();
    void onDragUpdateTimerTimeout();
    void updateRootContainerPreferredWidth(float width);


private:
    void createConnections();
    void createProgressBar();
    void createHandle();
    void setImmediateValue(float value, bool fireEvent = true);


private:
    // root container
    Container* m_rootContainer;
    float m_rootContainerWidth;
    float m_rootContainerHeight;
    float m_rootContainerPositionX;


    // progress bar
    Container* m_progressBarContainer;
    const float m_progressBarContainerHeight;
    ImageView* m_progressBarImageView;
    Image m_progressBarImage;
    Image m_progressBarImagePressed;

    // handle
    ImageView* m_handle;
    Image m_handleOnImg;
    Image m_handleOffImg;
    QSize m_handleSize;
    ImageTracker* m_handleImageTracker;

    // properties
    float m_value;
    float m_fromValue;
    float m_toValue;
    float m_immediateValue;
    float m_coordinateX;
    bool m_dragging;

    float m_touchEventInitX;
    float m_handleInitX;

    bool m_handleTouched;

    QTimer* m_timer;
    bool m_timerEnabled;

    int m_updateInterval;

    bool m_handleLongPressed;
    Container* m_dummyContainer;

    AbsoluteLayoutProperties* m_handleLayoutProperties;
};

#endif /* CUSTOMSLIDER_H_ */
