import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FoxHeartView extends WatchUi.DataField {

    hidden var profileWarning as String or Null = null;
    hidden var hasReceivedData as Boolean = false;

    hidden var currentHR as Numeric = 0;
    hidden var hr3s as Float = 0.0f;
    hidden var hrPctStr as String = "--";
    hidden var hrStr as String = "--";
    hidden var zoneStr as String = "--";

    hidden var smooth3s;

    hidden var _zoneResult as Array<Float> = [0.0f, 0.0f];
    hidden var currentZone as Number = 0;
    hidden var zoneDecimal as Float = 0.0f;
    hidden var numZones as Number = 5;
    hidden var cachedZoneColor as Number = 0xAAAAAA;

    hidden var zoneSystem as Number = 0;
    hidden var frielHrMethod as Number = 0;
    hidden var lthr as Number = 170;
    hidden var manualMaxHr as Number = 0;
    hidden var manualRestingHr as Number = 0;

    hidden var profileMaxHR as Number = 190;
    hidden var profileRestingHR as Number = 60;
    hidden var maxHR as Number = 190;
    hidden var restingHR as Number = 60;
    hidden var garminThresholds as Array<Number> = [117, 144, 160, 171, 189, 192];
    hidden var frielThresholds as Array<Number> = [138, 151, 158, 168, 173, 180];

    hidden var zoneHistogram as Array<Float>;
    hidden var prevTimerState as Number = 0;

    hidden var fontPrimary;
    hidden var fontPrimarySm;
    hidden var fontPrimaryXs;
    hidden var fontLabel;
    hidden var iconHeart;

    // Cached layout values (recomputed in onLayout)
    hidden var fieldWidth as Numeric = 140;
    hidden var fieldHeight as Numeric = 92;
    hidden var zoneColors as Array<Number> = [0x009E80, 0x009E00, 0xFFCB0E, 0xFF7F0E, 0xDD0447];
    hidden var zoneWidth as Number = 27;
    hidden var barY as Number = 90;
    hidden var primaryFont;
    hidden var centerY as Number = 46;

    function initialize() {
        DataField.initialize();
        smooth3s = new FoxHeartMath.RollingAvg(3);
        zoneHistogram = new Array<Float>[5];
        for (var i = 0; i < 5; i++) { zoneHistogram[i] = 0.0f; }

        fontPrimary = loadResource(Rez.Fonts.fontPrimary);
        fontPrimarySm = loadResource(Rez.Fonts.fontPrimarySm);
        fontPrimaryXs = loadResource(Rez.Fonts.fontPrimaryXs);
        fontLabel = loadResource(Rez.Fonts.fontLabel);
        iconHeart = loadResource(Rez.Drawables.iconHeart);
        primaryFont = fontPrimarySm;

        loadProfile();
        loadSettings();
    }

    hidden function loadProfile() as Void {
        garminThresholds = FoxHeartZones.getGarminHrZones();
        var pMax = FoxHeartZones.getMaxHrFromProfile();
        if (pMax > 0) {
            profileMaxHR = pMax;
        } else {
            profileWarning = "No Max HR in profile";
        }
        profileRestingHR = FoxHeartZones.getRestingHr();
    }

    function loadSettings() as Void {
        if (!(Toybox.Application has :Properties)) { return; }
        zoneSystem = Application.Properties.getValue("zoneSystem");
        frielHrMethod = Application.Properties.getValue("frielHrMethod");
        lthr = Application.Properties.getValue("lthr");
        manualMaxHr = Application.Properties.getValue("manualMaxHr");
        manualRestingHr = Application.Properties.getValue("manualRestingHr");

        numZones = zoneSystem == 0 ? 5 : 7;

        maxHR = manualMaxHr > 0 ? manualMaxHr : profileMaxHR;
        restingHR = manualRestingHr > 0 ? manualRestingHr : profileRestingHR;
        frielThresholds = FoxHeartZones.buildFrielThresholds(frielHrMethod, lthr, maxHR, restingHR);

        zoneColors = FoxHeartZones.getZoneColors(numZones);

        var histSize = numZones;
        if (zoneHistogram.size() != histSize) {
            zoneHistogram = new Array<Float>[histSize];
            for (var i = 0; i < histSize; i++) { zoneHistogram[i] = 0.0f; }
        }
    }

    function onLayout(dc as Dc) as Void {
        fieldWidth = dc.getWidth();
        fieldHeight = dc.getHeight();

        zoneWidth = Math.round((fieldWidth - 4.0) / numZones);
        barY = fieldHeight - 2;

        if (fieldHeight > 160) {
            primaryFont = fontPrimary;
        } else if (fieldHeight > 80) {
            primaryFont = fontPrimarySm;
        } else {
            primaryFont = fontPrimaryXs;
        }
        centerY = 18 + (fieldHeight - 8 - 18) / 2;
    }

    function compute(info as Activity.Info) as Void {
        var timerState = (info has :timerState) ? info.timerState : 0;
        if (timerState == 0 && prevTimerState != 0) {
            smooth3s.reset();
            for (var i = 0; i < zoneHistogram.size(); i++) { zoneHistogram[i] = 0.0f; }
        }
        prevTimerState = timerState;

        if (info has :currentHeartRate && info.currentHeartRate != null) {
            currentHR = info.currentHeartRate;
            hasReceivedData = true;
        } else {
            currentHR = 0;
            hrPctStr = "--";
            hrStr = "--";
            return;
        }

        if (maxHR > 0) {
            hrPctStr = ((currentHR * 100) / maxHR).format("%d") + "%";
        } else {
            hrPctStr = "--";
        }
        hrStr = currentHR.format("%d");

        computeSmoothedHR();
        computeZone();

        zoneStr = currentZone > 0 ? currentZone.format("%d") : "--";

        if (currentHR > 0 && currentZone >= 1) {
            var idx = currentZone - 1;
            if (idx < zoneHistogram.size()) {
                zoneHistogram[idx] = zoneHistogram[idx] + 1.0f;
            }
        }
    }

    hidden function computeSmoothedHR() as Void {
        hr3s = smooth3s.update(currentHR);
    }

    hidden function computeZone() as Void {
        var hr = hr3s;
        if (hr <= 0) {
            currentZone = 0;
            zoneDecimal = 0.0f;
            cachedZoneColor = Graphics.COLOR_LT_GRAY;
            return;
        }

        if (zoneSystem == 0) {
            FoxHeartZones.calcZone5(hr, garminThresholds, _zoneResult);
        } else {
            FoxHeartZones.calcZone7(hr, frielThresholds, _zoneResult);
        }
        currentZone = _zoneResult[0].toNumber();
        zoneDecimal = _zoneResult[1];
        cachedZoneColor = FoxHeartZones.getZoneColor(currentZone, numZones);
    }

    function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = bgColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fgColor, bgColor);
        dc.clear();

        if (profileWarning != null && !hasReceivedData) {
            dc.drawText(fieldWidth / 2, fieldHeight / 2, Graphics.FONT_SMALL, profileWarning, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        drawHistogram(dc);
        drawZoneBar(dc, fgColor);
        drawTopBar(dc, fgColor);
        drawPrimaryHR(dc);
    }

    hidden function drawHistogram(dc as Dc) as Void {
        var total = 0.0f;
        for (var i = 0; i < numZones; i++) { total += zoneHistogram[i]; }
        if (total == 0) { return; }

        var invTotal = 1.0f / total;
        var w = zoneWidth - 1;
        for (var z = 0; z < numZones; z++) {
            if (zoneHistogram[z] <= 0) { continue; }
            var barHeight = ((zoneHistogram[z] * invTotal) * barY).toNumber();
            if (barHeight < 1) { barHeight = 1; }
            dc.setColor(zoneColors[z], -1);
            var xPos = 2 + zoneWidth * z;
            for (var line = 0; line < barHeight; line += 3) {
                var yPos = barY - line - 2;
                if (yPos < 0) { break; }
                dc.fillRectangle(xPos, yPos, w, 1);
            }
        }
    }

    hidden function drawZoneBar(dc as Dc, fgColor as Number) as Void {
        for (var z = 0; z < numZones; z++) {
            dc.setColor(zoneColors[z], -1);
            dc.fillRectangle(2 + zoneWidth * z, fieldHeight - 2, zoneWidth - 1, 2);
        }

        var arrowX = 2.0;
        if (currentZone >= 1 && currentZone <= numZones) {
            arrowX = 2.0 + zoneWidth * (currentZone - 1) + zoneWidth * zoneDecimal;
        }
        dc.setColor(fgColor, -1);
        dc.fillPolygon([[arrowX - 3, fieldHeight], [arrowX + 3, fieldHeight], [arrowX, fieldHeight - 5]]);
    }

    hidden function drawTopBar(dc as Dc, fgColor as Number) as Void {
        dc.drawBitmap(2, -2, iconHeart);
        dc.setColor(cachedZoneColor, -1);
        dc.drawText(26, -8, fontLabel, zoneStr, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(fgColor, -1);
        dc.drawText(fieldWidth - 4, -8, fontLabel, hrPctStr, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function drawPrimaryHR(dc as Dc) as Void {
        dc.setColor(cachedZoneColor, -1);
        dc.drawText(fieldWidth / 2, centerY, primaryFont, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
