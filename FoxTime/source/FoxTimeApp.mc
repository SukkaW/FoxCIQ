import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FoxTimeApp extends Application.AppBase {

    var dataField;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        dataField = new FoxTimeView();
        return [ dataField ];
    }
}

function getApp() as FoxTimeApp {
    return Application.getApp() as FoxTimeApp;
}
