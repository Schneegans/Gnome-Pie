/* 
Copyright (c) 2011 by Simon Schneegans

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

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
    private const double delay = 7.0;

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
    /// Colors of the font and the background. Used for fading effects.
    /////////////////////////////////////////////////////////////////////
    
    private Gdk.Color fg;
    private Gdk.Color bg;
    
    /////////////////////////////////////////////////////////////////////
    /// The fading value.
    /////////////////////////////////////////////////////////////////////
    
    private AnimatedValue alpha;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members and sets the basic layout.
    /////////////////////////////////////////////////////////////////////
    
    public TipViewer(string[] tips) {
        this.tips = tips;
        this.fg = this.get_style().fg[0];
        this.bg = this.get_style().bg[0];
        
        this.alpha = new AnimatedValue.linear(0.8, 0.0, this.fade_time);
        
        this.set_alignment (0.0f, 0.5f);
        this.wrap = true;
        this.width_chars = 60;
        this.set_use_markup(true);
        //this.set_ellipsize(Pango.EllipsizeMode.END);
        this.modify_font(Pango.FontDescription.from_string("9"));
        
        this.set_random_tip();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Starts the playback of tips.
    /////////////////////////////////////////////////////////////////////
    
    public void start_slide_show() {
        if (!this.playing && tips.length > 1) {
            this.playing = true;
            GLib.Timeout.add((uint)(this.delay*1000.0), () => {
                this.fade_out();
                
                GLib.Timeout.add((uint)(1000.0*this.fade_time), () => {
                    this.set_random_tip();
                    this.fade_in();
                    return false;
                });
                
                return this.playing;
            });
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
        this.alpha = new AnimatedValue.linear(this.alpha.val, 0.8, this.fade_time);
        
        GLib.Timeout.add((uint)(1000.0/this.frame_rate), () => {
            this.alpha.update(1.0/this.frame_rate);
            this.update_label();
            
            return (this.alpha.val != 0.8);
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Starts the fading out.
    /////////////////////////////////////////////////////////////////////
    
    private void fade_out() {
        this.alpha = new AnimatedValue.linear(this.alpha.val, 0.0, this.fade_time);
        
        GLib.Timeout.add((uint)(1000.0/this.frame_rate), () => {
            this.alpha.update(1.0/this.frame_rate);
            this.update_label();
            
            return (this.alpha.val != 0.0);
        });
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Updates the color of the label. Called every frame while fading.
    /////////////////////////////////////////////////////////////////////
    
    private void update_label() {
        Gdk.Color color = {(uint32)(fg.pixel*this.alpha.val + bg.pixel*(1.0 - this.alpha.val)),
                           (uint16)(fg.red*this.alpha.val + bg.red*(1.0 - this.alpha.val)),
                           (uint16)(fg.green*this.alpha.val + bg.green*(1.0 - this.alpha.val)),
                           (uint16)(fg.blue*this.alpha.val + bg.blue*(1.0 - this.alpha.val))};
        
        this.modify_fg(Gtk.StateType.NORMAL, color);
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
            this.label = tips[this.index];
        }
    }
}

}
