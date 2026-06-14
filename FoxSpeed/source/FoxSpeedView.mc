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
    }

    function compute(info as Activity.Info) as Void {
        var settings = System.getDeviceSettings();
        var distUnit = settings.distanceUnits;
        if (distUnit == System.UNIT_STATUTE) {
            unitLabel = "mi/h";
            distLabel = "mi";
        } else {
            unitLabel = "km/h";
            distLabel = "km";
        }

        if (info has :currentSpeed && info.currentSpeed != null) {
            var spd = info.currentSpeed as Float;
            if (distUnit == System.UNIT_STATUTE) {
                spd = spd * 2.23694f;
            } else {
                spd = spd * 3.6f;
            }
            rawCurrentSpd = spd;
            hasCurrent = true;
            if (spd >= 100.0f) {
                currentSpeed = spd.format("%d");
            } else {
                currentSpeed = spd.format("%.1f");
            }
        } else {
            currentSpeed = "--";
            hasCurrent = false;
        }

        if (info has :averageSpeed && info.averageSpeed != null) {
            var avg = info.averageSpeed as Float;
            if (distUnit == System.UNIT_STATUTE) {
                avg = avg * 2.23694f;
            } else {
                avg = avg * 3.6f;
            }
            rawAvgSpd = avg;
            hasAvg = true;
            avgSpeed = avg.format("%.1f");
        } else {
            avgSpeed = "--";
            hasAvg = false;
        }

        if (info has :elapsedDistance && info.elapsedDistance != null) {
            var dist = info.elapsedDistance as Float;
            if (distUnit == System.UNIT_STATUTE) {
                dist = dist / 1609.344f;
            } else {
                dist = dist / 1000.0f;
            }
            if (dist >= 100.0f) {
                distStr = dist.format("%d");
            } else {
                distStr = dist.format("%.1f");
            }
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
        var unitW = dc.getTextWidthInPixels(unitLabel, Graphics.FONT_XTINY);
        dc.drawText(fieldWidth - 2, 3, Graphics.FONT_XTINY, "avg", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(fieldWidth - 2 - unitW - 2, -6, fontLabelSm, avgSpeed, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function drawSpeed(dc as Dc, fgColor as Number) as Void {
        dc.setColor(fgColor, -1);
        var cy = centerY;
        var unitW = dc.getTextWidthInPixels(unitLabel, Graphics.FONT_XTINY);
        var unitFontH = dc.getFontHeight(Graphics.FONT_XTINY);
        var speedFontH = dc.getFontHeight(primaryFont);
        var speedBottom = cy + speedFontH / 2;

        dc.drawText(fieldWidth - 2, speedBottom - unitFontH - 3, Graphics.FONT_XTINY, unitLabel, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(fieldWidth - 2 - unitW - 2, cy, primaryFont, currentSpeed, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (hasCurrent && hasAvg) {
            var speedW = dc.getTextWidthInPixels(currentSpeed, primaryFont);
            var speedLeftX = fieldWidth - 2 - unitW - 2 - speedW;
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

        // LEFT: speedometer icon + current speed + km/h
        dc.drawBitmap(4, 2, iconSpeed);

        var speedCx = halfW / 2 + 20;
        var speedW = dc.getTextWidthInPixels(currentSpeed, primaryFont);

        var speedFontH = dc.getFontHeight(primaryFont);
        var unitFontH = dc.getFontHeight(Graphics.FONT_XTINY);
        dc.drawText(speedCx, cy, primaryFont, currentSpeed, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(speedCx + speedW / 2 + 1, cy + speedFontH / 4 - unitFontH, Graphics.FONT_XTINY, unitLabel, Graphics.TEXT_JUSTIFY_LEFT);

        if (hasCurrent && hasAvg) {
            var speedLeftX = speedCx - speedW / 2;
            if (rawCurrentSpd > rawAvgSpd) {
                dc.drawBitmap(speedLeftX - 22, cy + 1, iconChevronUp);
            } else if (rawCurrentSpd < rawAvgSpd) {
                dc.drawBitmap(speedLeftX - 22, cy + 1, iconChevronDown);
            }
        }

        // RIGHT: shared alignment
        var halfH = fieldHeight / 2;
        var secFontH = dc.getFontHeight(fontSecondary);
        var tinyFontH = dc.getFontHeight(Graphics.FONT_XTINY);
        var unitLabelW = dc.getTextWidthInPixels(unitLabel, Graphics.FONT_XTINY);
        var distLabelW = dc.getTextWidthInPixels(distLabel, Graphics.FONT_XTINY);
        var maxLabelW = unitLabelW > distLabelW ? unitLabelW : distLabelW;
        var numberRightX = fieldWidth - 2 - maxLabelW - 2;
        var labelLeftX = numberRightX + 2;

        // RIGHT TOP: avg [number] km/h — labels bottom-aligned with digits
        var topCy = halfH / 2;
        var topLabelY = topCy + secFontH / 4 - tinyFontH;
        dc.drawText(labelLeftX, topLabelY, Graphics.FONT_XTINY, unitLabel, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(numberRightX, topCy, fontSecondary, avgSpeed, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        var avgW = dc.getTextWidthInPixels(avgSpeed, fontSecondary);
        dc.drawText(numberRightX - avgW - 2, topLabelY, Graphics.FONT_XTINY, "avg", Graphics.TEXT_JUSTIFY_RIGHT);

        // RIGHT BOTTOM: [number] km — labels bottom-aligned with digits, number aligned with top row
        var botCy = halfH + halfH / 2;
        var botLabelY = botCy + secFontH / 4 - tinyFontH;
        dc.drawText(labelLeftX, botLabelY, Graphics.FONT_XTINY, distLabel, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(numberRightX, botCy, fontSecondary, distStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
