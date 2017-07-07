/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A widget showing tips. The tips are beautifully faded in and out.
/////////////////////////////////////////////////////////////////////////

public class TipViewer : Gtk.Label {

    /////////////////////////////////////////////////////////////////////
    /// Some settings tweaking the behavior of the TipViewer.
    /////////////////////////////////////////////////////////////////////

    private const double fade_time = 0.5;
    private const double frame_rate = 20.0;
    private const double base_delay = 3.0;

    /////////////////////////////////////////////////////////////////////
    /// False, if the playback of tips is stopped.
    /////////////////////////////////////////////////////////////////////

    private bool playing = false;

    /////////////////////////////////////////////////////////////////////
    /// An array containing all tips.
    /////////////////////////////////////////////////////////////////////

    private string[] tips;

    /////////////////////////////////////////////////////////////////////
    /// The index of the currently displayed tip.
    /////////////////////////////////////////////////////////////////////

    private int index = -1;

    /////////////////////////////////////////////////////////////////////
    /// The fading value.
    /////////////////////////////////////////////////////////////////////

    private AnimatedValue alpha;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members and sets the basic layout.
    /////////////////////////////////////////////////////////////////////

    public TipViewer(string[] tips) {
        this.tips = tips;

        this.alpha = new AnimatedValue.linear(0.0, 1.0, fade_time);

        this.set_alignment (0.0f, 0.5f);
        this.opacity = 0;
        this.wrap = true;
        this.valign = Gtk.Align.END;
        this.set_use_markup(true);
    }

    /////////////////////////////////////////////////////////////////////
    /// Starts the playback of tips.
    /////////////////////////////////////////////////////////////////////

    public void start_slide_show() {
        if (!this.playing && tips.length > 1) {
            this.playing = true;
            show_tip();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Stops the playback of tips.
    /////////////////////////////////////////////////////////////////////

    public void stop_slide_show() {
        this.playing = false;
    }

    /////////////////////////////////////////////////////////////////////
    /// Starts the fading in.
    /////////////////////////////////////////////////////////////////////

    private void fade_in() {
        this.alpha = new AnimatedValue.linear(this.alpha.val, 1.0, fade_time);

        GLib.Timeout.add((uint)(1000.0/frame_rate), () => {
            this.alpha.update(1.0/frame_rate);
            this.opacity = this.alpha.val;

            return (this.alpha.val != 1.0);
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Starts the fading out.
    /////////////////////////////////////////////////////////////////////

    private void fade_out() {
        this.alpha = new AnimatedValue.linear(this.alpha.val, 0.0, fade_time);

        GLib.Timeout.add((uint)(1000.0/frame_rate), () => {
            this.alpha.update(1.0/frame_rate);
            this.opacity = this.alpha.val;

            return (this.alpha.val != 0.0);
        });
    }

    private void show_tip() {

        this.set_random_tip();

        this.fade_in();

        uint delay = (uint)(base_delay*1000.0) + tips[this.index].length*30;

        GLib.Timeout.add(delay, () => {
            this.fade_out();

            if (this.playing) {
                GLib.Timeout.add((uint)(1000.0*fade_time), () => {
                    this.show_tip();
                    return false;
                });
            }

            return false;
        });
    }

    /////////////////////////////////////////////////////////////////////
    /// Chooses the next random tip.
    /////////////////////////////////////////////////////////////////////

    private void set_random_tip() {
        if (tips.length > 1) {
            int next_index = -1;
            do {
                next_index = GLib.Random.int_range(0, tips.length);
            } while (next_index == this.index);
            this.index = next_index;
            this.label = "<small>" + tips[this.index] + "</small>";
        }
    }
}

}
