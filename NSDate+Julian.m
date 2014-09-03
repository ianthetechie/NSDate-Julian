//
//  NSDate+Julian.m
//
//  Formula sources: http://en.wikipedia.org/wiki/Julian_day
//                   http://users.electromagnetic.net/bu/astro/sunrise-set.php
//
//  Copyright (c) 2014, Ian Wagner
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its
//     contributors may be used to endorse or promote products derived from
//     this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "NSDate+Julian.h"
#import <fenv.h>

// Numeric sign function
int sgn(int n) {
    if (n > 0) {
        return 1;
    } else if (n < 0) {
        return -1;
    } else {
        return 0;
    }
}

@implementation NSDate (Julian)

//
// Julian date conversion and sunrise/sunset calculation methods
//

- (JulianDayNumber)julianDayNumber {
    CFAbsoluteTime at = CFDateGetAbsoluteTime((CFDateRef)self);
    CFGregorianDate date = CFAbsoluteTimeGetGregorianDate(at, NULL);
    
    // Convert the Gregorian date to Julian date number
    NSInteger a = floor((14 - date.month) / 12);
    NSInteger y = date.year + 4800 - a;
    NSInteger m = date.month + 12 * a - 3;
    NSInteger jdn = date.day + floor((153 * m + 2) / 5) + (365 * y) + floor(y / 4) - floor(y / 100) + floor(y / 400) - 32045;
    
    return jdn;
}

- (JulianDate)julianDate {
    CFAbsoluteTime at = CFDateGetAbsoluteTime((CFDateRef)self);
    CFGregorianDate date = CFAbsoluteTimeGetGregorianDate(at, NULL);
    
    JulianDayNumber jdn = [self julianDayNumber];
    return jdn + ((date.hour - 12) / 24.0) + (date.minute / 1440.0) + (date.second / 86400.0);
}

- (JulianDaylightInfo)julianDaylightInfoForLocation:(CLLocationCoordinate2D)location {
    JulianDayNumber jdn = [self julianDayNumber];
    NSInteger n = [NSDate julianCycleOnDate:jdn
                                atLongitude:-location.longitude];
    CLLocationDegrees jPrime = [NSDate solarNoonAtLongitude:-location.longitude
                                                   forCycle:n];
    CLLocationDegrees M = [NSDate solarMeanAnomalyForJulianNoon:jPrime];
    CLLocationDegrees L = [NSDate eclipticLongitudeForSolarMean:M];
    CLLocationDegrees jTransit = [NSDate solarTransitAngleForJulianNoon:jPrime
                                                                andMean:M];
    
    BOOL done = NO;
    do {
        CLLocationDegrees newM = [NSDate solarMeanAnomalyForJulianNoon:jTransit];
        L = [NSDate eclipticLongitudeForSolarMean:newM];
        
        done = fabs(newM - M) < DBL_EPSILON;
        M = newM;
    } while (!done);
    
    // Clear any floating point exception, if one exists
    if (math_errhandling & MATH_ERREXCEPT) {
        feclearexcept(FE_ALL_EXCEPT);
    }
    
    CLLocationDegrees declination = [NSDate solarDeclinationForEclipticLongitude:L];
    CLLocationDegrees hourAngle = [NSDate hourAngleForDeclination:declination
                                                       atLatitude:location.latitude];
    
    // Check for floaing point errors
    if (math_errhandling & MATH_ERRNO) {
        if (errno == EDOM) {
            NSLog(@"Floating point domain error");
            hourAngle = NAN;
        }
    }
    if (math_errhandling & MATH_ERREXCEPT) {
        if (fetestexcept(FE_INVALID)) {
            NSLog(@"FE_INVALID raised");
            feclearexcept(FE_ALL_EXCEPT);  // Cleanup
            hourAngle = NAN;
        }
    }
    
    JulianDaylightInfo info;
    
    // Check for midnight sun/polar night condition
    if (isnan(hourAngle)) {
        if (declination > 0) {
            // Midnight sun (sun always up)
            info.sunrise = jdn - 1;
            info.sunset = NAN;
        } else {
            // Polar night (it's dark)
            info.sunrise = NAN;
            info.sunset = jdn - 1;
        }
        
        return info;
    }
    
    info.sunset = 2451545.0009 + ((hourAngle + -location.longitude) / 360.0) + n + 0.0053 * sin(DEG_TO_RAD(M)) - 0.0069 * sin(DEG_TO_RAD(2 * L));
    info.sunrise = jTransit - (info.sunset - jTransit);
    
    return info;
}

//
// Class-level helper methods
// NOTE: All inputs and return values are in degrees
//

+ (NSInteger)julianCycleOnDate:(NSUInteger)jdn atLongitude:(CLLocationDegrees)longitude {
    CLLocationDegrees nPrime = jdn - 2451545.0009 - (longitude / 360.0);
    return floor(nPrime + 0.5);
}

+ (CLLocationDegrees)solarNoonAtLongitude:(CLLocationDegrees)longitude forCycle:(NSInteger)n {
    return 2451545.0009 + (longitude / 360.0) + n;
}

+ (CLLocationDegrees)solarMeanAnomalyForJulianNoon:(CLLocationDegrees)jPrime {
    return fmod(357.5291 + 0.98560028 * (jPrime - 2451545), 360);
}

+ (CLLocationDegrees)equationOfCenterForSolarMean:(CLLocationDegrees)M {
    return 1.9148 * sin(DEG_TO_RAD(M)) + 0.02 * sin(DEG_TO_RAD(2 * M)) + 0.0003 * sin(DEG_TO_RAD(3 * M));
}

+ (CLLocationDegrees)eclipticLongitudeForSolarMean:(CLLocationDegrees)M {
    CLLocationDegrees C = [NSDate equationOfCenterForSolarMean:M];
    return fmod(M + 102.9372 + C + 180, 360);
}

+ (CLLocationDegrees)solarTransitAngleForJulianNoon:(CLLocationDegrees)jPrime andMean:(CLLocationDegrees)M {
    CLLocationDegrees L = [NSDate eclipticLongitudeForSolarMean:M];
    return jPrime + 0.0053 * sin(DEG_TO_RAD(M)) - 0.0069 * sin(DEG_TO_RAD(2 * L));
}

+ (CLLocationDegrees)solarDeclinationForEclipticLongitude:(CLLocationDegrees)L {
    return RAD_TO_DEG(asin(sin(DEG_TO_RAD(L)) * sin(DEG_TO_RAD(23.45))));
}

+ (CLLocationDegrees)hourAngleForDeclination:(CLLocationDegrees)d atLatitude:(CLLocationDegrees)latitude {
    return RAD_TO_DEG(acos((sin(DEG_TO_RAD(-0.83)) - sin(DEG_TO_RAD(latitude)) * sin(DEG_TO_RAD(d))) / (cos(DEG_TO_RAD(latitude)) * cos(DEG_TO_RAD(d)))));
}

@end
