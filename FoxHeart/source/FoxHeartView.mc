import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FoxHeartView extends WatchUi.DataField {

    hidden var currentHR as Numeric = 0;
    hidden var hr3s as Float = 0.0f;

    hidden var arrHR as Array<Numeric> or Null = null;

    hidden var currentZone as Number = 0;
    hidden var zoneDecimal as Float = 0.0f;
    hidden var numZones as Number = 5;

    hidden var zoneBarHeight as Number = 2;
    hidden var zoneIndexHeight as Number = 4;
    hidden var zoneSystem as Number = 0;
    hidden var frielHrMethod as Number = 0;
    hidden var lthr as Number = 170;
    hidden var manualMaxHr as Number = 0;

    hidden var maxHR as Number = 190;
    hidden var restingHR as Number = 60;
    hidden var garminThresholds as Array<Number> = [117, 144, 160, 171, 189, 192];
    hidden var frielThresholds as Array<Number> = [138, 151, 158, 168, 173, 180];

    hidden var zoneHistogram as Array<Float>;
    hidden var normalizeOn as Boolean = false;
    hidden var prevTimerState as Number = 0;

    hidden var fontPrimary;
    hidden var fontPrimarySm;
    hidden var fontPrimaryXs;
    hidden var fontLabel;

    hidden var fieldWidth as Numeric = 140;
    hidden var fieldHeight as Numeric = 92;

    function initialize() {
        DataField.initialize();
        zoneHistogram = new Array<Float>[5];
        for (var i = 0; i < 5; i++) { zoneHistogram[i] = 0.0f; }

        fontPrimary = loadResource(Rez.Fonts.fontPrimary);
        fontPrimarySm = loadResource(Rez.Fonts.fontPrimarySm);
        fontPrimaryXs = loadResource(Rez.Fonts.fontPrimaryXs);
        fontLabel = loadResource(Rez.Fonts.fontLabel);

        loadSettings();
    }

    function loadSettings() as Void {
        if (!(Toybox.Application has :Properties)) { return; }
        zoneSystem = Application.Properties.getValue("zoneSystem");
        frielHrMethod = Application.Properties.getValue("frielHrMethod");
        lthr = Application.Properties.getValue("lthr");
        manualMaxHr = Application.Properties.getValue("manualMaxHr");
        zoneBarHeight = Application.Properties.getValue("zoneBarHeight");
        zoneIndexHeight = Application.Properties.getValue("zoneIndexHeight");

        numZones = zoneSystem == 0 ? 5 : 7;

        resolveMaxHR();
        resolveZones();
    }

    hidden function resolveMaxHR() as Void {
        if (manualMaxHr > 0) {
            maxHR = manualMaxHr;
            return;
        }
        var profileMaxHR = FoxHeartZones.getMaxHrFromProfile();
        if (profileMaxHR > 0) {
            maxHR = profileMaxHR;
        }
    }

    hidden function resolveZones() as Void {
        garminThresholds = FoxHeartZones.getGarminHrZones();
        restingHR = FoxHeartZones.getRestingHr();
        frielThresholds = FoxHeartZones.buildFrielThresholds(frielHrMethod, lthr, maxHR, restingHR);

        var histSize = numZones;
        if (zoneHistogram.size() != histSize) {
            zoneHistogram = new Array<Float>[histSize];
            for (var i = 0; i < histSize; i++) { zoneHistogram[i] = 0.0f; }
            normalizeOn = false;
        }
    }

    function onLayout(dc as Dc) as Void {
        fieldWidth = dc.getWidth();
        fieldHeight = dc.getHeight();
    }

    function compute(info as Activity.Info) as Void {
        var timerState = (info has :timerState) ? info.timerState : 0;
        if (timerState == 0 && prevTimerState != 0) {
            arrHR = null;
            for (var i = 0; i < zoneHistogram.size(); i++) { zoneHistogram[i] = 0.0f; }
            normalizeOn = false;
        }
        prevTimerState = timerState;

        if (info has :currentHeartRate && info.currentHeartRate != null) {
            currentHR = info.currentHeartRate;
        } else {
            currentHR = 0;
            return;
        }

        computeSmoothedHR();
        computeZone();

        if (currentHR > 0 && currentZone >= 1) {
            var idx = currentZone - 1;
            if (idx >= 0 && idx < zoneHistogram.size()) {
                zoneHistogram[idx] = zoneHistogram[idx] + 1.0f;
            }
        }
    }

    hidden function computeSmoothedHR() as Void {
        if (arrHR == null) {
            arrHR = [currentHR];
        } else if (arrHR.size() < 30) {
            arrHR.add(currentHR);
        } else {
            arrHR = FoxHeartMath.pushWindow(arrHR, currentHR);
        }

        var size = arrHR.size();
        if (size <= 3) {
            hr3s = FoxHeartMath.mean(arrHR);
        } else {
            var slice = arrHR.slice(-3, null);
            hr3s = FoxHeartMath.mean(slice);
        }
    }

    hidden function computeZone() as Void {
        var hr = hr3s;
        if (hr <= 0) {
            currentZone = 0;
            zoneDecimal = 0.0f;
            return;
        }

        var result;
        if (zoneSystem == 0) {
            result = FoxHeartZones.calcZone5(hr, garminThresholds);
        } else {
            result = FoxHeartZones.calcZone7(hr, frielThresholds);
        }
        currentZone = result[0].toNumber();
        zoneDecimal = result[1];
    }

    function onUpdate(dc as Dc) as Void {
        fieldWidth = dc.getWidth();
        fieldHeight = dc.getHeight();

        var bgColor = getBackgroundColor();
        var fgColor = bgColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fgColor, bgColor);
        dc.clear();

        var barTotal = zoneBarHeight;
        var barY = fieldHeight - barTotal;

        drawHistogram(dc, barY);
        drawZoneBar(dc, barY, barTotal, fgColor);
        drawTopBar(dc, fgColor);
        drawPrimaryHR(dc);
    }

    hidden function drawHistogram(dc as Dc, barY as Numeric) as Void {
        var colors = FoxHeartZones.getZoneColors(numZones);
        var zoneWidth = Math.round((fieldWidth - 4.0) / numZones);
        var maxGridHeight = barY;

        var total = 0.0f;
        for (var i = 0; i < numZones; i++) { total += zoneHistogram[i]; }
        if (total == 0) { return; }

        for (var z = 0; z < numZones; z++) {
            if (zoneHistogram[z] <= 0) { continue; }
            var pct = zoneHistogram[z] / total;
            var barHeight = (pct * maxGridHeight).toNumber();
            if (barHeight < 1) { barHeight = 1; }
            dc.setColor(colors[z], -1);
            var xPos = 2 + zoneWidth * z;
            var w = zoneWidth - 1;
            for (var line = 0; line < barHeight; line += 3) {
                var yPos = barY - line - 2;
                if (yPos < 0) { break; }
                dc.drawLine(xPos, yPos, xPos + w, yPos);
            }
        }
    }

    hidden function drawZoneBar(dc as Dc, barY as Numeric, barTotal as Numeric, fgColor as Number) as Void {
        var colors = FoxHeartZones.getZoneColors(numZones);
        var zoneWidth = Math.round((fieldWidth - 4.0) / numZones);

        for (var z = 0; z < numZones; z++) {
            dc.setColor(colors[z], -1);
            dc.fillRectangle(2 + zoneWidth * z, fieldHeight - barTotal, zoneWidth - 1, barTotal);
        }

        var arrowX = 2.0;
        if (currentZone >= 1 && currentZone <= numZones) {
            arrowX = 2.0 + zoneWidth * (currentZone - 1) + zoneWidth * zoneDecimal;
        }
        dc.setColor(fgColor, -1);
        dc.fillPolygon([[arrowX - 3, fieldHeight], [arrowX + 3, fieldHeight], [arrowX, fieldHeight - barTotal - 3]]);
    }

    hidden function drawTopBar(dc as Dc, fgColor as Number) as Void {
        var zoneColor = FoxHeartZones.getZoneColor(currentZone, numZones);
        dc.setColor(zoneColor, -1);
        var zoneStr = currentZone > 0 ? "Z" + currentZone.format("%d") : "--";
        dc.drawText(4, -8, fontLabel, zoneStr, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(fgColor, -1);
        var pctStr = "--";
        if (currentHR > 0 && maxHR > 0) {
            var pct = (currentHR * 100) / maxHR;
            pctStr = pct.format("%d") + "%";
        }
        dc.drawText(fieldWidth - 4, -8, fontLabel, pctStr, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function drawPrimaryHR(dc as Dc) as Void {
        var zoneColor = FoxHeartZones.getZoneColor(currentZone, numZones);
        dc.setColor(zoneColor, -1);

        var topBarHeight = 18;
        var barTotal = zoneBarHeight + 6;
        var font;
        if (fieldHeight > 160) {
            font = fontPrimary;
        } else if (fieldHeight > 80) {
            font = fontPrimarySm;
        } else {
            font = fontPrimaryXs;
        }
        var centerY = topBarHeight + (fieldHeight - barTotal - topBarHeight) / 2;
        var hrStr = currentHR > 0 ? currentHR.format("%d") : "--";
        dc.drawText(fieldWidth / 2, centerY, font, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
