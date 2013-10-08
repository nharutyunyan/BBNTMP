#include <bb/device/HardwareInfo>
using namespace bb::device;

#include <QObject>

class System: public QObject {
    Q_OBJECT
public:
    System(QObject* parent = 0);
    virtual ~System();
    Q_INVOKABLE QString modelName();
    Q_INVOKABLE bool isQ10();
    Q_INVOKABLE bool isZ10();

private:
    HardwareInfo* mHardware;
};


