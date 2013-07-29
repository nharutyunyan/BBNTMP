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
    
    Label {
        multiline: true
        text: subtitleManager.text
        textFormat: TextFormat.Html
        textStyle.color: Color.White
        textStyle.textAlign: TextAlign.Center
        overlapTouchPolicy: OverlapTouchPolicy.Allow
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Center
        
        onCreationCompleted: {
            
            setImplicitLayoutAnimationsEnabled(false);
        }
    }
}
