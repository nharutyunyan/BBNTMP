function formatTime(msecs)
{
    var seconds = msecs/1000;
    function format(number) {
        var t = Math.floor(number);
        if(t < 10)
            t = "0" + t;

        return t;
    }

    var hours = format(seconds / 3600);
    var reminder = seconds - hours * 3600;
    var mins = format(reminder / 60);
    reminder = reminder - mins * 60;
    var secs = format(reminder);

    return hours + ":" + mins + ":" + secs;
}
var seekTimeInSlide = 10*1000;
var heightOfSlider = 100;
var distanceFromSubtitleToBottomOfScreen = 30;
var widthOfSubtitleButton = 150;
var differentScreenWidthAndSubtitleWidth = 300;
// 112 magic number is my estimated width of the context menu, this is based on Q10. 
// TODO : find real size for all platforms ?
var widthOfContextMenu = 112;
var splashScreenForAnimationPortrait = "asset:///images/SplashScreenAnimationPortrait.png";
var splashScreenForAnimationLandscape = "asset:///images/SplashScreenAnimationLandscape.png";
var animatedLogoPositionXPortrait = 185;
var animatedLogoPositionYPortrait = 537;
var animatedLogoPositionXLandscape = 411;
var animatedLogoPositionYLandscape = 300;
var volumeIndicatorLength = 230;
var volumeBarIndicatorsCount = 13;
var volumeBarScaleX = 1;
var volumeBarScaleY = 1;
var aboutPageLinesHeightInPortrait = 2;
var aboutPageLinesHeightInLandscape = 1.5;
var actionBarPortraitHeight = 140;
var actionBarLandscapeHeight = 100;
var favoriteIconAdd = "asset:///images/GridView/favoriteIcon_add_Z10.png";
var favoriteIconRemove = "asset:///images/GridView/favoriteIcon_remove_Z10.png";
var timeAreasHorizontalPaddingInPortrait = 40;
var timeAreasHorizontalPaddingInLandscape = 35;
var timeAreasVerticalPaddingInPortrait = 0;
var timeAreasVerticalPaddingInLandscape = 0;
var bookmarkPaddingYInPortrait = 20;
var bookmarkPaddingYInLandscape = 15;
var bookmarkAnimationForwardYPortrait = 50;
var bookmarkAnimationBackYPortrait = 12;
var bookmarkAnimationForwardYLandscape = 35;
var bookmarkAnimationBackYLandscape = 12;

