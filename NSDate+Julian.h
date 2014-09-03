//
//  NSDate+Julian.h
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define DEG_TO_RAD(X) (X * M_PI / 180.0)
#define RAD_TO_DEG(X) (X * 180.0 / M_PI)

typedef struct {
    double sunrise;
    double sunset;
} JulianDaylightInfo;

typedef NSInteger JulianDayNumber;
typedef double JulianDate;

@interface NSDate (Julian)

- (JulianDayNumber)julianDayNumber;
- (JulianDate)julianDate;
- (JulianDaylightInfo)julianDaylightInfoForLocation:(CLLocationCoordinate2D)location;
+ (NSInteger)julianCycleOnDate:(NSUInteger)jdn atLongitude:(CLLocationDegrees)longitude;
+ (CLLocationDegrees)solarNoonAtLongitude:(CLLocationDegrees)longitude forCycle:(NSInteger)n;
+ (CLLocationDegrees)solarMeanAnomalyForJulianNoon:(CLLocationDegrees)jPrime;
+ (CLLocationDegrees)equationOfCenterForSolarMean:(CLLocationDegrees)M;
+ (CLLocationDegrees)eclipticLongitudeForSolarMean:(CLLocationDegrees)M;
+ (CLLocationDegrees)solarTransitAngleForJulianNoon:(CLLocationDegrees)jPrime andMean:(CLLocationDegrees)M;
+ (CLLocationDegrees)solarDeclinationForEclipticLongitude:(CLLocationDegrees)L;
+ (CLLocationDegrees)hourAngleForDeclination:(CLLocationDegrees)d atLatitude:(CLLocationDegrees)latitude;

@end
