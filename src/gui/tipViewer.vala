/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
