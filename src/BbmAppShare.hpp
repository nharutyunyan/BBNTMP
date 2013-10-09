#ifndef BBM_APP_SHARE_H_
#define BBM_APP_SHARE_H_

#include <QObject>
#include <bb/platform/bbm/Context>

class QUuid;

/**
 * This class allows sharing the app to a BBM contact
 */
class BbmAppShare: public QObject {
    Q_OBJECT

public:
    BbmAppShare(QObject* parent, const QUuid& uuid);
    ~BbmAppShare();

public Q_SLOTS:
    // Share the app to a BBM contact
    void shareApp();

private:
    QUuid uuid;
    // BBM Social Platform Context used to gain access to BBM functionality.
    bb::platform::bbm::Context* m_context;
};

#endif /* BBM_APP_SHARE_H_ */

