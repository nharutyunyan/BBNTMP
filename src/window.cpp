/**
 * @file window.cpp
 * @brief Contains the implementation of UI widget class used as a GUI in the Video Player application
 */

#include <bb/cascades/Application>
#include <bb/cascades/Color>
#include <bb/cascades/Container>
#include <bb/cascades/DockLayout>
#include <bb/cascades/Page>
#include <bb/cascades/Slider>
#include <bb/cascades/Stacklayout>
#include <bb/cascades/StacklayoutProperties>

#include "window.hpp"

using namespace bb::cascades;

PlayerWindow::PlayerWindow(Application* app)
: QObject(app)
{
	Container *appContainer = new Container();

	appContainer->setLayout(new DockLayout());
	appContainer->setBackground(Color::fromARGB(0xff262626));

	Container *contentContainer = new Container();
	contentContainer->setLayout(new StackLayout());
	contentContainer->setHorizontalAlignment(HorizontalAlignment::Center);
	contentContainer->setVerticalAlignment(VerticalAlignment::Center);

	Container *imageContainer = new Container();
	imageContainer->setLayout(new DockLayout());
	imageContainer->setHorizontalAlignment(HorizontalAlignment::Center);

	Container *sliderContainer = new Container();
	StackLayout *pMyLayout = StackLayout::create();
	pMyLayout->setOrientation(LayoutOrientation::LeftToRight);
	sliderContainer->setLayout(pMyLayout);
	sliderContainer->setLeftPadding(20.0f);
	sliderContainer->setRightPadding(20.0f);

	sliderContainer->setHorizontalAlignment(HorizontalAlignment::Center);

	Slider *opacitySlider = Slider::create()
	        .from(0.0f).to(0.5f)
	        .leftMargin(20.0f).rightMargin(20.0f);

	StackLayoutProperties *stackProperties = StackLayoutProperties::create();
	opacitySlider->setLayoutProperties(stackProperties);
	opacitySlider->setHorizontalAlignment(HorizontalAlignment::Fill);

	sliderContainer->add(opacitySlider);

	contentContainer->add(imageContainer);
	contentContainer->add(sliderContainer);
	appContainer->add(contentContainer);

	Page *page = new Page();
	page->setContent(appContainer);

	app->setScene(page);

}
