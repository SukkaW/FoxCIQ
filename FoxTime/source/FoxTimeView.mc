import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

class FoxTimeView extends WatchUi.DataField {

    hidden var hourStr as String = "--";
    hidden var minStr as String = "--";
    hidden var amPmStr as String = "";
    hidden var gpsQuality as Number = 0;
    hidden var batteryPct as Float = 0.0f;

    hidden var fontPrimary;
    hidden var fontPrimarySm;
    hidden var fontPrimaryXs;
    hidden var fontLabel;
    hidden var iconBattery;

    hidden var colonWLg;
    hidden var colonBLg;
    hidden var colonWSm;
    hidden var colonBSm;

    hidden var gpsWIcons as Array;
    hidden var gpsBIcons as Array;

    hidden var fieldWidth as Numeric = 140;
    hidden var fieldHeight as Numeric = 92;
    hidden var primaryFont;
    hidden var centerY as Number = 60;
    hidden var colonGap as Number = 6;
    hidden var colonW;
    hidden var colonB;
    hidden var colonHalf as Number = 20;
    hidden var colonShiftX as Number = 0;
    hidden var colonShiftY as Number = 2;

    function initialize() {
        DataField.initialize();

        fontPrimary = loadResource(Rez.Fonts.fontPrimary);
        fontPrimarySm = loadResource(Rez.Fonts.fontPrimarySm);
        fontPrimaryXs = loadResource(Rez.Fonts.fontPrimaryXs);
        fontLabel = loadResource(Rez.Fonts.fontLabel);
        iconBattery = loadResource(Rez.Drawables.iconBattery);

        colonWLg = loadResource(Rez.Drawables.iconColonWLg);
        colonBLg = loadResource(Rez.Drawables.iconColonBLg);
        colonWSm = loadResource(Rez.Drawables.iconColonWSm);
        colonBSm = loadResource(Rez.Drawables.iconColonBSm);

        var gpsWNone = loadResource(Rez.Drawables.gpsWNone);
        var gpsWPoor = loadResource(Rez.Drawables.gpsWPoor);
        var gpsWUsable = loadResource(Rez.Drawables.gpsWUsable);
        var gpsWGood = loadResource(Rez.Drawables.gpsWGood);
        gpsWIcons = [gpsWNone, gpsWNone, gpsWPoor, gpsWUsable, gpsWGood];

        var gpsBNone = loadResource(Rez.Drawables.gpsBNone);
        var gpsBPoor = loadResource(Rez.Drawables.gpsBPoor);
        var gpsBUsable = loadResource(Rez.Drawables.gpsBUsable);
        var gpsBGood = loadResource(Rez.Drawables.gpsBGood);
        gpsBIcons = [gpsBNone, gpsBNone, gpsBPoor, gpsBUsable, gpsBGood];

        primaryFont = fontPrimarySm;
        colonW = colonWSm;
        colonB = colonBSm;
    }

    function onLayout(dc as Dc) as Void {
        fieldWidth = dc.getWidth();
        fieldHeight = dc.getHeight();

        if (fieldHeight > 120) {
            primaryFont = fontPrimary;
            colonW = colonWLg;
            colonB = colonBLg;
            colonHalf = 22;
            colonShiftX = 0;
            colonShiftY = 3;
        } else if (fieldHeight > 80) {
            primaryFont = fontPrimarySm;
            colonW = colonWSm;
            colonB = colonBSm;
            colonHalf = 12;
            colonShiftX = 0;
            colonShiftY = 4;
        } else {
            primaryFont = fontPrimaryXs;
            colonW = colonWSm;
            colonB = colonBSm;
            colonHalf = 12;
            colonShiftX = 0;
            colonShiftY = 3;
        }
        centerY = 18 + (fieldHeight - 18) / 2;

        var fontH = dc.getFontHeight(primaryFont);
        colonGap = (fontH * 0.12f).toNumber();
    }

    function compute(info as Activity.Info) as Void {
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var settings = System.getDeviceSettings();
        if (!settings.is24Hour) {
            amPmStr = hours >= 12 ? "PM" : "AM";
            hours = hours % 12;
            if (hours == 0) { hours = 12; }
        } else {
            amPmStr = "";
        }
        hourStr = hours.format("%d");
        minStr = clockTime.min.format("%02d");

        if (info has :currentLocationAccuracy && info.currentLocationAccuracy != null) {
            gpsQuality = info.currentLocationAccuracy as Number;
        } else {
            gpsQuality = 0;
        }

        var bat = System.getSystemStats().battery;
        batteryPct = bat > 99.0f ? 99.0f : bat;
    }

    function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = bgColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fgColor, bgColor);
        dc.clear();

        drawTopBar(dc, fgColor);
        drawTime(dc, fgColor);
    }

    hidden function drawTopBar(dc as Dc, fgColor as Number) as Void {
        dc.setColor(fgColor, -1);
        var gpsLabelW = dc.getTextWidthInPixels("GPS", Graphics.FONT_XTINY);
        dc.drawText(2, 3, Graphics.FONT_XTINY, "GPS", Graphics.TEXT_JUSTIFY_LEFT);
        var gpsIcons = fgColor == Graphics.COLOR_WHITE ? gpsWIcons : gpsBIcons;
        var idx = gpsQuality;
        if (idx < 0) { idx = 0; }
        if (idx > 4) { idx = 4; }
        dc.drawBitmap(2 + gpsLabelW + 1, -2, gpsIcons[idx]);

        var batStr = batteryPct.format("%d") + "%";
        var batStrW = dc.getTextWidthInPixels(batStr, fontLabel);
        dc.drawText(fieldWidth - 2, -8, fontLabel, batStr, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawBitmap(fieldWidth - 2 - batStrW - 22, 0, iconBattery);
    }

    hidden function drawTime(dc as Dc, fgColor as Number) as Void {
        dc.setColor(fgColor, -1);
        var cx = fieldWidth / 2;
        var cy = centerY;
        var colonIcon = fgColor == Graphics.COLOR_WHITE ? colonW : colonB;

        dc.drawText(cx - colonGap, cy, primaryFont, hourStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawBitmap(cx - colonHalf + colonShiftX, cy - colonHalf + colonShiftY, colonIcon);
        dc.drawText(cx + colonGap, cy, primaryFont, minStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (amPmStr.length() > 0) {
            dc.drawText(4, fieldHeight - dc.getFontHeight(Graphics.FONT_XTINY), Graphics.FONT_XTINY, amPmStr, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}
