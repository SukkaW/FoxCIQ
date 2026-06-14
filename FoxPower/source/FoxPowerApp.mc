import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FoxPowerApp extends Application.AppBase {

    var dataField;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        dataField = new FoxPowerView();
        return [ dataField ];
    }

    function onSettingsChanged() {
        dataField.loadSettings();
    }
}

function getApp() as FoxPowerApp {
    return Application.getApp() as FoxPowerApp;
}
