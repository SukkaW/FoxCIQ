import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FoxSpeedView extends WatchUi.DataField {

    hidden var currentSpeed as String = "--";
    hidden var avgSpeed as String = "--";
    hidden var distStr as String = "--";
    hidden var unitLabel as String = "km/h";
    hidden var distLabel as String = "km";
    hidden var rawCurrentSpd as Float = 0.0f;
    hidden var rawAvgSpd as Float = 0.0f;
    hidden var hasAvg as Boolean = false;
    hidden var hasCurrent as Boolean = false;
    hidden var isStatute as Boolean = false;
    hidden var spdMultiplier as Float = 3.6f;
    hidden var distDivisor as Float = 1000.0f;

    hidden var fontPrimary;
    hidden var fontPrimarySm;
    hidden var fontPrimaryXs;
    hidden var fontWide;
    hidden var fontSecondary;
    hidden var fontLabel;
    hidden var fontLabelSm;
    hidden var iconSpeed;
    hidden var iconChevronUp;
    hidden var iconChevronDown;

    hidden var fieldWidth as Numeric = 140;
    hidden var fieldHeight as Numeric = 92;
    hidden var primaryFont;
    hidden var centerY as Number = 60;
    hidden var isWide as Boolean = false;
    hidden var cachedUnitW as Number = 0;
    hidden var cachedUnitFontH as Number = 0;
    hidden var cachedSpeedFontH as Number = 0;
    hidden var cachedSecFontH as Number = 0;
    hidden var cachedDistLabelW as Number = 0;

    function initialize() {
        DataField.initialize();

        fontPrimary = loadResource(Rez.Fonts.fontPrimary);
        fontPrimarySm = loadResource(Rez.Fonts.fontPrimarySm);
        fontPrimaryXs = loadResource(Rez.Fonts.fontPrimaryXs);
        fontWide = loadResource(Rez.Fonts.fontWide);
        fontSecondary = loadResource(Rez.Fonts.fontSecondary);
        fontLabel = loadResource(Rez.Fonts.fontLabel);
        fontLabelSm = loadResource(Rez.Fonts.fontLabelSm);
        iconSpeed = loadResource(Rez.Drawables.iconSpeed);
        iconChevronUp = loadResource(Rez.Drawables.iconChevronUp);
        iconChevronDown = loadResource(Rez.Drawables.iconChevronDown);

        primaryFont = fontPrimarySm;

        var distUnit = System.getDeviceSettings().distanceUnits;
        isStatute = distUnit == System.UNIT_STATUTE;
        if (isStatute) {
            unitLabel = "mi/h";
            distLabel = "mi";
            spdMultiplier = 2.23694f;
            distDivisor = 1609.344f;
        } else {
            unitLabel = "km/h";
            distLabel = "km";
            spdMultiplier = 3.6f;
            distDivisor = 1000.0f;
        }
    }

    function onLayout(dc as Dc) as Void {
        fieldWidth = dc.getWidth();
        fieldHeight = dc.getHeight();
        isWide = fieldWidth > 200;

        if (isWide) {
            primaryFont = fontWide;
        } else {
            if (fieldHeight > 120) {
                primaryFont = fontPrimary;
            } else if (fieldHeight > 80) {
                primaryFont = fontPrimarySm;
            } else {
                primaryFont = fontPrimaryXs;
            }
        }
        centerY = 18 + (fieldHeight - 18) / 2;

        cachedUnitW = dc.getTextWidthInPixels(unitLabel, Graphics.FONT_XTINY);
        cachedUnitFontH = dc.getFontHeight(Graphics.FONT_XTINY);
        cachedSpeedFontH = dc.getFontHeight(primaryFont);
        cachedSecFontH = dc.getFontHeight(fontSecondary);
        cachedDistLabelW = dc.getTextWidthInPixels(distLabel, Graphics.FONT_XTINY);
    }

    function compute(info as Activity.Info) as Void {
        if (info has :currentSpeed && info.currentSpeed != null) {
            var spd = (info.currentSpeed as Float) * spdMultiplier;
            rawCurrentSpd = spd;
            hasCurrent = true;
            currentSpeed = spd >= 100.0f ? spd.format("%d") : spd.format("%.1f");
        } else {
            currentSpeed = "--";
            hasCurrent = false;
        }

        if (info has :averageSpeed && info.averageSpeed != null) {
            var avg = (info.averageSpeed as Float) * spdMultiplier;
            rawAvgSpd = avg;
            hasAvg = true;
            avgSpeed = avg.format("%.1f");
        } else {
            avgSpeed = "--";
            hasAvg = false;
        }

        if (info has :elapsedDistance && info.elapsedDistance != null) {
            var dist = (info.elapsedDistance as Float) / distDivisor;
            distStr = dist >= 100.0f ? dist.format("%d") : dist.format("%.1f");
        } else {
            distStr = "--";
        }
    }

    function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = bgColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fgColor, bgColor);
        dc.clear();

        if (isWide) {
            drawWideLayout(dc, fgColor);
        } else {
            drawTopBar(dc, fgColor);
            drawSpeed(dc, fgColor);
        }
    }

    hidden function drawTopBar(dc as Dc, fgColor as Number) as Void {
        dc.drawBitmap(4, 2, iconSpeed);

        dc.setColor(fgColor, -1);
        dc.drawText(fieldWidth - 2, 3, Graphics.FONT_XTINY, "avg", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(fieldWidth - 2 - cachedUnitW - 2, -6, fontLabelSm, avgSpeed, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function drawSpeed(dc as Dc, fgColor as Number) as Void {
        dc.setColor(fgColor, -1);
        var cy = centerY;
        var speedBottom = cy + cachedSpeedFontH / 2;

        dc.drawText(fieldWidth - 2, speedBottom - cachedUnitFontH - 3, Graphics.FONT_XTINY, unitLabel, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(fieldWidth - 2 - cachedUnitW - 2, cy, primaryFont, currentSpeed, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (hasCurrent && hasAvg) {
            var speedW = dc.getTextWidthInPixels(currentSpeed, primaryFont);
            var speedLeftX = fieldWidth - 2 - cachedUnitW - 2 - speedW;
            if (rawCurrentSpd > rawAvgSpd) {
                dc.drawBitmap(speedLeftX - 22, cy - 3, iconChevronUp);
            } else if (rawCurrentSpd < rawAvgSpd) {
                dc.drawBitmap(speedLeftX - 22, cy - 3, iconChevronDown);
            }
        }
    }

    hidden function drawWideLayout(dc as Dc, fgColor as Number) as Void {
        dc.setColor(fgColor, -1);
        var halfW = fieldWidth / 2;
        var cy = fieldHeight / 2;

        dc.drawBitmap(4, 2, iconSpeed);

        var speedCx = halfW / 2 + 20;
        var speedW = dc.getTextWidthInPixels(currentSpeed, primaryFont);

        dc.drawText(speedCx, cy, primaryFont, currentSpeed, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(speedCx + speedW / 2 + 1, cy + cachedSpeedFontH / 4 - cachedUnitFontH, Graphics.FONT_XTINY, unitLabel, Graphics.TEXT_JUSTIFY_LEFT);

        if (hasCurrent && hasAvg) {
            var speedLeftX = speedCx - speedW / 2;
            if (rawCurrentSpd > rawAvgSpd) {
                dc.drawBitmap(speedLeftX - 22, cy + 1, iconChevronUp);
            } else if (rawCurrentSpd < rawAvgSpd) {
                dc.drawBitmap(speedLeftX - 22, cy + 1, iconChevronDown);
            }
        }

        var halfH = fieldHeight / 2;
        var maxLabelW = cachedUnitW > cachedDistLabelW ? cachedUnitW : cachedDistLabelW;
        var numberRightX = fieldWidth - 2 - maxLabelW - 2;
        var labelLeftX = numberRightX + 2;

        var topCy = halfH / 2;
        var topLabelY = topCy + cachedSecFontH / 4 - cachedUnitFontH;
        dc.drawText(labelLeftX, topLabelY, Graphics.FONT_XTINY, unitLabel, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(numberRightX, topCy, fontSecondary, avgSpeed, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        var avgW = dc.getTextWidthInPixels(avgSpeed, fontSecondary);
        dc.drawText(numberRightX - avgW - 2, topLabelY, Graphics.FONT_XTINY, "avg", Graphics.TEXT_JUSTIFY_RIGHT);

        var botCy = halfH + halfH / 2;
        var botLabelY = botCy + cachedSecFontH / 4 - cachedUnitFontH;
        dc.drawText(labelLeftX, botLabelY, Graphics.FONT_XTINY, distLabel, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(numberRightX, botCy, fontSecondary, distStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
