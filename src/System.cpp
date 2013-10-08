
#include "System.hpp"


using namespace bb::device;
System::System(QObject* parent) : QObject(parent){
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

// TODO: need to add Z30



