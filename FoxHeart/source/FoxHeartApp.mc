import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FoxHeartApp extends Application.AppBase {

    var dataField;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        dataField = new FoxHeartView();
        return [ dataField ];
    }

    function onSettingsChanged() {
        dataField.loadSettings();
    }
}

function getApp() as FoxHeartApp {
    return Application.getApp() as FoxHeartApp;
}
