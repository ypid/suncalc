
// Export as AMD module / Node module / browser variable.
if (typeof define === 'function' && define.amd) define(suncalc.SunCalc);
else if (typeof module !== 'undefined') module.exports = suncalc.SunCalc;
else window.SunCalc = suncalc.SunCalc;

}());
