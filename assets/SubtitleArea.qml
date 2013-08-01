import bb.cascades 1.0
import nuttyPlayer 1.0

Container {
    implicitLayoutAnimationsEnabled: false
    layout: StackLayout {
        orientation: LayoutOrientation.TopToBottom
    }
    preferredHeight: 200
    Container {
        layoutProperties: StackLayoutProperties {
            spaceQuota: 1.0
        }
    }

    Container {
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Center
        implicitLayoutAnimationsEnabled: false
        Container {
            implicitLayoutAnimationsEnabled: false
            layout: AbsoluteLayout {
            }
            Container {
                implicitLayoutAnimationsEnabled: false
                Label {
                    multiline: true
                    text: subtitleManager.text
                    textFormat: TextFormat.Html
                    textStyle.color: Color.DarkGray
                    overlapTouchPolicy: OverlapTouchPolicy.Allow
                    textStyle.textAlign: TextAlign.Center
                    implicitLayoutAnimationsEnabled: false
                }
                layoutProperties: AbsoluteLayoutProperties {
                    positionX: subtitleContainerLayout.layoutFrame.x + 2
                    positionY: subtitleContainerLayout.layoutFrame.y + 1
                }
            }
            Container {
                implicitLayoutAnimationsEnabled: false
                Label {
                    multiline: true
                    text: subtitleManager.text
                    textFormat: TextFormat.Html
                    textStyle.color: Color.White
                    textStyle.textAlign: TextAlign.Center
                    overlapTouchPolicy: OverlapTouchPolicy.Allow
                    implicitLayoutAnimationsEnabled: false
                }
                attachedObjects: LayoutUpdateHandler {
                    id: subtitleContainerLayout
                }
            }
        }
    }
}
