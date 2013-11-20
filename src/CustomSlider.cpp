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
#include <bb/cascades/ImagePaint>
#include <bb/cascades/animation/stockcurve.h>
#include <bb/cascades/ScalingMethod>
#include <bb/device/DisplayInfo>

const int LONG_PRESS_MAX_DEVIATION = 5;
const int HANDLE_TOUCH_SPACE_WIDTH = 40;

CustomSlider::CustomSlider(Container* parent)
    :CustomControl(parent),
     m_rootContainerHeight(105),
     m_progressBarContainerHeight(15),
     m_fromValue(0.0),
     m_toValue(1.0),
     m_coordinateX(0.0),
     m_objectName("")
{
    setUpdateInterval(0);
    setPreferredHeight(m_rootContainerHeight);
    m_rootContainer = Container::create()
                  .layout(new DockLayout())
                  .horizontal(HorizontalAlignment::Center)
                  .preferredHeight(m_rootContainerHeight);

    m_rootContainer->setMaxHeight(m_rootContainerHeight);

    createProgressBar();
    createHandle();
    createAnimation();

    m_handleContainer = Container::create()
                         .layout(new AbsoluteLayout())
                         .horizontal(HorizontalAlignment::Fill)
                         .vertical(VerticalAlignment::Center);
    m_handleContainer->addTouchBehavior(
               TouchBehavior::create()
                   .addTouchReaction(TouchType::Down,
                                     PropagationPhase::AtTarget,
                                     TouchResponse::StartTracking));
    m_handleContainer->setImplicitLayoutAnimationsEnabled(false);
     LongPressHandler* longPressHandler = LongPressHandler::create()
                .onLongPressed(this, SLOT(onHandleContainerLongPressed()));
    m_handleContainer->addGestureHandler(longPressHandler);
    m_handleContainer->add(m_handle);
    m_rootContainer->add(m_progressBarContainer);
    m_rootContainer->add(m_animationContainer);
    m_rootContainer->add(m_handleContainer);
    setRoot(m_rootContainer);

    m_timer = new QTimer(this);
    m_timer->setSingleShot(true);
    createConnections();
    QObject::connect(&m_eventHandler, SIGNAL(deviceLockStateChanged(bool)),  this, SLOT(reset()));
}

void CustomSlider::createAnimation()
{
	 m_animationContainer = Container::create()
	    						.horizontal(HorizontalAlignment::Fill)
	    						.vertical(VerticalAlignment::Center);
	 pStackLayout = new StackLayout();
	 pStackLayout->setOrientation( LayoutOrientation::LeftToRight );
	 m_animationContainer->setLayout(pStackLayout);

	 m_leftAnimationContainer =  Container::create()
	  	  	  	  	  	  	  	  	  .layout(new DockLayout())
	  	  	  	  	  	  	  	  	  .horizontal(HorizontalAlignment::Left)
	  	  	  	  	  	  	  	  	  .vertical(VerticalAlignment::Center);

	 m_rightAnimationContainer = Container::create()
	  	  	  	  	  	  	  	  	  .layout(new DockLayout())
	  	  	  	  	  	  	  	  	  .horizontal(HorizontalAlignment::Right)
	  	  	  	  	  	  		  	  .vertical(VerticalAlignment::Center);
	 m_leftContainer = Container::create()
	  	  	  	  .horizontal(HorizontalAlignment::Left)
	  		  	  .vertical(VerticalAlignment::Center);
	 m_rightContainer = Container::create()
	 	  	  	  	  .horizontal(HorizontalAlignment::Right)
	 	  		  	  .vertical(VerticalAlignment::Center);

	 m_leftAnimationContainer->add(m_leftContainer);
	 m_rightAnimationContainer->add(m_rightContainer);
	 m_animationContainer->add(m_leftAnimationContainer);
	 m_animationContainer->add(m_rightAnimationContainer);

	 m_animation = ParallelAnimation::create()
	 	 	 	   .add( TranslateTransition::create(m_leftContainer)
	 	 	 	   	   	 .toX(19)
	 	 	 	   	   	 .duration(200)
	 	 	 	   		 .easingCurve(StockCurve::BackOut))
	 	 	 	   .add( TranslateTransition::create(m_rightContainer)
	 	 	 	   		 .toX(-19)
	 	 	 	   		 .duration(200)
	 	 	 	   		 .easingCurve(StockCurve::BackOut));
}

void CustomSlider::setSmallSliderMaxWidth(float maxWidth)
{
	m_smallSliderMaxWidth = maxWidth;
}

void CustomSlider::setObjectName(QString name)
{
	m_objectName = name;
}

void CustomSlider::setAnimation(bool state)
{
	Q_UNUSED(state)

	m_progressBarContainer->setVisible(false);
	m_leftContainer->setTranslationX(m_leftAnimationContainerWidth);
	m_rightContainer->setTranslationX(-m_rightAnimationContainerWidth);
	m_animation->play();
}

void CustomSlider::setBackground(QString path)
{
	  leftBackground =
	            ImageView::create(path);
	  leftBackground->setScalingMethod(bb::cascades::ScalingMethod::AspectFill);
	  rightBackground =
	 	        ImageView::create(path);

	  rightBackground->setScaleX(-1);
	  rightBackground->setScalingMethod(bb::cascades::ScalingMethod::AspectFill);
	  m_leftContainer->add(leftBackground);
	  m_rightContainer->add(rightBackground);
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
	 if(this->m_objectName == "slider")
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

void CustomSlider::setSmallCurrentValue(float currentValue)
{
	m_smallSliderValue = currentValue;
}

void CustomSlider::setSmallCordX(float cordX)
{
	bb::device::DisplayInfo display;
	int width = display.pixelSize().width();
	if(cordX < -20)
	{
	 	 m_rootContainerWidth += cordX + 20;
		 m_rootContainer->setPreferredWidth(m_rootContainerWidth);
		 m_leftAnimationContainer->setRightPadding(m_leftAnimationContainer->rightPadding() +  cordX + 20);
		 m_leftAnimationContainerWidth =  m_rootContainerWidth - m_smallSliderMaxWidth / 2;
		 m_rightAnimationContainerWidth = m_smallSliderMaxWidth / 2;
		 m_handleLayoutProperties->setPositionX(m_leftAnimationContainerWidth - m_rootContainerHeight/2);
	} else if (width - cordX < m_rootContainerWidth - 20)
	{
		m_rightAnimationContainer->setLeftPadding(m_rightAnimationContainer->leftPadding() + ((width - cordX) - m_rootContainerWidth + 20));
		m_rootContainerWidth += ((width - cordX) - m_rootContainerWidth + 20);
		m_rootContainer->setPreferredWidth(m_rootContainerWidth);
		m_leftAnimationContainerWidth =  m_smallSliderMaxWidth / 2;
		m_rightAnimationContainerWidth = m_rootContainerWidth - m_smallSliderMaxWidth / 2;
		m_handleLayoutProperties->setPositionX(m_leftAnimationContainerWidth - m_rootContainerHeight/2);
	}
}


float CustomSlider::fromSmallSliderValueToPosX(float value)
{
	float factor;
	if(value <= m_smallSliderValue)
	{
		if(m_smallSliderValue == m_fromValue)
			factor = 0;
		else
		{
			factor = (value - m_fromValue) / (m_smallSliderValue - m_fromValue);
		}
		return factor * (m_leftAnimationContainerWidth - m_rootContainerHeight/2);
	}
	else
	{
		if(m_toValue == m_smallSliderValue)
			factor = 0;
		else
			factor = (value - m_smallSliderValue) / (m_toValue - m_smallSliderValue);
		return factor * (m_rightAnimationContainerWidth - m_rootContainerHeight/2);
	}
}

float CustomSlider::fromSmallSliderPosXToValue(float positionX)
{
	if(positionX < 0)
		positionX = 0;
	else if(positionX > m_rootContainerWidth - m_rootContainerHeight)
		positionX = m_rootContainerWidth - m_rootContainerHeight;
	m_handleLayoutProperties->setPositionX(positionX);
	 float endX;
	 float factor;
	 if(positionX < m_leftAnimationContainerWidth - m_rootContainerHeight/2)
	 {
		 if(positionX < 0)
			 positionX = 0;
		 endX = m_leftAnimationContainerWidth - m_rootContainerHeight/2;
		 factor = (positionX / endX);
		 return factor * (m_smallSliderValue - m_fromValue) + m_fromValue;
	 }
	 else
	 {
		 positionX = positionX - (m_leftAnimationContainerWidth- m_rootContainerHeight/2);
		 endX = m_rightAnimationContainerWidth - m_rootContainerHeight/2;
		 factor = positionX / endX;
		 return factor * (m_toValue - m_smallSliderValue) + m_smallSliderValue;
	 }
}

void CustomSlider::setLayoutSize(QSize size)
{
	 m_rootContainerWidth = size.width() ;
	 m_rootContainer->setPreferredWidth(size.width());
	 m_rootContainerHeight = size.height();

	 m_progressBarContainer->setPreferredWidth(m_rootContainerWidth - 87);
	 if(this->m_objectName == "smallStepSlider"){
		 m_leftAnimationContainer->setRightPadding(0);
		 m_rightAnimationContainer->setLeftPadding(0);
		 m_leftAnimationContainerWidth =  m_smallSliderMaxWidth / 2;
		 m_rightAnimationContainerWidth = m_smallSliderMaxWidth / 2;
	 }

	 float factor = (m_value - m_fromValue) / (m_toValue - m_value);
	 if(factor <= 1)
	 {
		 m_leftAnimationContainer->setRightPadding(size.width() -m_smallSliderMaxWidth);
		 m_leftAnimationContainerWidth = size.width() - m_smallSliderMaxWidth / 2;
	 }
	 else{
		 m_rightAnimationContainer->setLeftPadding(size.width() -m_smallSliderMaxWidth);
		 m_rightAnimationContainerWidth = size.width() - m_smallSliderMaxWidth / 2;
	 }

	if(this->m_objectName == "slider")
		updateHandlePositionX(m_value);
	else
		m_handleLayoutProperties->setPositionX(m_leftAnimationContainerWidth - m_rootContainerHeight/2);
}

void CustomSlider::createConnections()
{

	connect(OrientationSupport::instance(),
	          SIGNAL(orientationAboutToChange(bb::cascades::UIOrientation::Type)),
	          this,
	          SLOT(onOrientationAboutToChange(bb::cascades::UIOrientation::Type)), Qt::UniqueConnection);
    connect(m_handle, SIGNAL(touch(bb::cascades::TouchEvent*)),
            this, SLOT(sliderHandleTouched(bb::cascades::TouchEvent*)));
    connect(m_handleContainer, SIGNAL(touch(bb::cascades::TouchEvent*)),
            this, SLOT(progressBarTouched(bb::cascades::TouchEvent*)));
    connect(this, SIGNAL(preferredWidthChanged(float)), this, SLOT(updateRootContainerPreferredWidth(float)));


    bool result = connect(m_handleImageTracker, SIGNAL(sizeChanged(int, int)),
                    this, SLOT(onHandleImageSizeChanged(int, int)));
    Q_ASSERT(result);
    Q_UNUSED(result);
}

void CustomSlider::onOrientationAboutToChange(bb::cascades::UIOrientation::Type uiOrientation)
{
	Q_UNUSED(uiOrientation)

	reset();
}

void CustomSlider::reset()
{
	m_handle->setImage(m_handleOffImg);
	m_progressBarImageView->setImage(m_progressBarImage);
	setMediaState(false);
	float handlePosX = m_handleLayoutProperties->positionX();
	if (!m_handleLongPressed)
		setImmediateValue(fromPosXToValue(handlePosX));
	m_handleTouched = false;
	m_progressBarTouched = false;
	if (m_timer->isActive())
		m_timer->stop();
	m_handleLongPressed = false;
	m_handleContainer->setVisible(true);
	emit handleReleased();
}

void CustomSlider::createProgressBar()
{
    AbsoluteLayoutProperties* layoutProperties
                            = AbsoluteLayoutProperties::create();

    m_progressBarContainer = Container::create()
                    .layout(new DockLayout())
                    .layoutProperties(layoutProperties)
                    .horizontal(HorizontalAlignment::Center)
                    .vertical(VerticalAlignment::Center)
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
    m_progressBarImageView->setVisible(false);
    m_progressBarImageView->setImage(m_progressBarImage);
    m_progressBarImageView->setImplicitLayoutAnimationsEnabled(false);

    m_bookmarkProgressBar = ImageView::create()
                                    .preferredHeight(m_progressBarContainerHeight)
                                    .horizontal(HorizontalAlignment::Left)
                                    .vertical(VerticalAlignment::Center);
    m_bookmarkProgressBar->setVisible(false);
    m_bookmarkProgressBar->setOpacity(0.3);
    m_bookmarkProgressBar->setImage(m_progressBarImage);
    m_bookmarkProgressBar->setImplicitLayoutAnimationsEnabled(false);

    m_progressBarContainer->add(barImageView);
    m_progressBarContainer->add(m_progressBarImageView);
    m_progressBarContainer->add(m_bookmarkProgressBar);
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
	if (m_progressBarTouched || ( !mediaState() &&
	   (event->localX() < (m_rootContainerHeight - HANDLE_TOUCH_SPACE_WIDTH)/2  || event->localX() > (m_rootContainerHeight + HANDLE_TOUCH_SPACE_WIDTH)/2) ) )
	{
		progressBarTouched(event);
	}  else

    if(event->propagationPhase() == PropagationPhase::AtTarget && isEnabled()) {
        m_handleTouched = true;
        TouchType::Type type  = event->touchType();

        if(TouchType::Down == type) {
        	m_handleTouchDownX = event->windowX();
        	m_handleTouchMoveX = m_handleTouchDownX;
        	setMediaState(true);
            m_progressBarImageView->setImage(m_progressBarImagePressed);
            m_handle->setImage(m_handleOnImg);
            m_touchEventInitX = event->windowX();
            m_handleInitX = m_handleLayoutProperties->positionX() + m_rootContainerPositionX;
            m_smallSliderInitialValue = m_value;
            return;
        }

        float handlePosX = m_handleInitX - m_touchEventInitX + event->windowX();

        if(TouchType::Move == type) {
            if(!m_handleLongPressed) {
                if(!m_timer->isActive()) {
                	m_handleTouchMoveX = event->windowX();
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
            m_handle->setImage(m_handleOffImg);
            m_progressBarImageView->setImage(m_progressBarImage);

            float handlePosX = m_handleLayoutProperties->positionX();
            if(!m_handleLongPressed)
            	setImmediateValue(fromPosXToValue(handlePosX));
            m_handleTouched = false;
            if(m_timer->isActive())
                m_timer->stop();
            m_handleLongPressed = false;
            setMediaState(false);
            m_handleContainer->setVisible(true);
            emit handleReleased();

            return;
        }
    }

}

void CustomSlider::progressBarTouched(TouchEvent* event)
{
	if(event->propagationPhase() == PropagationPhase::AtTarget && isEnabled()) {
		m_progressBarTouched = true;
        TouchType::Type type = event->touchType();

        float handlePosX = event->windowX() - m_rootContainerHeight / 2;

		OrientationSupport *support = OrientationSupport::instance();
		if (support->orientation() != UIOrientation::Portrait) {
			bb::device::DisplayInfo display;
			handlePosX -= (display.pixelSize().height() - m_rootContainerWidth)/2;
		}

        if(TouchType::Down == type) {
        	setMediaState(true);
            m_handle->setImage(m_handleOnImg);
            m_progressBarImageView->setImage(m_progressBarImagePressed);
            setImmediateValue(fromPosXToValue(handlePosX));
            m_touchEventInitX = event->windowX();
            m_smallSliderInitialValue = m_value;
            return;
        }

        if(TouchType::Move == type) {
        	if(m_handleLongPressed){
        		emit move(event->windowX());
        		return;
        	}
            if(!m_timer->isActive()) {
                setImmediateValue(fromPosXToValue(handlePosX));
                m_timer->start(m_updateInterval);
            }
            return;
        }
        else

        if(TouchType::Up == type) {
        	m_progressBarTouched = false;
        	if(m_handleLongPressed){
        		sliderHandleTouched(event);
        		return;
        	}
            m_handle->setImage(m_handleOffImg);
            m_progressBarImageView->setImage(m_progressBarImage);
            setImmediateValue(fromPosXToValue(handlePosX));
            if(m_timer->isActive())
                m_timer->stop();
            emit handleReleased();
            setMediaState(false);
            return;
        }
    }
}

void CustomSlider::updateHandlePositionX(float value)
{
	if(this->m_objectName == "smallStepSlider")
	{
		m_coordinateX = fromSmallSliderValueToPosX(value);
	}
	else
		m_coordinateX = fromValueToPosX(value);

    m_handleLayoutProperties->setPositionX(m_coordinateX);
    if(m_coordinateX == 0) {
        m_progressBarImageView->setVisible(false);
    }
    else if(m_coordinateX > 0)
    {
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
	if (abs(m_handleTouchDownX - m_handleTouchMoveX) <= LONG_PRESS_MAX_DEVIATION) {
		m_handleLongPressed = true;
		m_handleContainer->setVisible(false);
		setImmediateValue(m_smallSliderInitialValue);
		emit handleLongPressed(event->x());
	}
}

void CustomSlider::onHandleContainerLongPressed()
{
	m_handleLongPressed = true;
	m_handleContainer->setVisible(false);
	emit handleLongPressed(m_rootContainerHeight/2);
}

float CustomSlider::handleLocalX() const
{
    return fromValueToPosX(m_value);
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
	m_handleContainer->setVisible(true);
    m_handleLongPressed = enabled;
}

float CustomSlider::smallSliderMaxWidth() const
{
    return m_smallSliderMaxWidth;
}

float CustomSlider::smallCurrentValue() const
{
    return m_smallCurrentValue;
}

float CustomSlider::smallCordX() const
{
    return m_smallCordX;
}

QString CustomSlider::objectName() const
{
    return m_objectName;
}

bool CustomSlider::animation() const
{
    return m_animation;
}

QString CustomSlider::background() const
{
    return m_background;
}

QSize CustomSlider::layoutSize() const
{
    return m_layoutSize;
}

void CustomSlider::hideBookmarkProgressBar()
{
	m_bookmarkProgressBar->setVisible(false);
}

void CustomSlider::showBookmarkProgressBar(float positionX)
{
	m_bookmarkProgressBar->setVisible(true);
	m_bookmarkProgressBar->setPreferredWidth(positionX);
}
