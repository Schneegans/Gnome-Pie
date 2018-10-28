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
/// This class representing a layer of a slice of a pie. Each theme may
/// have plenty of them.
/////////////////////////////////////////////////////////////////////////

public class SliceLayer : GLib.Object {

    public enum Type { FILE, ICON, CAPTION }
    public enum Visibility { ANY, WITH_CAPTION, WITHOUT_CAPTION }

    public Type layer_type { get; private set; }
    public Visibility visibility { get; private set; }

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
    public int x {get; private set; default=0;}
    public int y {get; private set; default=0;}
    public Color color {get; private set; default=new Color();}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members of the layer.
    /////////////////////////////////////////////////////////////////////

    public SliceLayer.file(string icon_file, int icon_size, int x, int y, bool colorize, Visibility visibility) {
        this.layer_type = Type.FILE;
        this.icon_file = icon_file;
        this.colorize = colorize;
        this.icon_size = icon_size;
        this.x = x;
        this.y = y;
        this.visibility = visibility;
    }

    public SliceLayer.icon(string icon_file, int icon_size, int x, int y, bool colorize, Visibility visibility) {
        this.layer_type = Type.ICON;
        this.icon_file = icon_file;
        this.colorize = colorize;
        this.icon_size = icon_size;
        this.x = x;
        this.y = y;
        this.visibility = visibility;
    }

    public SliceLayer.caption(string font, int width, int height, int x, int y, Color color, bool colorize, Visibility visibility) {
        this.layer_type = Type.CAPTION;
        this.font = font;
        this.width = width;
        this.height = height;
        this.x = x;
        this.y = y;
        this.color = color;
        this.visibility = visibility;
        this.colorize = colorize;
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
