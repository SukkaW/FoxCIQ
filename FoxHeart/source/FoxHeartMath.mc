import Toybox.Lang;

module FoxHeartMath {

    function pushWindow(values as Array<Numeric>, nextValue as Numeric) as Array<Numeric> {
        values.add(nextValue);
        return values.slice(1, null);
    }

    function mean(values as Array<Numeric>) as Float {
        var size = values.size();
        if (size == 0) { return 0.0f; }
        var sum = 0.0f;
        for (var i = 0; i < size; i++) {
            if (values[i] != null) {
                sum += values[i];
            }
        }
        return sum / size;
    }
}
