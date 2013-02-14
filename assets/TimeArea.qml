import bb.cascades 1.0
import "helpers.js" as Helpers

Container {
    property int timeInMsc
    layout: DockLayout {}

    background: Color.create("#0088cc")
    Label {
        text: Helpers.formatTime(timeInMsc)
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        textStyle {
            color: Color.White
            fontWeight: FontWeight.Normal
        }
    }
}