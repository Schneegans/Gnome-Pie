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

    public enum Type { IMAGE, ICON, CAPTION, CAPTION_BACKGROUND }
    public Type layer_type { get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Information on the contained image.
    /////////////////////////////////////////////////////////////////////
    
    public Image image {get; set;}
    
    
    /////////////////////////////////////////////////////////////////////
    /// Properties of this layer.
    /////////////////////////////////////////////////////////////////////
    
    public string icon_file {get; private set; default="";}
    public bool colorize {get; private set; default=false;}
    public int icon_size {get; private set; default=1;}
    
    public string font {get; private set; default="";}
    public int width {get; private set; default=0;}
    public int height {get; private set; default=0;}
    public int position {get; private set; default=0;}
    public Color color {get; private set; default=new Color();}
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members of the layer.
    /////////////////////////////////////////////////////////////////////
    
    public SliceLayer(string icon_file, int icon_size, bool colorize) {
        this.layer_type = Type.IMAGE;
        this.icon_file = icon_file;
        this.colorize = colorize;
        this.icon_size = icon_size;
    }
    
    public SliceLayer.icon(string icon_file, int icon_size, bool colorize) {
        this.layer_type = Type.ICON;
        this.icon_file = icon_file;
        this.colorize = colorize;
        this.icon_size = icon_size;
    }
    
    public SliceLayer.caption(string font, int width, int height, int position, Color color) {
        this.layer_type = Type.CAPTION;
        this.font = font;
        this.width = width;
        this.height = height;
        this.position = position;
        this.color = color;
    }
    
    public SliceLayer.caption_bg(string icon_file, int icon_size, bool colorize) {
        this.layer_type = Type.CAPTION_BACKGROUND;
        this.icon_file = icon_file;
        this.colorize = colorize;
        this.icon_size = icon_size;
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads the contained image.
    /////////////////////////////////////////////////////////////////////
    
    public void load_image() {
        this.image = null;
    
        if (this.icon_file == "" && this.layer_type == Type.ICON) 
            this.image = new Image.empty(this.icon_size, this.icon_size, new Color.from_rgb(1, 1, 1));
        else if (this.icon_file != "")
            this.image = new Image.from_file_at_size(this.icon_file, this.icon_size, this.icon_size);
    }
}

}
