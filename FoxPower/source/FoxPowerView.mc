import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FoxPowerView extends WatchUi.DataField {

    hidden var currentPower as Numeric = 0;
    hidden var power3s as Float = 0.0f;
    hidden var normalizedPower as Numeric = 0;

    hidden var arrPower as Array<Numeric> or Null = null;
    hidden var npCounter as Numeric = 0;
    hidden var prevNP as Float = 0.0f;

    hidden var currentZone as Number = 1;
    hidden var zoneDecimal as Float = 0.0f;
    hidden var numZones as Number = 7;

    hidden var zoneSystem as Number = 1;
    hidden var manualFtp as Number = 0;

    hidden var ftp as Number = 200;
    hidden var thresholds7 as Array<Number> = [110, 150, 180, 210, 240, 300];
    hidden var thresholds5 as Array<Number> or Null = null;

    hidden var zoneHistogram as Array<Float>;
    hidden var prevTimerState as Number = 0;

    hidden var fontPrimary;
    hidden var fontPrimarySm;
    hidden var fontPrimaryXs;
    hidden var fontLabel;

    // Cached layout values (recomputed in onLayout)
    hidden var fieldWidth as Numeric = 140;
    hidden var fieldHeight as Numeric = 92;
    hidden var zoneColors as Array<Number> = [0x009E80, 0x009E00, 0xFFCB0E, 0xFF7F0E, 0xDD0447, 0x6633CC, 0x504861];
    hidden var zoneWidth as Number = 34;
    hidden var barY as Number = 90;
    hidden var primaryFont;
    hidden var centerY as Number = 46;
    hidden var npLabelOffsetY as Number = 0;

    function initialize() {
        DataField.initialize();
        zoneHistogram = new Array<Float>[7];
        for (var i = 0; i < 7; i++) { zoneHistogram[i] = 0.0f; }

        fontPrimary = loadResource(Rez.Fonts.fontPrimary);
        fontPrimarySm = loadResource(Rez.Fonts.fontPrimarySm);
        fontPrimaryXs = loadResource(Rez.Fonts.fontPrimaryXs);
        fontLabel = loadResource(Rez.Fonts.fontLabel);
        primaryFont = fontPrimarySm;

        loadSettings();
    }

    function loadSettings() as Void {
        if (!(Toybox.Application has :Properties)) { return; }
        zoneSystem = Application.Properties.getValue("zoneSystem");
        manualFtp = Application.Properties.getValue("manualFtp");

        numZones = zoneSystem == 0 ? 5 : 7;

        resolveFtp();
        resolveZones();
    }

    hidden function resolveFtp() as Void {
        if (manualFtp > 0) {
            ftp = manualFtp;
            return;
        }
        var profileFtp = FoxPowerZones.getFtp();
        if (profileFtp > 0) {
            ftp = profileFtp;
        }
    }

    hidden function resolveZones() as Void {
        if (zoneSystem == 0) {
            thresholds5 = FoxPowerZones.getGarminZones();
        }
        thresholds7 = FoxPowerZones.buildFrielThresholds(ftp);

        zoneColors = FoxPowerZones.getZoneColors(numZones);

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

        var numH = dc.getFontHeight(fontLabel);
        var npH = dc.getFontHeight(Graphics.FONT_SMALL);
        npLabelOffsetY = -8 + numH - npH - 2;
    }

    function compute(info as Activity.Info) as Void {
        var timerState = (info has :timerState) ? info.timerState : 0;
        if (timerState == 0 && prevTimerState != 0) {
            arrPower = null;
            npCounter = 0;
            prevNP = 0.0f;
            for (var i = 0; i < zoneHistogram.size(); i++) { zoneHistogram[i] = 0.0f; }
        }
        prevTimerState = timerState;

        if (info has :currentPower && info.currentPower != null) {
            currentPower = info.currentPower;
        } else {
            currentPower = 0;
            return;
        }

        computeRollingPower();
        computeNP();
        computeZone();

        if (currentPower > 0 && currentZone >= 1) {
            var idx = currentZone - 1;
            if (idx < zoneHistogram.size()) {
                zoneHistogram[idx] = zoneHistogram[idx] + 1.0f;
            }
        }
    }

    hidden function computeRollingPower() as Void {
        if (arrPower == null) {
            arrPower = [currentPower];
        } else if (arrPower.size() < 30) {
            arrPower.add(currentPower);
        } else {
            arrPower = FoxPowerMath.pushWindow(arrPower, currentPower);
        }

        var size = arrPower.size();
        if (size <= 3) {
            power3s = FoxPowerMath.mean(arrPower);
        } else {
            var slice = arrPower.slice(-3, null);
            power3s = FoxPowerMath.mean(slice);
        }
    }

    hidden function computeNP() as Void {
        if (arrPower == null || arrPower.size() < 30) {
            normalizedPower = 0;
            return;
        }
        var avg30s = FoxPowerMath.mean(arrPower);
        normalizedPower = FoxPowerMath.updateNormalizedPower(prevNP, npCounter, avg30s).toNumber();
        prevNP = normalizedPower.toFloat();
        npCounter++;
    }

    hidden function computeZone() as Void {
        var p = power3s;
        if (p <= 0) {
            currentZone = 1;
            zoneDecimal = 0.0f;
            return;
        }

        var result;
        if (zoneSystem == 0 && thresholds5 != null) {
            result = FoxPowerZones.calcZone5(p, thresholds5);
        } else {
            result = FoxPowerZones.calcZone7(p, thresholds7);
        }
        currentZone = result[0].toNumber();
        zoneDecimal = result[1];
    }

    function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = bgColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fgColor, bgColor);
        dc.clear();

        drawHistogram(dc);
        drawZoneBar(dc, fgColor);
        drawTopBar(dc, fgColor);
        drawPrimaryPower(dc);
    }

    hidden function drawHistogram(dc as Dc) as Void {
        var total = 0.0f;
        for (var i = 0; i < numZones; i++) { total += zoneHistogram[i]; }
        if (total == 0) { return; }

        var w = zoneWidth - 1;
        for (var z = 0; z < numZones; z++) {
            if (zoneHistogram[z] <= 0) { continue; }
            var barHeight = ((zoneHistogram[z] / total) * barY).toNumber();
            if (barHeight < 1) { barHeight = 1; }
            dc.setColor(zoneColors[z], -1);
            var xPos = 2 + zoneWidth * z;
            for (var line = 0; line < barHeight; line += 3) {
                var yPos = barY - line - 2;
                if (yPos < 0) { break; }
                dc.drawLine(xPos, yPos, xPos + w, yPos);
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
        var zoneColor = FoxPowerZones.getZoneColor(currentZone, numZones);
        dc.setColor(zoneColor, -1);
        dc.drawText(4, -8, fontLabel, "Z" + currentZone.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(fgColor, -1);
        var npNumStr = normalizedPower > 0 ? normalizedPower.format("%d") : "--";
        dc.drawText(fieldWidth - 4, -8, fontLabel, npNumStr, Graphics.TEXT_JUSTIFY_RIGHT);
        var numW = dc.getTextWidthInPixels(npNumStr, fontLabel);
        dc.drawText(fieldWidth - 4 - numW - 3, npLabelOffsetY, Graphics.FONT_SMALL, "NP", Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function drawPrimaryPower(dc as Dc) as Void {
        var zoneColor = FoxPowerZones.getZoneColor(currentZone, numZones);
        dc.setColor(zoneColor, -1);
        var pwrStr = power3s > 0 ? power3s.format("%d") : "--";
        dc.drawText(fieldWidth / 2, centerY, primaryFont, pwrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
