NSDate+Julian
=============

This is an NSDate Category for working with Julian dates + a few fun extras like sunrise and sunset calculaiton.

I created this set of functions because I needed to be able to tell whether the user was using the app during daylight
hours (defined as the sun being up) or not for a Pebble GPS app (Pebble Pilot GPS) with the goal of watch battery
longevity. I have included my sunrise/sunset computation method in the category in case anyone finds it useful. I even
went so far as to make the return value reflect midnight sun (sunset is NAN) and polar night (sunrise is NAN)
conditions in the return value.

The notable omission from this category is the inverse conversion from Julian to NSDate. I have been unable to find
sufficient authoritative documentation on how NSDate handles leap seconds, and can't seem to find another solid,
straightforward conversion formula that I'm confident will hold up over time. If anyone has a contribution to make,
please send a pull request, along with documentation as to why the method will work.

Hope you find this useful.
