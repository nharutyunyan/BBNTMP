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
#include <bb/cascades/OrientationSupport>
#include <bb/cascades/animation/translatetransition.h>
#include <bb/cascades/animation/parallelanimation.h>
#include <bb/cascades/StackLayout>
#include "BpsEventHandler.hpp"
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

    Q_PROPERTY(float smallSliderMaxWidth READ smallSliderMaxWidth WRITE setSmallSliderMaxWidth FINAL)
    Q_PROPERTY(float smallCurrentValue READ smallCurrentValue  WRITE setSmallCurrentValue FINAL)
    Q_PROPERTY(float smallCordX READ smallCordX  WRITE setSmallCordX FINAL)
    Q_PROPERTY(QString objectName READ objectName  WRITE setObjectName FINAL)
    Q_PROPERTY(bool animation READ animation  WRITE setAnimation FINAL)
    Q_PROPERTY(QString background READ background  WRITE setBackground FINAL)
    Q_PROPERTY(QSize layoutSize READ layoutSize  WRITE setLayoutSize FINAL)
    Q_PROPERTY(bool mediaState READ  mediaState WRITE setMediaState NOTIFY mediaStateChanged FINAL)
    Q_PROPERTY(float value READ value WRITE setValue FINAL)
    Q_PROPERTY(float fromValue READ fromValue WRITE setFromValue NOTIFY fromValueChanged FINAL)
    Q_PROPERTY(float toValue READ toValue WRITE setToValue NOTIFY toValueChanged FINAL)
    Q_PROPERTY(float immediateValue READ immediateValue NOTIFY immediateValueChanged FINAL)
    Q_PROPERTY(QSize handleSize READ handleSize NOTIFY handleSizeChanged FINAL)

public:
    float cordinatX();
    bool mediaState();
    CustomSlider(Container* parent = 0);
    virtual ~CustomSlider(){}

    float value() const;
    float fromValue() const;
    float toValue() const;
    float immediateValue() const;
    float smallSliderMaxWidth() const;
    float smallCurrentValue() const;
    float smallCordX() const;
    QString objectName() const;
    bool animation() const;
    QString background() const;
    QSize layoutSize() const;
    Q_INVOKABLE float handleLocalX() const;
    Q_INVOKABLE void setLongPressEnabled(bool enabled);

public Q_SLOTS:
	void setSmallSliderMaxWidth(float);
	void setSmallCurrentValue(float);
	void setSmallCordX(float);
	void setObjectName(QString);
	void setAnimation(bool);
	void setBackground(QString);
	void onOrientationAboutToChange(bb::cascades::UIOrientation::Type uiOrientation);
	void setLayoutSize(QSize);
	void setMediaState(bool);
    void setValue(float value);
    void setFromValue(float value);
    void setToValue(float value);
    void resetValue();
    void setUpdateInterval(int interval);
    void onHandleLongPressed(bb::cascades::LongPressEvent* event);
    void onHandleContainerLongPressed();
    float fromPosXToValue(float positionX) const;
    float fromValueToPosX(float value) const;
    float fromSmallSliderValueToPosX(float);
    float fromSmallSliderPosXToValue(float);
    void onHandleImageSizeChanged(int width, int height);
    QSize handleSize() const;

Q_SIGNALS:
	void mediaStateChanged();
    void valueChanged(float value);
    void fromValueChanged(float value);
    void toValueChanged(float value);
    void immediateValueChanged();
    void handleLongPressed(float positionX);
    void handleReleased();
    void move(float windowX);
    void press(float windowX);
    void handleSizeChanged(QSize size);

private Q_SLOTS:
    void sliderHandleTouched(bb::cascades::TouchEvent* event);
    void progressBarTouched(bb::cascades::TouchEvent* event);
    void updateHandlePositionX(float);
    void updateRootContainerPreferredWidth(float width);
    void reset();


private:
    void createAnimation();
    void createConnections();
    void createProgressBar();
    void createHandle();
    void setImmediateValue(float);
    void update(float);

private:
    BpsEventHandler m_eventHandler;
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
    ParallelAnimation* m_animation;
    TranslateTransition* m_leftTranslateTransition;
    TranslateTransition* m_rightTranslateTransition;

    // handle
    Container* m_handleContainer;
    Container* m_animationContainer;
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
    bool m_mediastate;
    float m_smallSliderValue;
    float m_smallSliderInitialValue;

    float m_touchEventInitX;
    float m_handleInitX;

    bool m_handleTouched;

    QTimer* m_timer;
    bool m_timerEnabled;

    int m_updateInterval;

    bool m_handleLongPressed;
    QString m_objectName;
    float m_smallSliderMaxWidth;
    float m_smallCurrentValue;
    float m_smallCordX;
    QString m_background;
    QSize m_layoutSize;

    AbsoluteLayoutProperties* m_handleLayoutProperties;
    Container* m_leftAnimationContainer;
    Container* m_rightAnimationContainer;
    Container* m_leftContainer;
    Container* m_rightContainer;
    float m_leftAnimationContainerWidth;
    float m_rightAnimationContainerWidth;
    StackLayout *pStackLayout;
    ImageView* leftBackground;
    ImageView* rightBackground;
};

#endif /* CUSTOMSLIDER_H_ */
