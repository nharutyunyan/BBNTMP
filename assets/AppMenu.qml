import bb.cascades 1.0

MenuDefinition {
    property Page aboutPage
    actions: [
        ActionItem {
            title: qsTr("Invite") 
            imageSource: "asset:///images/ic_bbm.png"
            onTriggered: {
                _appShare.shareApp();                
            }
        },        
        ActionItem {
            enabled: !navigationPane.isAboutPage
            title: qsTr("About") 
            onTriggered: {
                navigationPane.push(getAboutPage());
                navigationPane.backButtonsVisible = true;
                navigationPane.isAboutPage = true;
            }
            imageSource: "asset:///images/appInfo.png"
        }
    ]
    attachedObjects: [
        ComponentDefinition {
            id: aboutPageDefinition
            source: "aboutPage.qml"
        }
    ]
    function getAboutPage()
    {
        if(!aboutPage)
        {
        	aboutPage = aboutPageDefinition.createObject();
        }
        return aboutPage;
    }
}
