import Toybox.Lang;

module FoxHeartMath {
    class RollingAvg {
        hidden var _buf as Array<Numeric>;
        hidden var _size as Number;
        hidden var _idx as Number = 0;
        hidden var _count as Number = 0;
        hidden var _sum as Float = 0.0f;

        function initialize(size as Number) {
            _size = size;
            _buf = new Array<Numeric>[size];
            for (var i = 0; i < size; i++) { _buf[i] = 0; }
        }

        function update(value as Numeric) as Float {
            var old = _buf[_idx];
            _buf[_idx] = value;
            _idx = (_idx + 1) % _size;
            if (_count < _size) {
                _count++;
                _sum += value.toFloat();
            } else {
                _sum += value.toFloat() - old.toFloat();
            }
            return _sum / _count;
        }

        function avg() as Float {
            return _count > 0 ? _sum / _count : 0.0f;
        }

        function isFull() as Boolean {
            return _count >= _size;
        }

        function reset() as Void {
            _idx = 0;
            _count = 0;
            _sum = 0.0f;
            for (var i = 0; i < _size; i++) { _buf[i] = 0; }
        }
    }
}
