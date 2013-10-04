import bb.cascades 1.0

MenuDefinition {
    actions: [
        ActionItem {
            title: qsTr("About")+Retranslate.onLanguageChanged
            onTriggered: {
                var page = aboutPageDefinition.createObject()
                navigationPane.push(page);
                Application.setMenuEnabled(false)
            }
            imageSource: "asset:///images/appInfo.png"
        },
        ActionItem {
            title: qsTr("Invite")+Retranslate.onLanguageChanged
            imageSource: "asset:///images/ic_bbm.png"
            onTriggered: {
                _appShare.shareApp();
            }
        }
    ]
    attachedObjects: [
        ComponentDefinition {
            id: aboutPageDefinition
            source: "aboutPage.qml"
        }
    ]
}
