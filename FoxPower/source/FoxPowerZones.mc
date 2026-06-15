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
        var zones = UserProfile.getPowerZones(Activity.SPORT_CYCLING);
        if (zones == null) {
            zones = UserProfile.getPowerZones(Activity.SPORT_GENERIC);
        }
        return zones;
    }

    function buildFrielThresholds(ftp as Number) as Array<Number> {
        var t = new Array<Number>[6];
        for (var i = 0; i < 6; i++) {
            t[i] = (ftp * FRIEL_MULTIPLIERS[i]).toNumber();
        }
        return t;
    }

    function calcZone7(power as Numeric, thresholds as Array<Number>, out as Array<Float>) as Void {
        if (power == null || power <= 0) {
            out[0] = 1.0f;
            out[1] = 0.0f;
            return;
        }
        if (power <= thresholds[0]) {
            out[0] = 1.0f;
            out[1] = power.toFloat() / thresholds[0];
            return;
        }
        if (power > thresholds[5]) {
            var dec = (power - thresholds[5]).toFloat() / (thresholds[5] * 0.5);
            out[0] = 7.0f;
            out[1] = dec > 1.0 ? 1.0f : dec;
            return;
        }
        for (var i = 1; i < 6; i++) {
            if (power > thresholds[i - 1] && power <= thresholds[i]) {
                var lo = thresholds[i - 1].toFloat();
                var hi = thresholds[i].toFloat();
                out[0] = (i + 1).toFloat();
                out[1] = (power.toFloat() - lo) / (hi - lo);
                return;
            }
        }
        out[0] = 1.0f;
        out[1] = 0.0f;
    }

    function calcZone5(power as Numeric, thresholds as Array<Number>, out as Array<Float>) as Void {
        if (power == null || power <= 0) {
            out[0] = 1.0f;
            out[1] = 0.0f;
            return;
        }
        var numZones = thresholds.size() - 1;
        if (numZones < 1) {
            out[0] = 1.0f;
            out[1] = 0.0f;
            return;
        }

        if (power < thresholds[0]) {
            out[0] = 1.0f;
            out[1] = 0.0f;
            return;
        }

        for (var i = 1; i <= numZones; i++) {
            if (i >= thresholds.size()) { break; }
            if (power >= thresholds[i - 1] && power < thresholds[i]) {
                var lo = thresholds[i - 1].toFloat();
                var hi = thresholds[i].toFloat();
                out[0] = i.toFloat();
                out[1] = (power.toFloat() - lo) / (hi - lo);
                return;
            }
        }
        out[0] = numZones.toFloat();
        out[1] = 1.0f;
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
