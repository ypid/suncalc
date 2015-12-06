[![Build Status](https://travis-ci.org/ypid/suncalc.svg?branch=master)](https://travis-ci.org/ypid/suncalc)


## Limitations

The following limitations seems to be related which should mean that when they are fixed for one target, the tests for the other targets should also pass. If you need `SunCalc.getMoonTimes` for one of those targets, feel free to debug it further.

* Python: `SunCalc.getMoonTimes` (`rise` date can not be calculated.).
* C++: `SunCalc.getMoonTimes` (`segmentation fault`).
* Java: `SunCalc.getMoonTimes` (`java.lang.NullPointerException`).
* Neko: `SunCalc.getMoonTimes`

## Unsure/untested

* ActionScript 3: Does compile but I have no idea how to test it.
* Flash: Does compile but I have no idea how to test it.

## Unsupported

* C#: Dependency `datetime` does not compile on target "datetime/3,0,2/src/datetime/DateTime.hx:146: characters 28-110 : haxe.Int64 should be Float"

  Priority low.
