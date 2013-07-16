/*
 * NuttySlider.cpp
 *
 *  Created on: Jan 27, 2013
 *      Author: bmnatsakanyan
 */

// TODO Clean up
#include "CustomSlider.hpp"
#include <bb/cascades/Container>
#include <bb/cascades/DockLayout>
#include <bb/cascades/ImageView>
#include <bb/cascades/AbsoluteLayout>
#include <bb/cascades/Color>
#include <bb/cascades/LayoutUpdateHandler>
#include <bb/cascades/AbsoluteLayoutProperties>
#include <bb/cascades/TouchBehavior>
#include <bb/cascades/LongPressHandler>
#include <bb/cascades/LongPressEvent>
#include <bb/cascades/ImageTracker>

CustomSlider::CustomSlider(Container* parent)
    :CustomControl(parent),
     m_rootContainerHeight(105),
     m_progressBarContainerHeight(15),
     m_fromValue(0.0),
     m_coordinateX(0.0),
     m_toValue(1.0)
{
    setUpdateInterval(0);
    setPreferredHeight(m_rootContainerHeight);
    m_rootContainer = Container::create()
                  .layout(new AbsoluteLayout())
                  .preferredHeight(m_rootContainerHeight)
                  .background(Color::fromARGB(0x10f2eded));

    m_rootContainer->setMaxHeight(m_rootContainerHeight);

    createProgressBar();
    createHandle();
    m_dummyContainer = Container::create()
                  .layout(new AbsoluteLayout())
                  .background(Color::fromARGB(0x000088cc));
    m_dummyContainer->addTouchBehavior(
        TouchBehavior::create()
            .addTouchReaction(TouchType::Down,
                              PropagationPhase::AtTarget,
                              TouchResponse::StartTracking));
//    m_rootContainer->addTouchBehavior(
//        TouchBehavior::create()
//            .addTouchReaction(TouchType::Down,
//                              PropagationPhase::Bubbling,
//                              TouchResponse::StartTracking));


    m_rootContainer->add(m_progressBarContainer);
    m_rootContainer->add(m_dummyContainer);
    m_rootContainer->add(m_handle);
    setRoot(m_rootContainer);

    m_timer = new QTimer(this);
    m_timer->setSingleShot(true);
    createConnections();
}

bool CustomSlider::mediaState()
{
	return m_mediastate;
}

void CustomSlider::setMediaState(bool state)
{
	m_mediastate = state;
	emit mediaStateChanged();
}

float CustomSlider::value() const
{
    return m_value;
}

void CustomSlider::setValue(float value)
{
	 m_value = value;
	 m_immediateValue = value;
	 updateHandlePositionX(m_value);
}

float CustomSlider::fromValue() const
{
    return m_fromValue;
}

void CustomSlider::setFromValue(float value)
{
    if(m_fromValue == value)
        return;

    m_fromValue = value;
}

float CustomSlider::toValue() const
{
    return m_toValue;
}

void CustomSlider::setToValue(float value)
{
    if(m_toValue == value)
        return;

    m_toValue = value;

}

float CustomSlider::immediateValue() const
{
    return m_immediateValue;
}

void CustomSlider::setImmediateValue(float value)
{
    if(m_immediateValue == value)
        return;

    m_immediateValue = value;
    m_value = value;
    updateHandlePositionX(m_immediateValue);
    emit immediateValueChanged();
}

void CustomSlider::resetValue()
{
    setValue(m_fromValue);
}

void CustomSlider::handleLayoutFrameUpdated(QRectF frame)
{
    m_progressBarContainer->setPreferredWidth(frame.width() - m_rootContainerHeight);
    m_rootContainerWidth = frame.width();
    m_rootContainerHeight = frame.height();
    m_rootContainerPositionX = frame.x();
    m_dummyContainer->setPreferredWidth(m_rootContainerWidth);
    m_dummyContainer->setPreferredHeight(m_rootContainerHeight);
    updateHandlePositionX(m_value);
}

void CustomSlider::createConnections()
{
    LayoutUpdateHandler::create(m_rootContainer)
        .onLayoutFrameChanged(this, SLOT(handleLayoutFrameUpdated(QRectF)));
    connect(m_handle, SIGNAL(touch(bb::cascades::TouchEvent*)),
            this, SLOT(sliderHandleTouched(bb::cascades::TouchEvent*)));
    //connect(this, SIGNAL(immediateValueChanged(float)), this, SLOT(updateHandlePositionX()));
    //connect(this, SIGNAL(toValueChanged(float)), this, SLOT(updateHandlePositionX()));
    connect(m_dummyContainer, SIGNAL(touch(bb::cascades::TouchEvent*)),
            this, SLOT(progressBarTouched(bb::cascades::TouchEvent*)));
    connect(this, SIGNAL(preferredWidthChanged(float)), this, SLOT(updateRootContainerPreferredWidth(float)));


    bool result = connect(m_handleImageTracker, SIGNAL(sizeChanged(int, int)),
                    this, SLOT(onHandleImageSizeChanged(int, int)));
    Q_ASSERT(result);
    Q_UNUSED(result);
}

void CustomSlider::createProgressBar()
{
    AbsoluteLayoutProperties* layoutProperties
                            = AbsoluteLayoutProperties::create();
    layoutProperties->setPositionX(m_rootContainerHeight / 2);
    layoutProperties->setPositionY((m_rootContainerHeight
                                    - m_progressBarContainerHeight) / 2);

    m_progressBarContainer = Container::create()
                    .layout(new DockLayout())
                    .layoutProperties(layoutProperties)
                    .preferredHeight(m_progressBarContainerHeight)
                    .background(Color::fromARGB(0xfffddded));

    ImageView* barImageView =
            ImageView::create("asset:///images/bar.amd")
                                    .preferredHeight(m_progressBarContainerHeight)
                                    .horizontal(HorizontalAlignment::Fill)
                                    .vertical(VerticalAlignment::Center);

    m_progressBarImage = bb::cascades
                 ::Image(QUrl("asset:///images/progress.amd"));
    m_progressBarImagePressed = bb::cascades
                  ::Image(QUrl("asset:///images/progress_pressed.amd"));
    m_progressBarImageView = ImageView::create()
                                    .preferredHeight(m_progressBarContainerHeight)
                                    .horizontal(HorizontalAlignment::Left)
                                    .vertical(VerticalAlignment::Center);
    m_progressBarImageView->setImage(m_progressBarImage);
    m_progressBarImageView->setImplicitLayoutAnimationsEnabled(false);

    m_progressBarContainer->add(barImageView);
    m_progressBarContainer->add(m_progressBarImageView);
}

void CustomSlider::createHandle()
{
    m_handleOnImg = bb::cascades
                 ::Image(QUrl("asset:///images/Player/SliderPointerPrecision.png"));
    m_handleOffImg = bb::cascades
                  ::Image(QUrl("asset:///images/Player/SliderPointer.png"));

    m_handle = ImageView::create()
               .preferredWidth(m_rootContainerHeight)
               .preferredHeight(m_rootContainerHeight);

    m_handleImageTracker = new ImageTracker(m_handleOnImg.source());


    m_handleLayoutProperties = AbsoluteLayoutProperties::create();
    m_handle->setLayoutProperties(m_handleLayoutProperties);

    m_handle->setImage(m_handleOffImg);
    m_handle->setImplicitLayoutAnimationsEnabled(false);

    m_handle->addTouchBehavior(
        TouchBehavior::create()
            .addTouchReaction(TouchType::Down,
                              PropagationPhase::AtTarget,
                              TouchResponse::StartTracking));
    LongPressHandler* longPressHandler = LongPressHandler::create()
        .onLongPressed(this, SLOT(onHandleLongPressed(bb::cascades::LongPressEvent*)));
    m_handle->addGestureHandler(longPressHandler);
}

void CustomSlider::sliderHandleTouched(TouchEvent* event)
{
    if(event->propagationPhase() == PropagationPhase::AtTarget && isEnabled()) {
        m_handleTouched = true;
        TouchType::Type type  = event->touchType();


        if(TouchType::Down == type) {
        	setMediaState(true);
            m_progressBarImageView->setImage(m_progressBarImagePressed);
            m_handle->setImage(m_handleOnImg);
            m_touchEventInitX = event->windowX();

            m_handleInitX = m_handleLayoutProperties->positionX() + m_rootContainerPositionX;
            return;
        }

        float handlePosX = m_handleInitX - m_touchEventInitX + event->windowX();

        if(TouchType::Move == type) {
            if(!m_handleLongPressed) {
                if(!m_timer->isActive()) {
                	setImmediateValue(fromPosXToValue(handlePosX));
                    m_timer->start(m_updateInterval);
                }

                return;
            }
            else {
                emit move(event->windowX());
            }
        }
        else

        if(TouchType::Up == type) {
        	setMediaState(false);
            m_handle->setImage(m_handleOffImg);
            m_progressBarImageView->setImage(m_progressBarImage);

            float handlePosX = m_handleLayoutProperties->positionX();
            if(!m_handleLongPressed)
            	setImmediateValue(fromPosXToValue(handlePosX));
            m_handleTouched = false;
            if(m_timer->isActive())
                m_timer->stop();
            m_handleLongPressed = false;
            emit handleReleased();

            return;
        }
    }

}

void CustomSlider::progressBarTouched(TouchEvent* event)
{
    if(event->propagationPhase() == PropagationPhase::AtTarget && isEnabled()) {
        TouchType::Type type = event->touchType();
        float handlePosX = event->localX() - m_rootContainerHeight / 2;

        if(TouchType::Down == type) {

            m_handle->setImage(m_handleOnImg);
            m_progressBarImageView->setImage(m_progressBarImagePressed);
            setImmediateValue(fromPosXToValue(handlePosX));
            return;
        }

        if(TouchType::Move == type) {
            if(!m_timer->isActive()) {
                setImmediateValue(fromPosXToValue(handlePosX));
                m_timer->start(m_updateInterval);
            }
            return;
        }
        else

        if(TouchType::Up == type) {
            m_handle->setImage(m_handleOffImg);
            m_progressBarImageView->setImage(m_progressBarImage);
            setImmediateValue(fromPosXToValue(handlePosX));
            if(m_timer->isActive())
                m_timer->stop();
            return;
        }
    }
}

void CustomSlider::updateHandlePositionX(float value)
{
	m_coordinateX = fromValueToPosX(value);

//    Q_ASSERT(static_cast<AbsoluteLayoutProperties*>(m_handle->layoutProperties()) != 0);
    m_handleLayoutProperties->setPositionX(m_coordinateX);
    if(m_coordinateX == 0) {
        m_progressBarImageView->setVisible(false);
    }
    else {
        m_progressBarImageView->setVisible(true);
        m_progressBarImageView->setPreferredWidth(m_coordinateX);
    }
}

float CustomSlider::fromValueToPosX(float value) const
{
    float factor = (value - m_fromValue) / (m_toValue - m_fromValue);

    return (m_rootContainerWidth - m_rootContainerHeight) * factor;
}

float CustomSlider::fromPosXToValue(float positionX) const
{
    float endX = m_rootContainerWidth - m_rootContainerHeight;

    if(positionX < 0)
        positionX = 0;
    if(positionX > endX)
        positionX = endX;

    float factor = positionX / endX;

    return factor * (m_toValue - m_fromValue) + m_fromValue;
}


void CustomSlider::setUpdateInterval(int interval)
{
    if(m_updateInterval == interval)
        return;

    m_updateInterval = interval;
}

void CustomSlider::onHandleLongPressed(bb::cascades::LongPressEvent* event)
{
    m_handleLongPressed = true;
    emit handleLongPressed(event->x());
}

float CustomSlider::handleLocalX() const
{
    return fromValueToPosX(m_immediateValue);
}

void CustomSlider::onHandleImageSizeChanged(int width, int height)
{
    m_handleSize.setWidth(width);
    m_handleSize.setHeight(height);
    emit handleSizeChanged(m_handleSize);
}

QSize CustomSlider::handleSize() const
{
    return m_handleSize;
}

void CustomSlider::updateRootContainerPreferredWidth(float width)
{
    m_rootContainerWidth = width;
}

void CustomSlider::setLongPressEnabled(bool enabled)
{
    m_handleLongPressed = enabled;
}
