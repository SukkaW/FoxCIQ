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
    hidden var pwrStr as String = "--";
    hidden var npStr as String = "--";
    hidden var zoneStr as String = "1";

    hidden var smooth3s;
    hidden var smooth30s;
    hidden var npCounter as Numeric = 0;
    hidden var prevAvgP4 as Float = 0.0f;

    hidden var _zoneResult as Array<Float> = [0.0f, 0.0f];
    hidden var _npResult as Array<Float> = [0.0f, 0.0f];
    hidden var currentZone as Number = 1;
    hidden var zoneDecimal as Float = 0.0f;
    hidden var numZones as Number = 7;
    hidden var cachedZoneColor as Number = 0x009E80;

    hidden var zoneSystem as Number = 1;

    hidden var ftp as Number = 200;
    hidden var thresholds7 as Array<Number> = [110, 150, 180, 210, 240, 300];
    hidden var thresholds5 as Array<Number> or Null = null;

    hidden var zoneHistogram as Array<Float>;
    hidden var prevTimerState as Number = 0;

    hidden var fontPrimary;
    hidden var fontPrimarySm;
    hidden var fontPrimaryXs;
    hidden var fontLabel;
    hidden var iconBolt;

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
        smooth3s = new FoxPowerMath.RollingAvg(3);
        smooth30s = new FoxPowerMath.RollingAvg(30);
        zoneHistogram = new Array<Float>[7];
        for (var i = 0; i < 7; i++) { zoneHistogram[i] = 0.0f; }

        fontPrimary = loadResource(Rez.Fonts.fontPrimary);
        fontPrimarySm = loadResource(Rez.Fonts.fontPrimarySm);
        fontPrimaryXs = loadResource(Rez.Fonts.fontPrimaryXs);
        fontLabel = loadResource(Rez.Fonts.fontLabel);
        iconBolt = loadResource(Rez.Drawables.iconBolt);
        primaryFont = fontPrimarySm;

        loadProfile();
        loadSettings();
    }

    hidden function loadProfile() as Void {
        var pFtp = FoxPowerZones.getFtp();
        if (pFtp > 0) { ftp = pFtp; }
        thresholds5 = FoxPowerZones.getGarminZones();
    }

    function loadSettings() as Void {
        if (!(Toybox.Application has :Properties)) { return; }
        zoneSystem = Application.Properties.getValue("zoneSystem");

        numZones = zoneSystem == 0 ? 5 : 7;
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
            smooth3s.reset();
            smooth30s.reset();
            npCounter = 0;
            prevAvgP4 = 0.0f;
            for (var i = 0; i < zoneHistogram.size(); i++) { zoneHistogram[i] = 0.0f; }
        }
        prevTimerState = timerState;

        if (info has :currentPower && info.currentPower != null) {
            currentPower = info.currentPower;
        } else {
            currentPower = 0;
            pwrStr = "--";
            npStr = "--";
            return;
        }

        computeRollingPower();
        computeNP();
        computeZone();

        pwrStr = power3s > 0 ? power3s.format("%d") : "--";
        npStr = normalizedPower > 0 ? normalizedPower.format("%d") : "--";
        zoneStr = currentZone.format("%d");

        if (currentPower > 0 && currentZone >= 1) {
            var idx = currentZone - 1;
            if (idx < zoneHistogram.size()) {
                zoneHistogram[idx] = zoneHistogram[idx] + 1.0f;
            }
        }
    }

    hidden function computeRollingPower() as Void {
        smooth30s.update(currentPower);
        power3s = smooth3s.update(currentPower);
    }

    hidden function computeNP() as Void {
        if (!smooth30s.isFull()) {
            normalizedPower = 0;
            return;
        }
        var avg30s = smooth30s.avg();
        FoxPowerMath.updateNormalizedPower(prevAvgP4, npCounter, avg30s, _npResult);
        normalizedPower = _npResult[0].toNumber();
        prevAvgP4 = _npResult[1];
        npCounter++;
    }

    hidden function computeZone() as Void {
        var p = power3s;
        if (p <= 0) {
            currentZone = 1;
            zoneDecimal = 0.0f;
            cachedZoneColor = zoneColors[0];
            return;
        }

        if (zoneSystem == 0 && thresholds5 != null) {
            FoxPowerZones.calcZone5(p, thresholds5, _zoneResult);
        } else {
            FoxPowerZones.calcZone7(p, thresholds7, _zoneResult);
        }
        currentZone = _zoneResult[0].toNumber();
        zoneDecimal = _zoneResult[1];
        cachedZoneColor = FoxPowerZones.getZoneColor(currentZone, numZones);
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
        dc.drawBitmap(2, -2, iconBolt);
        dc.setColor(cachedZoneColor, -1);
        dc.drawText(26, -8, fontLabel, zoneStr, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(fgColor, -1);
        dc.drawText(fieldWidth - 4, -8, fontLabel, npStr, Graphics.TEXT_JUSTIFY_RIGHT);
        var numW = dc.getTextWidthInPixels(npStr, fontLabel);
        dc.drawText(fieldWidth - 4 - numW - 3, npLabelOffsetY, Graphics.FONT_SMALL, "NP", Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function drawPrimaryPower(dc as Dc) as Void {
        dc.setColor(cachedZoneColor, -1);
        dc.drawText(fieldWidth / 2, centerY, primaryFont, pwrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
