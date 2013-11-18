

#include <bps/audiomixer.h>
#include <bps/vibration.h>
#include <bb/system/InvokeManager>

#include "System.hpp"

using namespace bb::device;
System::System(QObject* parent)
: QObject(parent)
{
	mHardware = new HardwareInfo();
}

System::~System() {
}

QString System::modelName()
{
	return mHardware->modelName();
}

bool System::isQ10()
{
	return modelName()=="Q10"? true : false ;
}

bool System::isZ10()
{
	return modelName()=="Z10"? true : false ;
}

bool System::OpenSettings()
{
	using namespace bb::system;

	// Create and send an invocation for the card target
	InvokeManager* invokeManager = new InvokeManager();
	InvokeRequest cardRequest;
	cardRequest.setTarget("sys.settings.target");
	cardRequest.setAction("bb.action.OPEN");
	cardRequest.setMimeType("settings/view");
	cardRequest.setUri("settings://permissions");
	InvokeTargetReply* reply = invokeManager->invoke(cardRequest);

	//in case if invocation wasn't successful
	if(reply == 0)
		return false;

	return true;
}

void System::setVolume(float volumeValue)
{
	audiomixer_set_output_level(AUDIOMIXER_OUTPUT_DEFAULT, volumeValue);
}

float System::getVolume()
{
	float oldVolume;
	audiomixer_get_output_level(AUDIOMIXER_OUTPUT_DEFAULT, &oldVolume);
	return oldVolume;
}

void System::startVibration(int intensity, int duration)
{
	vibration_request(intensity,duration);
}



