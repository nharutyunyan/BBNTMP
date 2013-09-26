#include "BbmAppShare.hpp"
#include <QUuid>
#include <bb/platform/bbm/Context>
#include <bb/platform/bbm/MessageService>
#include <bb/system/SystemToast>

using namespace bb::platform::bbm;
using bb::system::SystemToast;

const QString ANALYTIC_EVENT_APP_INVITE = "AppInvite";

BbmAppShare::BbmAppShare(QObject* parent, const QUuid &uuid) :
                QObject(parent) {
    m_context = new Context(uuid, parent);
}

BbmAppShare::~BbmAppShare() {
    qDebug() << "BbmAppShare::~BbmAppShare";
}

void BbmAppShare::shareApp() {
    qDebug() << "BbmAppShare::shareApp";

    if (m_context->isAccessAllowed()) {
        MessageService messageservice(m_context);
        messageservice.sendDownloadInvitation();
    } else {
        SystemToast *toast = new SystemToast(this);

        toast->setBody(tr("Not registered to BBM"));
        toast->show();
    }
}

