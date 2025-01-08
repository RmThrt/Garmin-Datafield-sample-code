using Toybox.AntPlus;
using Toybox.Lang;

module Radar {
  class MyRadarTarget extends AntPlus.RadarTarget {
    function initialize(rangeI as Lang.Float, speedI as Lang.Float,
                        threatI as AntPlus.ThreatLevel,
                        threatSideI as AntPlus.ThreatSide) {
      AntPlus.RadarTarget.initialize();
      range = rangeI;
      speed = speedI;
      threat = threatI;
      threatSide = threatSideI;
    }
  }

  class _MyRadarListenerCommon extends Toybox.AntPlus.BikeRadarListener {
    const NUMBER_OF_THREAT as Lang.Number = 8;
    var radarInfos as Lang.Array<MyRadarTarget> = [];
    var maxRadarRange as Lang.Float = 0.0;
    var radarConnected as Lang.Boolean = false;

    function initialize() { AntPlus.BikeRadarListener.initialize(); }

    function getRadarInfos() as Lang.Array<MyRadarTarget> {
      return self.radarInfos;
    }

    function getMaxRange() as Lang.Float { return self.maxRadarRange; }

    function getRadarConnected() as Lang.Boolean { return radarConnected; }
  }

  class MockRadarListener extends _MyRadarListenerCommon {
    const emulatorIterationBeforeSetBackvalue as Lang.Number = 5;
    var emulatorIterationCount as Lang.Number = 0;

    function initialize() {
      _MyRadarListenerCommon.initialize();

    }

    function onBikeRadarUpdate(data) {
      self.radarConnected = true;
      self.maxRadarRange = 0.0;

      for (var i = 0; i < self.radarInfos.size(); i++) {
        self.radarInfos[i].range = self.radarInfos[i].range - 15;
        if (self.radarInfos[i].range < 0) {
          self.radarInfos[i].range = self.radarInfos[i].range;
          self.radarInfos.remove(radarInfos[i]);
          i--;
          continue;
        }
        if (self.radarInfos[i].range > self.maxRadarRange) {
          self.maxRadarRange = self.radarInfos[i].range;
        }
      }

      if (self.maxRadarRange == 0) {
        if (emulatorIterationCount < emulatorIterationBeforeSetBackvalue) {
          emulatorIterationCount++;
        } else {
          emulatorIterationCount= 0;
          self.radarInfos = [
            new MyRadarTarget(30.0, 90.0,
                              AntPlus.THREAT_LEVEL_VEHICLE_FAST_APPROACHING,
                              AntPlus.THREAT_SIDE_LEFT),
            new MyRadarTarget(58.0, 30.0,
                              AntPlus.THREAT_LEVEL_VEHICLE_FAST_APPROACHING,
                              AntPlus.THREAT_SIDE_RIGHT),
            new MyRadarTarget(90.0, 50.0,
                              AntPlus.THREAT_LEVEL_VEHICLE_APPROACHING,
                              AntPlus.THREAT_SIDE_NO_SIDE),
            new MyRadarTarget(139.0, 120.0,
                              AntPlus.THREAT_LEVEL_VEHICLE_APPROACHING,
                              AntPlus.THREAT_SIDE_NO_SIDE)
          ];
        }
      }
    }
  }

  class RadarListener extends _MyRadarListenerCommon {
    function initialize() { _MyRadarListenerCommon.initialize(); }

    function onBikeRadarUpdate(data) {
      // Handle the radar update data here
      self.radarInfos = [];
      self.maxRadarRange = 0.0;

      if (data != null) {
        self.radarConnected = true;
        for (var i = 0; i < NUMBER_OF_THREAT; i++) {
          if (data[i].range.toNumber() > self.maxRadarRange) {
            self.maxRadarRange = data[i].range;
          }
          self.radarInfos.add(new MyRadarTarget(data[i].range, data[i].speed,
                                                data[i].threat,
                                                data[i].threatSide));
        }
      }
    }
  }

  class MyBikeRadar extends Toybox.AntPlus.BikeRadar {
    var radarInfos as Lang.Array<MyRadarTarget> = [];
    var maxRadarRange as Lang.Float = 0.0;
    var listener as _MyRadarListenerCommon;

    function initialize(listener as _MyRadarListenerCommon or Null) {
      AntPlus.BikeRadar.initialize(listener);
      self.listener = listener;
    }

    function getRadarInfos() as Lang.Array<MyRadarTarget> {
      return self.listener.getRadarInfos();
    }

    function getMaxRange() as Lang.Float { return self.listener.getMaxRange(); }

    function isConnected() { return self.listener.getRadarConnected(); }
  }

  class RadarView {
    var bikeRadar as MyBikeRadar;
    var xScreenProtectionArea as Lang.Number;
    var yScreenProtectionArea as Lang.Number;
    var MAX_RANGE_DETECTION as Lang.Number = 170;
    var radarAreaWidth as Lang.Number;
    var radarAreaHeight as Lang.Number;
    var radarAreaIsClean as Lang.Boolean;
    var mockRadar as Lang.Boolean = false;
    var toggleCircleIndicator as Lang.Boolean = false;
    const borderOffset as Lang.Number = 8;
    var atLeastOneFastVehicule as Lang.Boolean = false;

    function initialize(bikeRadar as MyBikeRadar,
                        xScreenProtectionArea as Lang.Number,
                        yScreenProtectionArea as Lang.Number,
                        radarAreaWidth as Lang.Number,
                        radarAreaHeight as Lang.Number,
                        radarAreaIsClean as Lang.Boolean,
                        mockRadar as Lang.Boolean) {
      self.bikeRadar = bikeRadar;
      self.xScreenProtectionArea = xScreenProtectionArea;
      self.yScreenProtectionArea = yScreenProtectionArea;
      self.radarAreaWidth = radarAreaWidth;
      self.radarAreaHeight = radarAreaHeight;
      self.radarAreaIsClean = radarAreaIsClean;
      self.mockRadar = mockRadar;
    }



    function _showVehicule(x as Lang.Number, height as Lang.Number,
                           radarInfo as Radar.MyRadarTarget) {
      $.sdk.changeColor(self.atLeastOneFastVehicule ? 0 : 8);
      if (radarInfo.range < MAX_RANGE_DETECTION && radarInfo.range > 0) {
        var yValue = height - radarInfo.range.toNumber() * MAX_RANGE_DETECTION /
                                  (height - self.borderOffset * 2);
        if (yValue > 0) {
            $.sdk.changeColor(self.atLeastOneFastVehicule ? 0 : 8);
            $.sdk.fullCircle(x, yValue.toNumber(),self.atLeastOneFastVehicule ?8 :6);
        }
      }
    }

    function clearRadarArea() {
      if (self.bikeRadar.isConnected() && self.bikeRadar.getMaxRange() == 0 &&
          self.radarAreaIsClean == false) {
        $.sdk.changeColor(0);
        $.sdk.fullRectangle(self.xScreenProtectionArea,
                            self.yScreenProtectionArea, self.radarAreaWidth,
                            self.radarAreaHeight);
        $.sdk.resetLayouts([]);
        radarAreaIsClean = true;
      }
    }

    function _isThereAtLeastOneFastVehicule(
        radarInfos as Lang.Array<Radar.MyRadarTarget>) as Lang.Boolean {
      for (var i = 0; i < self.bikeRadar.getRadarInfos().size(); i++) {
        if (radarInfos[i].threat ==
            AntPlus.THREAT_LEVEL_VEHICLE_FAST_APPROACHING) {
          return true;
        }
      }
      return false;
    }

    function updateRadarInfos(xScreenProtectionArea as Lang.Number) {
      self.xScreenProtectionArea = xScreenProtectionArea;
      if (self.mockRadar) {
        self.bikeRadar.listener.onBikeRadarUpdate([new AntPlus.RadarTarget()]);
      }

      if (self.bikeRadar.isConnected()) {
        if (toggleCircleIndicator) {
          $.sdk.changeColor(8);
          toggleCircleIndicator = false;
        } else {
          $.sdk.changeColor(0);
          toggleCircleIndicator = true;
        }
        $.sdk.fullCircle(
            self.xScreenProtectionArea > 110 ? self.xScreenProtectionArea + self.radarAreaWidth*3/4 : 110,
            212, 6);
        if (self.bikeRadar.getMaxRange() > 0) {
          $.sdk.changeColor(8);
          $.sdk.fullRectangle(self.xScreenProtectionArea,
                              self.yScreenProtectionArea, self.radarAreaWidth,
                              self.radarAreaHeight);

          self.atLeastOneFastVehicule = self._isThereAtLeastOneFastVehicule(
              self.bikeRadar.getRadarInfos());
          if (self.atLeastOneFastVehicule == false) {
            $.sdk.changeColor(0);
            $.sdk.fullRectangle(self.xScreenProtectionArea + self.borderOffset,
                                self.yScreenProtectionArea + self.borderOffset,
                                self.radarAreaWidth - self.borderOffset * 2,
                                self.radarAreaHeight - self.borderOffset * 2);
          }

          for (var i = 0; i < self.bikeRadar.getRadarInfos().size(); i++) {
            var radarInfo =
                (self.bikeRadar.getRadarInfos())[i] as Radar.MyRadarTarget;
            self._showVehicule(
                self.xScreenProtectionArea + self.radarAreaWidth / 2,
                self.radarAreaHeight, radarInfo);
          }

          self.radarAreaIsClean = false;
        }
      }
    }
  }
}