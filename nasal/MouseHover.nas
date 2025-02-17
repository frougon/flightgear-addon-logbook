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
# MouseHover class
#
var MouseHover = {
    #
    # Constructor
    #
    # hash detailsDialog - DetailsDialog object
    # hash style - My style structure from Dialog
    # hash element - The element that will listen to the event
    # hash target - The element on which the event will be executed. If nil then `element` will be used as `target`.
    # vector dataRow - Logbook one row data to display after click. If nil then click event is not handling.
    #
    new: func (detailsDialog, style, element, target = nil, dataRow = nil) {
        var me = { parents: [MouseHover] };

        me.style = style;
        me.element = element;
        me.style = style;
        me.target = target == nil ? element : target;
        me.dataRow = dataRow;
        me.detailsDialog = detailsDialog;

        return me;
    },

    #
    # Add mouse events to the logbook row
    #
    addEvents: func() {
        me.element.addEventListener("mouseenter", func {
            me.target.setColorFill(me.style.HOVER_BG);
        });

        me.element.addEventListener("mouseleave", func {
            me.target.setColorFill([0.0, 0.0, 0.0, 0.0]);
        });

        if (me.dataRow != nil) {
            me.element.addEventListener("click", func {
                me.detailsDialog.show(me.dataRow);
            });
        }
    },
};
