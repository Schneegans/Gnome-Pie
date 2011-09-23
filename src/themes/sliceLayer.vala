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
/// This class representing a layer of a slice of a pie. Each theme may
/// have plenty of them.
/////////////////////////////////////////////////////////////////////////

public class SliceLayer : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// Information on the contained image.
    /////////////////////////////////////////////////////////////////////
    
    public Image image {get; set;}
    public string icon_file {get; private set;}
    
    /////////////////////////////////////////////////////////////////////
    /// Properties of this layer.
    /////////////////////////////////////////////////////////////////////
    
    public bool colorize {get; private set; }
    public bool is_icon {get; private set;}
    public int icon_size {get; private set;}
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members of the layer.
    /////////////////////////////////////////////////////////////////////
    
    public SliceLayer(string icon_file, int icon_size, bool colorize, bool is_icon) {
        this.icon_file = icon_file;
        this.colorize = colorize;
        this.is_icon = is_icon;
        this.icon_size = icon_size;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads the contained image.
    /////////////////////////////////////////////////////////////////////
    
    public void load_image() {
        if (this.icon_file == "" && this.is_icon == true) 
            this.image = new Image.empty(this.icon_size, this.icon_size, new Color.from_rgb(1, 1, 1));
        else
            this.image = new Image.from_file_at_size(this.icon_file, this.icon_size, this.icon_size);
    }
}

}
