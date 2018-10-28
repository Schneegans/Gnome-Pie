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
/// A class representing a square-shaped icon, themed according to the
/// current theme of Gnome-Pie.
/////////////////////////////////////////////////////////////////////////

public class ThemedIcon : Image {

    /////////////////////////////////////////////////////////////////////
    /// Paint a slice icon according to the current theme.
    /////////////////////////////////////////////////////////////////////

    public ThemedIcon(string caption, string icon_name, bool active) {

        // get layers for the desired slice type
        var layers = active ? Config.global.theme.active_slice_layers : Config.global.theme.inactive_slice_layers;

        // get max size
        int size = 1;
        foreach (var layer in layers) {
            if (layer.image != null && layer.image.width() > size)
                size = layer.image.width();
        }

        this.surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);

        // get size of icon layer
        int icon_size = size;
        foreach (var layer in layers) {
            if (layer.image != null && layer.layer_type == SliceLayer.Type.ICON)
                icon_size = layer.image.width();
        }

        Image icon;
        if (icon_name.contains("/"))
            icon = new Image.from_file_at_size(icon_name, icon_size, icon_size);
        else
            icon = new Icon(icon_name, icon_size);

        var color = new Color.from_icon(icon);
        var ctx = this.context();

        ctx.translate(size/2, size/2);
        ctx.set_operator(Cairo.Operator.OVER);

        // now render all layers on top of each other
        foreach (var layer in layers) {

            if (layer.visibility == SliceLayer.Visibility.ANY ||
                (Config.global.show_captions == (layer.visibility == SliceLayer.Visibility.WITH_CAPTION))) {

                if (layer.colorize) {
                    ctx.push_group();
                }

                if (layer.layer_type == SliceLayer.Type.ICON) {
                    ctx.push_group();

                    ctx.translate(layer.x, layer.y);
                    layer.image.paint_on(ctx);

                    ctx.set_operator(Cairo.Operator.IN);

                    if (layer.image.width() != icon_size) {
                        if (icon_name.contains("/"))
                            icon = new Image.from_file_at_size(icon_name, layer.image.width(), layer.image.width());
                        else
                            icon = new Icon(icon_name,layer.image.width());
                    }

                    icon.paint_on(ctx);
                    ctx.translate(-layer.x, -layer.y);

                    ctx.pop_group_to_source();
                    ctx.paint();
                    ctx.set_operator(Cairo.Operator.OVER);

                } else if (layer.layer_type == SliceLayer.Type.CAPTION) {
                    Image text = new RenderedText(caption, layer.width, layer.height, layer.font, layer.color, Config.global.global_scale);
                    ctx.translate(layer.x, layer.y);
                    text.paint_on(ctx);
                    ctx.translate(-layer.x, -layer.y);
                } else if (layer.layer_type == SliceLayer.Type.FILE) {
                    ctx.translate(layer.x, layer.y);
                    layer.image.paint_on(ctx);
                    ctx.translate(-layer.x, -layer.y);
                }

                // colorize the whole layer if neccasary
                if (layer.colorize) {
                    ctx.set_operator(Cairo.Operator.ATOP);
                    ctx.set_source_rgb(color.r, color.g, color.b);
                    ctx.paint();

                    ctx.set_operator(Cairo.Operator.OVER);
                    ctx.pop_group_to_source();
                    ctx.paint();
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns the size of the icon in pixels. Greetings to Liskov.
    /////////////////////////////////////////////////////////////////////

    public int size() {
        return base.width();
    }
}

}
