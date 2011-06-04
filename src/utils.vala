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

using GLib.Math;

namespace GnomePie.Utils {
    
    public double refresh_rate = 60.0;
    
    // Code from Unity 
    public void get_icon_color(Cairo.ImageSurface icon, out Color color) {
        
        unowned uchar[] data = icon.get_data();
        
        uint width = icon.get_width();
        uint height = icon.get_height();
        uint row_bytes = icon.get_stride();

        double total = 0.0;
        double rtotal = 0.0;
        double gtotal = 0.0;
        double btotal = 0.0; 

        for (uint i = 0; i < width; ++i) {
            for (uint j = 0; j < height; ++j) {
                uint pixel = j * row_bytes + i * 4;
                double b = data[pixel + 0]/255.0;
                double g = data[pixel + 1]/255.0;
                double r = data[pixel + 2]/255.0;
                double a = data[pixel + 3]/255.0;

                double saturation = (fmax (r, fmax (g, b)) - fmin (r, fmin (g, b)));
                double relevance = 0.1 + 0.9 * a * saturation;
                
               // stdout.printf("%4i", (int)(saturation*255.0));

                rtotal +=  (r * relevance);
                gtotal +=  (g * relevance);
                btotal +=  (b * relevance);

                total += relevance;
            }
            
           // stdout.printf("%\n");
        }

        color = new Color.from_rgb((float)(rtotal/total), (float)(gtotal/total), (float)(btotal/total));

        if (color.s > 0.15f)
        color.s = 0.65f;

        color.v = 1.0f;
    }
    
    // Code from Gnome-Do/Synapse 
    public static void present_window(Gtk.Window window) {
        // raise without grab
        uint32 timestamp = Gtk.get_current_event_time();
        window.present_with_time(timestamp);
        window.get_window().raise();
        window.get_window().focus(timestamp);

        // grab
        int i = 0;
        Timeout.add (100, ()=>{
            if (i >= 100) return false;
            ++i;
            return !try_grab_window(window);
        });
    }
    
    // Code from Gnome-Do/Synapse 
    public static void unpresent_window(Gtk.Window window) {
        uint32 time = Gtk.get_current_event_time();

        Gdk.pointer_ungrab (time);
        Gdk.keyboard_ungrab (time);
        Gtk.grab_remove (window);
    }
    
    // Code from Gnome-Do/Synapse 
    private static bool try_grab_window(Gtk.Window window) {
        uint time = Gtk.get_current_event_time();
        if (Gdk.pointer_grab (window.get_window(), true,
            Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
            null, null, time) == Gdk.GrabStatus.SUCCESS) {
            
            if (Gdk.keyboard_grab(window.get_window(), true, time) == Gdk.GrabStatus.SUCCESS) {
                Gtk.grab_add(window);
                return true;
            } else {
                Gdk.pointer_ungrab(time);
                return false;
            }
        }
        return false;
    }
}
