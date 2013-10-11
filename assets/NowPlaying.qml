import bb.cascades 1.0


Container {
    visible: HDMIPlayer.playing
    layout: StackLayout {
        orientation: LayoutOrientation.LeftToRight
    }
    topPadding: 25
    bottomPadding: 25
    leftPadding: 25
    Label {
        text: qsTr("Now Playing") + Retranslate.onLocaleOrLanguageChanged
    }
    ImageButton {
        defaultImageSource: HDMIPlayer.paused?"asset:///images/Player/ic_play.png":"asset:///images/Player/ic_pause.png"
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
