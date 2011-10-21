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
/// This class represents a hotkey, used to open pies. It supports any
/// combination of modifier keys with keyboard and mouse buttons.
/////////////////////////////////////////////////////////////////////////

public class Trigger : GLib.Object {

    private bool with_mouse;
    private int key_code;
    private Gdk.ModifierType modifiers;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates an invalid Trigger.
    /////////////////////////////////////////////////////////////////////
    
    public Trigger() {
        this.with_mouse = false;
        this.key_code = -1;
        this.modifiers = 0;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new Trigger from a given Trigger string. This is
    /// in this format: 
    /////////////////////////////////////////////////////////////////////
    
    public Trigger.from_string(string trigger) {
        this.parse_string(trigger);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes static members.
    /////////////////////////////////////////////////////////////////////
    
    public void parse_string(string trigger) {
        
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes static members.
    /////////////////////////////////////////////////////////////////////
    
    public string get_label() {
        if (this.with_mouse) {
            return "";
        } else {
            return "";
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Initializes static members.
    /////////////////////////////////////////////////////////////////////
    
    public string get_trigger() {
        return "";
    }
}

}
