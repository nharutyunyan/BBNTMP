import bb.cascades 1.0
import bb.cascades.pickers 1.0

MenuDefinition {
    actions: [
        ActionItem {
            title: qsTr("About")+Retranslate.onLanguageChanged
            onTriggered: {
                var page = aboutPageDefinition.createObject();
                navigationPane.push(page);
                Application.setMenuEnabled(false);
            }
            imageSource: "asset:///images/appInfo.png"
        },
        ActionItem {
            title: qsTr("Invite")+Retranslate.onLanguageChanged
            imageSource: "asset:///images/ic_bbm.png"
            onTriggered: {
                _appShare.shareApp();
            }
        },
        ActionItem {
            title: qsTr("Refresh") + Retranslate.onLanguageChanged
            imageSource: "asset:///images/refresh.png"
            enabled: !loadingIndicator.running
            onTriggered: {
            	infoListModel.getVideoFiles();
            }
        },
        ActionItem {
            title: qsTr("Browse") + Retranslate.onLanguageChanged
            //imageSource: "asset:///images/"  
            onTriggered: {
               filePicker.open();              
            }
        }
    ]
    attachedObjects: [
        ComponentDefinition {
            id: aboutPageDefinition
            source: "aboutPage.qml"
        },
        FilePicker {
            id: filePicker
            title : "Browse Files"
            type : FileType.Video    
            directories: ["/accounts/1000/shared"]
            mode: FilePickerMode.PickerMultiple  
            onFileSelected : { 
               	var count = infoListModel.addNewVideosManually(selectedFiles);
               	if (count > 0) {
               	    if (count==1) {
                        addedVideosToast.body = "1 item added";
               	    } else {
                        addedVideosToast.body = count + " items added";;
               	    }
                    addedVideosToast.show();
               	}               
                var index = infoListModel.getIndex(selectedFiles[0]);
                mainPage.movieGridObj.scrollToItem(index, ScrollAnimation.None); 
           }
        } 
    ]
}
