import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FoxSpeedApp extends Application.AppBase {
    var dataField;
    function initialize() { AppBase.initialize(); }
    function onStart(state) {}
    function onStop(state) {}
    function getInitialView() {
        dataField = new FoxSpeedView();
        return [ dataField ];
    }
}

function getApp() as FoxSpeedApp {
    return Application.getApp() as FoxSpeedApp;
}
