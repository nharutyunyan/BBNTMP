import bb.cascades 1.0
import nuttyPlayer 1.0

Container {
    property variant playerPage
    visible: HDMIPlayer.playing
    layout: DockLayout {
    }
    horizontalAlignment: HorizontalAlignment.Fill
    topPadding: 25
    bottomPadding: 25
    leftPadding: 25
    Container {
        layout: StackLayout {
            orientation: LayoutOrientation.LeftToRight
        }
        Label {
            text: qsTr("Now Playing") + Retranslate.onLocaleOrLanguageChanged
        }
        ImageButton {
            defaultImageSource: HDMIPlayer.paused ? "asset:///images/Player/ic_play.png" : "asset:///images/Player/ic_pause.png"
            onClicked: {
                HDMIPlayer.pause(!HDMIPlayer.paused)
            }
        }
        ImageButton {
            defaultImageSource: "asset:///images/Player/ic_stop.png"
            onClicked: {
                HDMIPlayer.stop()
            }
        }
    }
    Container {
        horizontalAlignment: HorizontalAlignment.Right
        ImageButton {
            defaultImageSource: "asset:///images/GridView/ic_up.png"
            onClicked: {
                settings.setValue("inPlayerView", true);
                Application.setMenuEnabled(false);
                navigationPane.push(playerPage)
            }
        }
    }
    attachedObjects: [
        Settings {
            id: settings
        }
    ]
}
