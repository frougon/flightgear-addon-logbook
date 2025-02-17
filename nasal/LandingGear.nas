#
# Logbook - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Logbook is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class LandingGear
#
var LandingGear = {
    #
    # Constants
    #
    GEAR_FLOATS : "floats",

    #
    # Constructor
    #
    new: func () {
        var me = { parents: [LandingGear] };

        me.gearIndexes = [];

        # Used to count seconds during landing without landing gear recognition
        me.landingCountSec = 0;
        me.landingAmount = 0;

        return me;
    },

    #
    # Recognize and count landing gears if possible
    #
    # bool onGround - If true then aircraft start on the ground, otherwise in air
    # return int - nuber of found wheels/landing gears
    #
    recognizeGears: func(onGround) {
        me.resetLandingWithNoGearRecognized();

        me.gearIndexes = [];

        if (onGround) {
            # We are on the ground, so we can count the gears from "/gear/gear[n]/wow" property
            me.loopThroughGears(func(index) {
                logprint(LOG_ALERT, "Logbook Add-on - recognizeGears: landing gear found at index = ", index);
                append(me.gearIndexes, index);
            });

            if (size(me.gearIndexes) == 0) {
                # No landing gear found, check floats
                if (me.isFloatsDragOnWater()) {
                    logprint(LOG_ALERT, "Logbook Add-on - recognizeGears: floats detected");
                    append(me.gearIndexes, LandingGear.GEAR_FLOATS);
                }
            }
        }

        return size(me.gearIndexes);
    },

    #
    # Check the WoW state of all landing gears
    #
    # bool onGround
    # return bool
    #
    checkWow: func(onGround) {
        var counters = {
            'onGroundGearCounter' : 0,
            'inAirGearCounter'    : 0,
            'expectedCount'       : size(me.gearIndexes),
        };

        if (counters.expectedCount > 0) {
            # We know we have some landing gears
            counters = me.checkWowWithGearRecognized(counters, onGround);
        }
        else if (!onGround) {
            # We know nothing about landing gears, try check all of them, it make sense for landing only
            counters = me.checkWowWithNoGearRecognized(counters);
        }

        if (counters.inAirGearCounter == 0 and counters.onGroundGearCounter == 0) {
            # Nothing detected
            return false;
        }

        return onGround
            ? (counters.expectedCount == counters.inAirGearCounter) # all wheels are in the air - takeoff
            : (counters.expectedCount == counters.onGroundGearCounter); # all wheels are on the ground - landing
    },

    #
    # Check Wow with gear recognized.
    #
    # hash counters
    # bool onGround
    # return hash
    #
    checkWowWithGearRecognized: func(counters, onGround) {
        foreach (var index; me.gearIndexes) {
            if (index == LandingGear.GEAR_FLOATS) {
                # Check whether gear down
                if (!onGround and getprop("/controls/gear/gear-down")) {
                    # Probably the amphibian took off on floats and it's now landing on wheels
                    counters = me.checkWowWithNoGearRecognized(counters);
                }
                else {
                    # Probably using floats
                    me.isFloatsDragOnWater()
                        ? (counters.onGroundGearCounter += 1)
                        : (counters.inAirGearCounter += 1);
                }
            }
            else {
                # logprint(MY_LOG_LEVEL, "Logbook Add-on - checkWow index = ", index);
                getprop("/gear/gear[" ~ index ~ "]/wow")
                    ? (counters.onGroundGearCounter += 1)
                    : (counters.inAirGearCounter += 1);
            }
        }

        if (!onGround and counters.onGroundGearCounter == 0 and counters.inAirGearCounter == 0) {
            # A case where an amphibian took off on wheels and now might want to land on water

            if (me.isFloatsDragOnWater()) {
                # Force water landing confirmation
                counters.onGroundGearCounter = 1;
                counters.expectedCount = 1;
            }
        }

        return counters;
    },

    #
    # Try to check WoW with NO gear recognized by check all of them. It make sense for landing only.
    #
    # hash counters
    # return hash
    #
    checkWowWithNoGearRecognized: func(counters) {
        me.loopThroughGears(func {
            counters.onGroundGearCounter += 1;
        });

        if (counters.onGroundGearCounter > 0) {
            # We know how many wheels we put on the ground, but we don't know how many there should be!
            # We can assume that if it keeps returning the same number for x seconds, we've landed.
            if (me.landingCountSec > 2) {
                # We assume we have landed
                counters.expectedCount = counters.onGroundGearCounter;
            }
            else {
                if (me.landingAmount == counters.onGroundGearCounter) {
                    me.landingCountSec += 1;
                }
                else {
                    me.landingAmount = counters.onGroundGearCounter;
                    me.landingCountSec = 0;
                }
            }
        }
        else {
            me.resetLandingWithNoGearRecognized();

            # Maybe floats?
            if (me.isFloatsDragOnWater()) {
                # We have landing on floats
                counters.onGroundGearCounter = 1;
                counters.expectedCount = 1;
            }
        }

        return counters;
    },

    #
    # Check if the airplane has water drag on the floats (JSBSim only).
    #
    # return bool - Return true if drag force detected.
    #
    isFloatsDragOnWater: func() {
        var fdragLbs = getprop("/fdm/jsbsim/hydro/fdrag-lbs");
        return fdragLbs != nil and fdragLbs > 0;
    },

    resetLandingWithNoGearRecognized: func() {
        me.landingAmount = 0;
        me.landingCountSec = 0;
    },

    #
    # Loop through all gears properties
    #
    # callback - Function that will be called with the gear index of which WoW is true.
    #
    loopThroughGears: func(callback) {
        foreach (var gear; props.globals.getNode("/gear").getChildren("gear")) {
            var wow = gear.getChild("wow");
            if (wow != nil and wow.getValue()) {
                callback(gear.getIndex());
            }
        }
    }
};
