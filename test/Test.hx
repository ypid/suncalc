import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import datetime.DateTime;

import suncalc.SunCalc;

class Test extends TestCase {

    var date:Date = DateTime.fromString('2013-03-05T00:00:00Z');
    var lat = 50.5;
    var lng = 30.5;

    var testTimes:Map<String, String> = [
        'solarNoon' => '2013-03-05T10:10:57Z',
        'nadir' => '2013-03-04T22:10:57Z',
        'sunrise' => '2013-03-05T04:34:56Z',
        'sunset' => '2013-03-05T15:46:57Z',
        'sunriseEnd' => '2013-03-05T04:38:19Z',
        'sunsetStart' => '2013-03-05T15:43:34Z',
        'dawn' => '2013-03-05T04:02:17Z',
        'dusk' => '2013-03-05T16:19:36Z',
        'nauticalDawn' => '2013-03-05T03:24:31Z',
        'nauticalDusk' => '2013-03-05T16:57:22Z',
        'nightEnd' => '2013-03-05T02:46:17Z',
        'night' => '2013-03-05T17:35:36Z',
        'goldenHourEnd' => '2013-03-05T05:19:01Z',
        'goldenHour' => '2013-03-05T15:02:52Z',
    ];

    private function near(val1:Float, val2:Float, margin:Float = 1E-15):Bool {
        return Math.abs(val1 - val2) < margin;
    }

    private function testGetPosition():Void {
        var sunPos = SunCalc.getPosition(date, lat, lng);

        assertTrue(near(sunPos.azimuth, -2.5003175907168385));
        assertTrue(near(sunPos.altitude, -0.7000406838781611));
    }

    private function testGetTimes():Void {
        var times = SunCalc.getTimes(date, lat, lng);

        for (testTime in testTimes.keys()) {
            var test_date:Date = DateTime.fromString(testTimes[testTime]);
            assertEquals(DateTime.fromDate(test_date).utc().toString(), DateTime.fromDate(times[testTime]).utc().toString());
        }
    }

    private function testGetMoonPosition():Void {
        var moonPos = SunCalc.getMoonPosition(date, lat, lng);

        assertTrue(near(moonPos.azimuth, -0.9783999522438226));
        assertTrue(near(moonPos.altitude, 0.006969727754891917));
        assertTrue(near(moonPos.distance, 364121.37256256194));
    }

    private function testGetMoonIllumination():Void {
        var moonIllum = SunCalc.getMoonIllumination(date);

        assertTrue(near(moonIllum.fraction, 0.4848068202456373));
        assertTrue(near(moonIllum.phase, 0.7548368838538762));
        assertTrue(near(moonIllum.angle, 1.6732942678578346));
    }

/*
 * See README.md under limitations for details.
 */
#if !(cpp || java || python || neko)
    private function testGetMoonTimes():Void {
        var moon_date:Date = DateTime.fromString('2013-03-04');
        var moonTimes = SunCalc.getMoonTimes(moon_date, lat, lng, true);

        assertTrue(Std.is(moonTimes.get('rise'), Date));
        assertTrue(Std.is(moonTimes.get('set'), Date));
        assertEquals(DateTime.fromString('2013-03-04T23:57:55Z').utc().toString(), DateTime.fromDate(moonTimes.get('rise')).utc().toString());
        assertEquals(DateTime.fromString('2013-03-04T07:28:41Z').utc().toString(), DateTime.fromDate(moonTimes.get('set')).utc().toString());
    }
#end

    static public function main():Void {

        var runner = new TestRunner();
        runner.add(new Test());
        var all_tests_passed:Bool = runner.run();
        Sys.exit(all_tests_passed ? 0 : 1);
    }
}
