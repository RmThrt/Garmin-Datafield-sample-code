using Toybox.AntPlus;
using Toybox.Lang;

module Navigation {
  var RoutingType = {
      "left" => "left",
      "right" => "right",
      "slight left" => "slight left",
      "slight right" => "slight right",
      "sharp left" => "sharp left",
      "sharp right" => "sharp right",
      "Enter roundabout" => "Enter roundabout",
      "Exit roundabout" => "Exit roundabout",
      "U-turn" => "U-turn",
      "Goal" => "Goal",
      "Depart" => "Depart",
      "Keep left" => "Keep left",
      "Keep right" => "Keep right",
      "" => ""
  };


  class Navigation {  
    var xScreenProtectionArea as Lang.Number;
    var yScreenProtectionArea as Lang.Number;
    var simCount = -1;
    var isRunning = false;
    var distanceToDisplay as Lang.Float = 30.0;
    const borderOffset as Lang.Number = 8;
    var fontSize as Lang.Number;

    function initialize(xScreenProtectionArea as Lang.Number,
                        yScreenProtectionArea as Lang.Number,
                        fontSize as Lang.Number,
                        distanceToDisplay as Lang.Float) {
      self.xScreenProtectionArea = xScreenProtectionArea;
      self.distanceToDisplay = distanceToDisplay;
      self.yScreenProtectionArea = yScreenProtectionArea;
      self.fontSize = fontSize;
    }

    function sendNavInfos(routingType as Lang.String,distance as Lang.Float, offCourseDistance as Lang.Float){
      isRunning = false;

      if ((distance < self.distanceToDisplay || offCourseDistance >5.0) && distance > 0.0 ) {
        isRunning = true;
        var routingTypeStr = routingType;
        var distanceStr = distance.format("%.0f") + "m";
        if (offCourseDistance > 5.0) {
          routingTypeStr = "OffCourse, distance:";
          distanceStr = offCourseDistance.format("%.0f") + "m";
        }
        var routingTypeLen = routingTypeStr.length();
        var distanceStrLen = distanceStr.length();

        $.sdk.changeColor(0);
        $.sdk.fullRectangle(0, 0, xScreenProtectionArea,
                            yScreenProtectionArea);
        $.sdk.changeColor(8);
        $.sdk.fullRectangle(0, yScreenProtectionArea - 4, xScreenProtectionArea,
                            4);

        $.sdk.changeColor(8);
        $.sdk.Text(routingTypeStr, self.xScreenProtectionArea /2 + routingTypeLen * 14 /2, (self.yScreenProtectionArea *0.85).toNumber() ,4, fontSize,8);
        $.sdk.Text(distanceStr, self.xScreenProtectionArea/2 + distanceStrLen * 14 /2, (self.yScreenProtectionArea*0.45).toNumber(),4, fontSize,8);

      }
    }

    function clearArea() {
      if (isRunning) {
        $.sdk.changeColor(0);
        $.sdk.fullRectangle(0,
                            0, self.xScreenProtectionArea,
                            self.yScreenProtectionArea);
        $.sdk.resetLayouts([]);
      }
    }

    (:release) function updateNavInfos(routingType as Lang.String,distance as Lang.Float, offCourseDistance as Lang.Float) {
      self.sendNavInfos(routingType, distance, offCourseDistance);
    }

     (:debug) function updateNavInfos(routingType as Lang.String,distance as Lang.Float, offCourseDistance as Lang.Float){
      // if( simCount>RoutingType.size()){
      //   simCount = -1;
      // }

      // simCount++;
      // routingType = RoutingType.keys()[simCount];
      // distance = DISTANCE_TO_DISPLAY/RoutingType.size() * simCount;
      
      self.sendNavInfos(routingType, distance, offCourseDistance);

    }
  }
}