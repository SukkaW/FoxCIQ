import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;

module FoxPowerZones {

    const FRIEL_MULTIPLIERS as Array<Float> = [0.55, 0.75, 0.90, 1.05, 1.20, 1.50];

    const COLORS_5 as Array<Number> = [0x009E80, 0x009E00, 0xFFCB0E, 0xFF7F0E, 0xDD0447];
    const COLORS_7 as Array<Number> = [0x009E80, 0x009E00, 0xFFCB0E, 0xFF7F0E, 0xDD0447, 0x6633CC, 0x504861];

    function getFtp() as Number {
        var ftp = UserProfile.getFunctionalThresholdPower(Activity.SPORT_CYCLING);
        if (ftp != null && ftp > 0) {
            return ftp;
        }
        return 0;
    }

    function getGarminZones() as Array<Number> or Null {
        return UserProfile.getPowerZones(Activity.SPORT_CYCLING);
    }

    function buildFrielThresholds(ftp as Number) as Array<Number> {
        var t = new Array<Number>[6];
        for (var i = 0; i < 6; i++) {
            t[i] = (ftp * FRIEL_MULTIPLIERS[i]).toNumber();
        }
        return t;
    }

    function calcZone7(power as Numeric, thresholds as Array<Number>) as Array<Float> {
        if (power == null || power <= 0) {
            return [1.0f, 0.0f];
        }
        if (power <= thresholds[0]) {
            return [1.0f, power.toFloat() / thresholds[0]];
        }
        if (power > thresholds[5]) {
            var dec = (power - thresholds[5]).toFloat() / (thresholds[5] * 0.5);
            return [7.0f, dec > 1.0 ? 1.0f : dec];
        }
        for (var i = 1; i < 6; i++) {
            if (power > thresholds[i - 1] && power <= thresholds[i]) {
                var lo = thresholds[i - 1].toFloat();
                var hi = thresholds[i].toFloat();
                return [(i + 1).toFloat(), (power.toFloat() - lo) / (hi - lo)];
            }
        }
        return [1.0f, 0.0f];
    }

    function calcZone5(power as Numeric, thresholds as Array<Number>) as Array<Float> {
        if (power == null || power <= 0) {
            return [1.0f, 0.0f];
        }
        var numZones = thresholds.size() - 1;
        if (numZones < 1) { return [1.0f, 0.0f]; }

        if (power < thresholds[0]) {
            return [1.0f, 0.0f];
        }

        for (var i = 1; i <= numZones; i++) {
            if (i >= thresholds.size()) { break; }
            if (power >= thresholds[i - 1] && power < thresholds[i]) {
                var lo = thresholds[i - 1].toFloat();
                var hi = thresholds[i].toFloat();
                return [i.toFloat(), (power.toFloat() - lo) / (hi - lo)];
            }
        }
        return [numZones.toFloat(), 1.0f];
    }

    function getZoneColor(zone as Number, numZones as Number) as Number {
        var colors = numZones == 7 ? COLORS_7 : COLORS_5;
        var idx = zone - 1;
        if (idx < 0) { idx = 0; }
        if (idx >= colors.size()) { idx = colors.size() - 1; }
        return colors[idx];
    }

    function getZoneColors(numZones as Number) as Array<Number> {
        return numZones == 7 ? COLORS_7 : COLORS_5;
    }
}
