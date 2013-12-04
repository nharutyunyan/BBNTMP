import bb.cascades 1.0
import bb.system.phone 1.0
import system 1.0
import "helpers.js" as Helpers

Page {
    
    Container {

        background: Color.White

        ImageView {
            minHeight: 72
            id: headerImage
            imageSource: orientHandler.orientation == UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
        }

        Container {
            topPadding: 50
            leftPadding: 50
            rightPadding: leftPadding
            Container {
                layoutProperties: StackLayoutProperties {
                    spaceQuota: 2.5
                }
                Label {
                    text: qsTr("Nutty Player is a video player application that supports a wide range of formats. Offers subtitles, captions, intuitive user interface, touch screen navigation, play over HDMI and Miracast.")
                    + Retranslate.onLanguageChanged
                    multiline: true
                    textStyle.color: Color.Black
                }
            }
            Container {
                layoutProperties: StackLayoutProperties {
                    spaceQuota: 0
                }
                Label {
                    text: "<html><a href=\"http://macadamian.com\">Macadamian Technologies</a></html>"
                    textStyle.color: Color.create("#c55500")
                }
            }
            Container {
                layoutProperties: StackLayoutProperties {
                    spaceQuota: 1
                }
                Label {
                    text: "1-877-779-6336"
                    textStyle.color: Color.create("#c55500")
                }
            }

            Container {
                layoutProperties: StackLayoutProperties {
                    spaceQuota: system.isQ10() ? 1 : 4 
                }
                Label {
                    text: qsTr("Version %1").arg(AppInfo.version) + Retranslate.onLanguageChanged
                    textStyle.color: Color.Black
                }
            }
        }
    }

    paneProperties: NavigationPaneProperties {
        backButton: ActionItem {
            onTriggered: {
                navigationPane.pop();
            }
        }
    }

    attachedObjects: [
        OrientationHandler {
            id: orientHandler
            onOrientationAboutToChange: {
                headerImage.imageSource = orientHandler.orientation != UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
            }
        },
        Phone {
            id: phone
        },
        System {
            id: system
        } 
    ]
       
}
