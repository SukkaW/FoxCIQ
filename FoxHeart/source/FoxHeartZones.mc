import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;

module FoxHeartZones {

    const FRIEL_LTHR as Array<Float> = [0.81, 0.89, 0.93, 0.99, 1.02, 1.06];
    const FRIEL_MAXHR as Array<Float> = [0.68, 0.73, 0.80, 0.89, 0.93, 1.00];
    const FRIEL_HRR as Array<Float> = [0.40, 0.55, 0.70, 0.80, 0.90, 0.95];

    const COLORS_5 as Array<Number> = [0x009E80, 0x009E00, 0xFFCB0E, 0xFF7F0E, 0xDD0447];
    const COLORS_7 as Array<Number> = [0x009E80, 0x009E00, 0xFFCB0E, 0xFF7F0E, 0xDD0447, 0x6633CC, 0x504861];

    function getGarminHrZones() as Array<Number> {
        var thresholds = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
        if (thresholds == null) {
            thresholds = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        }
        if (thresholds == null) {
            return [117, 144, 160, 171, 189, 192];
        }
        return thresholds;
    }

    function getMaxHrFromProfile() as Number {
        var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
        if (zones == null) {
            zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        }
        if (zones != null && zones.size() >= 6) {
            return zones[5];
        }
        return 0;
    }

    function getRestingHr() as Number {
        var profile = UserProfile.getProfile();
        if (profile != null && profile.restingHeartRate != null) {
            return profile.restingHeartRate;
        }
        return 60;
    }

    function buildFrielThresholds(method as Number, lthr as Number, maxHr as Number, restingHr as Number) as Array<Number> {
        var multipliers;
        var base;

        switch (method) {
            case 1:
                multipliers = FRIEL_MAXHR;
                base = maxHr;
                break;
            case 2:
                multipliers = FRIEL_HRR;
                var hrr = maxHr - restingHr;
                var t = new Array<Number>[6];
                for (var i = 0; i < 6; i++) {
                    t[i] = (restingHr + hrr * multipliers[i]).toNumber();
                }
                return t;
            default:
                multipliers = FRIEL_LTHR;
                base = lthr;
                break;
        }

        var t = new Array<Number>[6];
        for (var i = 0; i < 6; i++) {
            t[i] = (base * multipliers[i]).toNumber();
        }
        return t;
    }

    function calcZone7(hr as Numeric, thresholds as Array<Number>, out as Array<Float>) as Void {
        if (hr == null || hr <= 0) {
            out[0] = 0.0f;
            out[1] = 0.0f;
            return;
        }
        if (hr <= thresholds[0]) {
            out[0] = 1.0f;
            out[1] = hr.toFloat() / thresholds[0];
            return;
        }
        if (hr > thresholds[5]) {
            var dec = (hr - thresholds[5]).toFloat() / (thresholds[5] * 0.2);
            out[0] = 7.0f;
            out[1] = dec > 1.0 ? 1.0f : dec;
            return;
        }
        for (var i = 1; i < 6; i++) {
            if (hr > thresholds[i - 1] && hr <= thresholds[i]) {
                var lo = thresholds[i - 1].toFloat();
                var hi = thresholds[i].toFloat();
                out[0] = (i + 1).toFloat();
                out[1] = (hr.toFloat() - lo) / (hi - lo);
                return;
            }
        }
        out[0] = 1.0f;
        out[1] = 0.0f;
    }

    function calcZone5(hr as Numeric, thresholds as Array<Number>, out as Array<Float>) as Void {
        if (hr == null || hr <= 0) {
            out[0] = 0.0f;
            out[1] = 0.0f;
            return;
        }
        if (hr < thresholds[0]) {
            out[0] = 0.0f;
            out[1] = 0.0f;
            return;
        }
        if (hr > thresholds[5]) {
            out[0] = 5.0f;
            out[1] = 1.0f;
            return;
        }
        for (var i = 1; i < 6; i++) {
            if (hr > thresholds[i - 1] && hr <= thresholds[i]) {
                var lo = thresholds[i - 1].toFloat();
                var hi = thresholds[i].toFloat();
                out[0] = i.toFloat();
                out[1] = (hr.toFloat() - lo) / (hi - lo);
                return;
            }
        }
        out[0] = 0.0f;
        out[1] = 0.0f;
    }

    function getZoneColor(zone as Number, numZones as Number) as Number {
        if (zone == 0) { return Graphics.COLOR_LT_GRAY; }
        var colors = numZones == 7 ? COLORS_7 : COLORS_5;
        var idx = zone - 1;
        if (idx < 0) { return Graphics.COLOR_LT_GRAY; }
        if (idx >= colors.size()) { idx = colors.size() - 1; }
        return colors[idx];
    }

    function getZoneColors(numZones as Number) as Array<Number> {
        return numZones == 7 ? COLORS_7 : COLORS_5;
    }
}
