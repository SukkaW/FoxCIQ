import Toybox.Lang;
import Toybox.Math;

module FoxPowerMath {

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

    function updateNormalizedPower(prevNP as Numeric, counter as Numeric, avg30s as Numeric) as Numeric {
        if (counter == 0) {
            return avg30s;
        }
        var prevFrac = (counter - 1.0) / counter;
        var currFrac = 1.0 / counter;
        var result = Math.pow(prevNP, 4) * prevFrac + Math.pow(avg30s, 4) * currFrac;
        return Math.pow(result, 0.25);
    }
}
