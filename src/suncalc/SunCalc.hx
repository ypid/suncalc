package suncalc;

#if !js
import datetime.DateTime;
#end

/*
 * Only inline code/values when they are only used once to allow caching
 * optimization to happen for the different targets.
 */

/**
    The SunCalc module allows to calculate sun position,
    sunlight phases (times for sunrise, sunset, dusk, etc.),
    moon position and lunar phase for the given location and time.

    The library was ported to Haxe by [Robin `ypid` Schneider](https://github.com/ypid) to allow using it in a library for [opening hours](https://github.com/opening-hours/opening_hours.js/issues/136).

    It is based on the [JavaScript implementation](https://github.com/mourner/suncalc)
    created by [Vladimir Agafonkin](http://agafonkin.com/en) ([@mourner](https://github.com/mourner))
    as a part of the [SunCalc.net project](http://suncalc.net).

    Most calculations are based on the formulas given in the excellent Astronomy Answers articles
    about [position of the sun](http://aa.quae.nl/en/reken/zonpositie.html)
    and [the planets](http://aa.quae.nl/en/reken/hemelpositie.html).
    You can read about different twilight phases calculated by SunCalc
    in the [Twilight article on Wikipedia](https://en.wikipedia.org/wiki/Twilight).
**/

@:expose
class SunCalc {

    /**
        Version of the suncalc library.
    **/
    public static var version(default, never):String = Version.getVersion();

    /**
        git commit hash from which this library was build.
    **/
    public static var version_hash(default, never):String = Version.getGitCommitHash();

    /**
        Version of Haxe used to build this library.
    **/
    public static var version_haxe_compiler(default, never):String = Version.getHaxeCompilerVersion();

    /* Date/time constants and conversions. {{{ */
    private static var dayMs:Int = 1000 * 60 * 60 * 24;  /* Used: toJulian, fromJulian, hoursLater */
    private static var J1970:Int = 2440588; /* Used: toJulian, fromJulian */
    private static var J2000:Int = 2451545; /* Used: toDays, solarTransitJ */
    /* }}} */

    /* General calculations for position. {{{ */
    private static var rad:Float = Math.PI / 180;
    private static var   e:Float = Math.PI / 180 * 23.4397; /* Obliquity of the Earth. */
    /* }}} */

    /* Helper functions. {{{ */

    /* Used: 1*toDays */
    private static inline function toJulian(date: Date):Float {
        return date.getTime() / dayMs - 0.5 + J1970;
    }

    /* Used: 4*getTimes */
    private static function fromJulian(j: Float):Date {
        return Date.fromTime((j + 0.5 - J1970) * dayMs);
    }

    /* Used: getPosition, getTimes, getMoonPosition, getMoonIllumination */
    private static function toDays(date: Date):Float {
        return toJulian(date) - J2000;
    }

    /* Used: sunCoords, moonCoords */
    private static function rightAscension(l, b):Float {
        return Math.atan2(
            Math.sin(l) * Math.cos(e) - Math.tan(b) * Math.sin(e),
            Math.cos(l));
    }

    /* Used: sunCoords, moonCoords, getTimes */
    private static function declination(l, b):Float {
        return Math.asin(Math.sin(b) * Math.cos(e) + Math.cos(b) * Math.sin(e) * Math.sin(l));
    }

    /* Used: getPosition, getMoonPosition */
    private static function azimuth(H, phi, dec):Float {
         return Math.atan2(Math.sin(H), Math.cos(H) * Math.sin(phi) - Math.tan(dec) * Math.cos(phi));
    }

    /* Used: getPosition, getMoonPosition */
    private static function altitude(H, phi, dec):Float {
          return Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(H));
    }

    /* Used: getPosition, getMoonPosition */
    private static function siderealTime(d:Float, lw:Float):Float {
        return rad * (280.16 + 360.9856235 * d) - lw;
    }

    /* }}} */

    /* General sun calculations. {{{ */

    /* Used: sunCoords, getTimes */
    private static function solarMeanAnomaly(d:Float):Float {
        return rad * (357.5291 + 0.98560028 * d);
    }

    /* Used: sunCoords, getTimes */
    private static function eclipticLongitude(M):Float {
        var C = rad * (1.9148 * Math.sin(M) + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M)), // equation of center
            P = rad * 102.9372; // perihelion of the Earth

        return M + C + P + Math.PI;
    }

    /* Used: getPosition, getMoonPosition */
    private static function sunCoords(d) {
        var M = solarMeanAnomaly(d),
            L = eclipticLongitude(M);

        return {
            dec: declination(L, 0),
            ra: rightAscension(L, 0)
        };
    }

    /* public: getPosition {{{ */
    /**
        Returns an object with the following properties:

        * `altitude`: Sun altitude above the horizon in radians,
          e.g. `0` at the horizon and `PI/2` at the zenith (straight over your head).

        * `azimuth`: Sun azimuth in radians (direction along the horizon, measured from south to west),
          e.g. `0` is south and `PI * 3/4` is northwest.

    **/
    public static function getPosition(date:Date, lat:Float, lng:Float) {
        var lw  = rad * -lng,
            phi = rad * lat,
            d   = toDays(date),

            c  = sunCoords(d),
            H  = siderealTime(d, lw) - c.ra;

        return {
            azimuth: azimuth(H, phi, c.dec),
            altitude: altitude(H, phi, c.dec)
        };
    };

    /**
        Contains all currently defined times.
    **/
    public static var times: Array<Array<Dynamic>> = [
        [-0.833, 'sunrise',       'sunset'      ],
        [  -0.3, 'sunriseEnd',    'sunsetStart' ],
        [    -6, 'dawn',          'dusk'        ],
        [   -12, 'nauticalDawn',  'nauticalDusk'],
        [   -18, 'nightEnd',      'night'       ],
        [     6, 'goldenHourEnd', 'goldenHour'  ],
    ];
    /* }}} */

    /**
        Adds a custom time to the `times` configuration.
    **/
    public static function addTime(angle:Float, riseName:String, setName:String) {
        times.push([angle, riseName, setName]);
    };

    // calculations for sun times
    private static var J0 = 0.0009;

    /* Used: 1*getTimes */
    private static inline function julianCycle(d:Float, lw:Float) {
        return Math.round(d - J0 - lw / (2 * Math.PI));
    }
    /* Used: 1*getSetJ, 1*getTimes */
    private static function approxTransit(Ht:Float, lw, n) {
        return J0 + (Ht + lw) / (2 * Math.PI) + n;
    }
    /* Used: 1*getSetJ, 1*getTimes */
    private static function solarTransitJ(ds:Float, M:Float, L:Float) {
        return J2000 + ds + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
    }

    /* Used: 1*getSetJ */
    private static inline function hourAngle(h, phi, d) {
        return Math.acos((Math.sin(h) - Math.sin(phi) * Math.sin(d)) / (Math.cos(phi) * Math.cos(d)));
    }

    /* Returns set time for the given sun altitude.
     * Used: 1*getTimes
     * Can not be inlined as of Haxe 3.2.1.
     */
    private static function getSetJ(h, lw, phi, dec, n, M, L) {
        var w = hourAngle(h, phi, dec),
            a = approxTransit(w, lw, n);
        return solarTransitJ(a, M, L);
    }

    /* Calculates sun times for a given date and latitude/longitude. {{{ */
    /**

        Returns an object with the following properties (each is a `Date` object):

        <table><thead>
        <tr>
        <th>Property</th>
        <th>Description</th>
        </tr>
        </thead><tbody>
        <tr>
        <td><code>sunrise</code></td>
        <td>sunrise (top edge of the sun appears on the horizon)</td>
        </tr>
        <tr>
        <td><code>sunriseEnd</code></td>
        <td>sunrise ends (bottom edge of the sun touches the horizon)</td>
        </tr>
        <tr>
        <td><code>goldenHourEnd</code></td>
        <td>morning golden hour (soft light, best time for photography) ends</td>
        </tr>
        <tr>
        <td><code>solarNoon</code></td>
        <td>solar noon (sun is in the highest position)</td>
        </tr>
        <tr>
        <td><code>goldenHour</code></td>
        <td>evening golden hour starts</td>
        </tr>
        <tr>
        <td><code>sunsetStart</code></td>
        <td>sunset starts (bottom edge of the sun touches the horizon)</td>
        </tr>
        <tr>
        <td><code>sunset</code></td>
        <td>sunset (sun disappears below the horizon, evening civil twilight starts)</td>
        </tr>
        <tr>
        <td><code>dusk</code></td>
        <td>dusk (evening nautical twilight starts)</td>
        </tr>
        <tr>
        <td><code>nauticalDusk</code></td>
        <td>nautical dusk (evening astronomical twilight starts)</td>
        </tr>
        <tr>
        <td><code>night</code></td>
        <td>night starts (dark enough for astronomical observations)</td>
        </tr>
        <tr>
        <td><code>nadir</code></td>
        <td>nadir (darkest moment of the night, sun is in the lowest position)</td>
        </tr>
        <tr>
        <td><code>nightEnd</code></td>
        <td>night ends (morning astronomical twilight starts)</td>
        </tr>
        <tr>
        <td><code>nauticalDawn</code></td>
        <td>nautical dawn (morning nautical twilight starts)</td>
        </tr>
        <tr>
        <td><code>dawn</code></td>
        <td>dawn (morning nautical twilight ends, morning civil twilight starts)</td>
        </tr>
        </tbody></table>

    **/
    public static function getTimes(date:Date, lat:Float, lng:Float):Map<String, Date> {
        var lw = rad * -lng,
            phi = rad * lat,

            d = toDays(date),
            n = julianCycle(d, lw),
            ds:Float = approxTransit(0, lw, n),

            M = solarMeanAnomaly(ds),
            L = eclipticLongitude(M),
            dec = declination(L, 0),

            Jnoon = solarTransitJ(ds, M, L),

            i, len, time, Jset, Jrise;

        var result = new Map<String, Date>();
        result['solarNoon'] = fromJulian(Jnoon);
        result['nadir'] = fromJulian(Jnoon - 0.5);

        for (time in times) {

            Jset = getSetJ(time[0] * rad, lw, phi, dec, n, M, L);
            Jrise = Jnoon - (Jset - Jnoon);

            result[time[1]] = fromJulian(Jrise);
            result[time[2]] = fromJulian(Jset);
        }

#if (normal_build && js)
        return untyped result.h;
#else
        return result;
#end
    }; /* }}} */

    /* }}} */

    /* Moon position calculations. {{{
     * Based on http://aa.quae.nl/en/reken/hemelpositie.html formulas.
     */

    /**
        Geocentric ecliptic coordinates of the moon.
    **/
    private static function moonCoords(d:Float) {

        var L = rad * (218.316 + 13.176396 * d), /* Ecliptic longitude. */
            M = rad * (134.963 + 13.064993 * d), /* Mean anomaly. */
            F = rad * (93.272 + 13.229350 * d),  /* Mean distance. */

            longitude = L + rad * 6.289 * Math.sin(M),
            latitude  = rad * 5.128 * Math.sin(F),
            dt = 385001 - 20905 * Math.cos(M); /* Distance to the moon in km. */

        return {
            ra: rightAscension(longitude, latitude),
            dec: declination(longitude, latitude),
            dist: dt
        };
    }

    /**
        Returns an object with the following properties:

        - `altitude`: Moon altitude above the horizon in radians.

        - `azimuth`: Moon azimuth in radians.

        - `distance`: Distance to moon in kilometers.
    **/
    public static function getMoonPosition (date:Date, lat:Float, lng:Float) {
        var lw      = rad * -lng,
            phi     = rad *  lat,
            d:Float = toDays(date),

            c = moonCoords(d),
            H = siderealTime(d, lw) - c.ra,
            h:Float = altitude(H, phi, c.dec);

        // altitude correction for refraction
        h = h + rad * 0.017 / Math.tan(h + rad * 10.26 / (h + rad * 5.10));

        return {
            azimuth: azimuth(H, phi, c.dec),
            altitude: h,
            distance: c.dist
        };
    };

    /* Calculations for illumination parameters of the moon. {{{
     * Based on http://idlastro.gsfc.nasa.gov/ftp/pro/astro/mphase.pro formulas and
     * Chapter 48 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
     */
    /**

        Returns an object with the following properties:

         - `fraction`: Illuminated fraction of the moon; varies from `0.0` (new moon) to `1.0` (full moon).

         - `phase`: Moon phase; varies from `0.0` to `1.0`, described below.

         - `angle`: Midpoint angle in radians of the illuminated limb of the moon reckoned eastward from the north point of the disk;
           the moon is waxing if the angle is negative, and waning if positive.

        Moon phase value should be interpreted like this:

        <table><thead>
        <tr>
        <th align="left">Phase</th>
        <th>Name</th>
        </tr>
        </thead><tbody>
        <tr>
        <td align="right">0</td>
        <td>New Moon, Waxing Crescent</td>
        </tr>
        <tr>
        <td align="right">0.25</td>
        <td>First Quarter, Waxing Gibbous</td>
        </tr>
        <tr>
        <td align="right">0.5</td>
        <td>Full Moon, Waning Gibbous</td>
        </tr>
        <tr>
        <td align="right">0.75</td>
        <td>Last Quarter, Waning Crescent</td>
        </tr>
        </tbody></table>

    **/
    public static function getMoonIllumination(date:Date) {
        var d:Float = toDays(date),
            s = sunCoords(d),
            m = moonCoords(d),

            astronomical_unit:Int = 149598000,
            /* Roughly the distance from the Earth to the Sun in km. */

            phi = Math.acos(Math.sin(s.dec) * Math.sin(m.dec) + Math.cos(s.dec) * Math.cos(m.dec) * Math.cos(s.ra - m.ra)),
            inc = Math.atan2(astronomical_unit * Math.sin(phi), m.dist - astronomical_unit * Math.cos(phi)),
            angle = Math.atan2(Math.cos(s.dec) * Math.sin(s.ra - m.ra), Math.sin(s.dec) * Math.cos(m.dec) -
                    Math.cos(s.dec) * Math.sin(m.dec) * Math.cos(s.ra - m.ra));

        return {
            fraction: (1 + Math.cos(inc)) / 2,
            phase: 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Math.PI,
            angle: angle
        };
    }; /* }}} */

    /* Calculations for moon rise/set times. {{{
     * Based on http://www.stargazing.net/kepler/moonrise.html article.
     */

    private static function hoursLater(date:Date, h:Dynamic) {
        return Date.fromTime(date.getTime() + h * dayMs / 24);
    }

    /**
        Returns an object with the following properties:

         - `rise`: Moon rise time as `Date`.

         - `set`: Moon set time as `Date`.

         - `alwaysUp`: `true` if the moon never rises/sets and is always _above_ the horizon during the day.

         - `alwaysDown`: `true` if the moon is always _below_ the horizon.

        By default, it will search for moon rise and set during local user's day (from 0 to 24 hours).
        If `inUTC` is set to true, it will instead search the specified date from 0 to 24 UTC hours.
    **/
    public static function getMoonTimes(date:Date, lat:Float, lng:Float, inUTC:Bool = false) {
        if (inUTC) {
#if js
            untyped date.setUTCHours(0, 0, 0, 0);
#else
            date = DateTime.fromDate(date).utc();
            date = new Date( date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0 );
#end
        } else {
#if js
            untyped date.setHours(0, 0, 0, 0);
#else
            date = new Date( date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0 );
#end
        }

        var hc:Float = 0.133 * rad,
            h0:Float = getMoonPosition(date, lat, lng).altitude - hc,
            h1:Float, h2:Float,
            rise:Float = 0.0,
            set:Float  = 0.0,
            a:Float, b:Float, xe:Float,
            ye:Float = 0.0,
            d:Float,
            roots:Int,
            x1:Float = 0.0,
            x2:Float = 0.0,
            dx:Float;

        /* Go in 2-hour chunks, each time seeing if a 3-point quadratic curve
         * crosses zero (which means rise or set) */
        var i = 1;
        while (i <= 24) {
            h1 = getMoonPosition(hoursLater(date, i), lat, lng).altitude - hc;
            h2 = getMoonPosition(hoursLater(date, i + 1), lat, lng).altitude - hc;

            a = (h0 + h2) / 2 - h1;
            b = (h2 - h0) / 2;
            xe = -b / (2 * a);
            ye = (a * xe + b) * xe + h1;
            d = b * b - 4 * a * h1;

            roots = 0;

            if (d >= 0) {
                dx = Math.sqrt(d) / (Math.abs(a) * 2);
                x1 = xe - dx;
                x2 = xe + dx;
                if (Math.abs(x1) <= 1) roots++;
                if (Math.abs(x2) <= 1) roots++;
                if (x1 < -1) x1 = x2;
            }

            if (roots == 1) {
                if (h0 < 0) rise = i + x1;
                else set = i + x1;
            } else if (roots == 2) {
                rise = i + (ye < 0 ? x2 : x1);
                set = i + (ye < 0 ? x1 : x2);
            }

            if (rise != 0 && set != 0) {
                break;
            }

            h0 = h2;

            i += 2;
        }

        var result = new Map<String, Dynamic>();

        if (rise != 0) result['rise'] = hoursLater(date, rise);
        if (set != 0)  result['set'] = hoursLater(date, set);

        if (rise == 0 && set == 0) result[ye > 0 ? 'alwaysUp' : 'alwaysDown'] = true;

#if (normal_build && js)
        return untyped result.h;
#else
        return result;
#end
    }; /* }}} */

    /* }}} */

    static function main() {
    }
}
