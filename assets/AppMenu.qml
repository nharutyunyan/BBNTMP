import bb.cascades 1.0

MenuDefinition {
    actions: [
        ActionItem {
            title: qsTr("Invite") 
            imageSource: "asset:///images/ic_bbm.png"
            onTriggered: {
                _appShare.shareApp();                
            }
        },        
        ActionItem {
            title: qsTr("About") 
            onTriggered: {
                linkInvocation.trigger("bb.action.OPEN");
            }
            imageSource: "asset:///images/appInfo.png"
            attachedObjects: [
                Invocation {
                    id: linkInvocation
                    query {
                        uri: "http://www.macadamian.com/"
                    }
                }
            ]
        }
    ]
}
