/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
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

using GLib.Math;

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// A theme of Gnome-Pie. Can be loaded from XML-Files.
/////////////////////////////////////////////////////////////////////////

public class Theme : GLib.Object {

    /////////////////////////////////////////////////////////////////////
    /// Properties of a theme.
    /////////////////////////////////////////////////////////////////////

    public string directory        {get; private set; default="";}
    public string name             {get; private set; default="";}
    public string description      {get; private set; default="";}
    public string author           {get; private set; default="";}
    public string email            {get; private set; default="";}
    public double radius           {get; private set; default=150;}
    public double max_zoom         {get; private set; default=1.2;}
    public double zoom_range       {get; private set; default=0.2;}
    public double transition_time  {get; private set; default=0.5;}
    public double wobble           {get; private set; default=0.0;}
    public double fade_in_time     {get; private set; default=0.2;}
    public double fade_out_time    {get; private set; default=0.1;}
    public double fade_in_zoom     {get; private set; default=1.0;}
    public double fade_out_zoom    {get; private set; default=1.0;}
    public double fade_in_rotation {get; private set; default=0.0;}
    public double fade_out_rotation{get; private set; default=0.0;}
    public double springiness      {get; private set; default=0.0;}
    public double center_radius    {get; private set; default=90.0;}
    public double active_radius    {get; private set; default=45.0;}
    public double slice_radius     {get; private set; default=32.0;}
    public double visible_slice_radius {get; private set; default=0.0;}
    public double slice_gap        {get; private set; default=14.0;}
    public bool   has_slice_captions {get; private set; default=false;}
    public bool   caption          {get; private set; default=false;}
    public string caption_font     {get; private set; default="sans 12";}
    public int    caption_width    {get; private set; default=100;}
    public int    caption_height   {get; private set; default=100;}
    public double caption_position {get; private set; default=0.0;}
    public Color  caption_color    {get; private set; default=new Color();}
    public Icon   preview_icon     {get; private set; default=new Icon("gnome-pie", 36);}

    public Gee.ArrayList<CenterLayer?> center_layers         {get; private set;}
    public Gee.ArrayList<SliceLayer?>  active_slice_layers   {get; private set;}
    public Gee.ArrayList<SliceLayer?>  inactive_slice_layers {get; private set;}

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a theme object for a given theme directory. This
    /// directory should contain a theme.xml file.
    /////////////////////////////////////////////////////////////////////

    public Theme(string dir) {
        this.center_layers =         new Gee.ArrayList<CenterLayer?>();
        this.active_slice_layers =   new Gee.ArrayList<SliceLayer?>();
        this.inactive_slice_layers = new Gee.ArrayList<SliceLayer?>();

        this.directory = dir;
    }

    /////////////////////////////////////////////////////////////////////
    /// Loads the theme from its directory. Images have to be loaded
    /// explicitly.
    /////////////////////////////////////////////////////////////////////

    public bool load() {
        this.center_layers.clear();
        this.active_slice_layers.clear();
        this.inactive_slice_layers.clear();

        if (!GLib.File.new_for_path(this.directory).query_exists()) {
            return false;
        }

        string config_file = this.directory + "/theme.xml";

        if (!GLib.File.new_for_path(config_file).query_exists()) {
            try {
                // detect whether theme is one directory deeper
                string child;
                bool success = false;

                // load global themes
                var d = Dir.open(this.directory);
                while ((child = d.read_name()) != null && !success) {
                    config_file = this.directory + "/" + child + "/theme.xml";
                    if (GLib.File.new_for_path(config_file).query_exists()) {
                        this.directory = this.directory + "/" + child;
                        success = true;
                    }
                }

                if (!success) {
                    return false;
                }
            } catch (Error e) {
                warning (e.message);
                return false;
            }
        }

        this.preview_icon = new Icon(this.directory + "/preview.png", 36);

        Xml.Parser.init();

        Xml.Doc* themeXML = Xml.Parser.parse_file(config_file);
        if (themeXML == null) {
            warning("Failed to add theme: \"" + config_file + "\" not found!");
            return false;
        }

        Xml.Node* root = themeXML->get_root_element();
        if (root == null) {
            delete themeXML;
            warning("Failed to add theme: \"theme.xml\" is empty!");
            return false;
        }

        this.parse_root(root);

        delete themeXML;
        Xml.Parser.cleanup();

        this.radius *= max_zoom;

        return true;
    }


    /////////////////////////////////////////////////////////////////////
    /// Exports the theme directory to an importable archive.
    /////////////////////////////////////////////////////////////////////

    public void export(string file) {

        var archive = new ArchiveWriter();
        bool success = true;

        if (!archive.open(file)) {
            warning("Cannot open file " + file + " for writing!");
            success = false;
        } else if (!archive.add(this.directory)) {
            warning("Cannot append directory " + this.directory + " to archive!");
            success = false;
        }

        archive.close();

        if (success) {
            var message = _("Successfully exported the theme \"%s\"!").printf(this.name);
            var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL,
                                               Gtk.MessageType.INFO, Gtk.ButtonsType.CLOSE, message);
            dialog.run();
            dialog.destroy();

        } else {
            var message = _("An error occured while exporting the theme \"%s\"! Please check the console output.").printf(this.name);
            var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL,
                                               Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, message);
            dialog.run();
            dialog.destroy();
        }
    }


    /////////////////////////////////////////////////////////////////////
    /// Loads all images of the theme.
    /////////////////////////////////////////////////////////////////////

    public void load_images() {
        foreach (var layer in this.center_layers)
            layer.load_image();
        foreach (var layer in this.active_slice_layers)
            layer.load_image();
        foreach (var layer in this.inactive_slice_layers)
            layer.load_image();
    }

    /////////////////////////////////////////////////////////////////////
    /// Returns true if the theme is installed to the local themes
    /// directory.
    /////////////////////////////////////////////////////////////////////

    public bool is_local() {
        return this.directory.has_prefix(Paths.local_themes);
    }

    /////////////////////////////////////////////////////////////////////
    /// The following methods parse specific parts of the theme file.
    /// Nothing special here, just some boring code.
    /////////////////////////////////////////////////////////////////////

    private void parse_root(Xml.Node* root) {
        for (Xml.Attr* attribute = root->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "name":
                    name = attr_content;
                    break;
                case "description":
                    description = attr_content;
                    break;
                case "email":
                    email = attr_content;
                    break;
                case "author":
                    author = attr_content;
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <theme> element!");
                    break;
            }
        }
        for (Xml.Node* node = root->children; node != null; node = node->next) {
            if (node->type == Xml.ElementType.ELEMENT_NODE) {
                parse_pie(node);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <pie> element from the theme.xml file.
    /////////////////////////////////////////////////////////////////////

    private void parse_pie(Xml.Node* pie) {
        for (Xml.Attr* attribute = pie->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "radius":
                    radius = double.parse(attr_content) * Config.global.global_scale;
                    break;
                case "maxzoom":
                    max_zoom = double.parse(attr_content);
                    break;
                case "zoomrange":
                    zoom_range = double.parse(attr_content);
                    break;
                case "transitiontime":
                    transition_time = double.parse(attr_content);
                    break;
                case "wobble":
                    wobble = double.parse(attr_content);
                    break;
                case "fadeintime":
                    fade_in_time = double.parse(attr_content);
                    break;
                case "fadeouttime":
                    fade_out_time = double.parse(attr_content);
                    break;
                case "fadeinzoom":
                    fade_in_zoom = double.parse(attr_content);
                    break;
                case "fadeoutzoom":
                    fade_out_zoom = double.parse(attr_content);
                    break;
                case "fadeinrotation":
                    fade_in_rotation = double.parse(attr_content);
                    break;
                case "fadeoutrotation":
                    fade_out_rotation = double.parse(attr_content);
                    break;
                case "springiness":
                    springiness = double.parse(attr_content);
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <pie> element!");
                    break;
            }
        }
        for (Xml.Node* node = pie->children; node != null; node = node->next) {
            if (node->type == Xml.ElementType.ELEMENT_NODE) {
                string element_name = node->name.down();
                switch (element_name) {
                    case "center":
                        parse_center(node);
                        break;
                    case "slices":
                        parse_slices(node);
                        break;
                    case "caption":
                        caption = true;
                        parse_caption(node);
                        break;
                    default:
                        warning("Invalid child element \"" + element_name + "\" in <pie> element!");
                        break;
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <center> element from the theme.xml file.
    /////////////////////////////////////////////////////////////////////

    private void parse_center(Xml.Node* center) {
        for (Xml.Attr* attribute = center->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "radius":
                    center_radius = double.parse(attr_content) * Config.global.global_scale;
                    break;
                case "activeradius":
                    active_radius = double.parse(attr_content) * Config.global.global_scale;
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <center> element!");
                    break;
            }
        }
        for (Xml.Node* node = center->children; node != null; node = node->next) {
            if (node->type == Xml.ElementType.ELEMENT_NODE) {
                string element_name = node->name.down();

                if (element_name == "center_layer") {
                    parse_center_layer(node);
                } else {
                    warning("Invalid child element \"" + element_name + "\" in <center> element!");
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <slices> element from the theme.xml file.
    /////////////////////////////////////////////////////////////////////

    private void parse_slices(Xml.Node* slices) {
        for (Xml.Attr* attribute = slices->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                 case "radius":
                    slice_radius = double.parse(attr_content) * Config.global.global_scale;
                    visible_slice_radius = double.parse(attr_content) * Config.global.global_scale;
                    break;
                case "mingap":
                    slice_gap = double.parse(attr_content) * Config.global.global_scale;
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <slices> element!");
                    break;
            }
        }
        for (Xml.Node* node = slices->children; node != null; node = node->next) {
            if (node->type == Xml.ElementType.ELEMENT_NODE) {
                string element_name = node->name.down();

                if (element_name == "activeslice" || element_name == "inactiveslice") {
                    parse_slice_layers(node);
                } else {
                    warning("Invalid child element \"" + element_name + "\" in <slices> element!");
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <center_layer> element from the theme.xml file.
    /////////////////////////////////////////////////////////////////////

    private void parse_center_layer(Xml.Node* layer) {

        string file = "";
        double active_rotation_speed = 0.0;
        double inactive_rotation_speed = 0.0;
        double active_scale = 1.0;
        double inactive_scale = 1.0;
        double active_alpha = 1.0;
        double inactive_alpha = 1.0;
        bool   active_colorize = false;
        bool   inactive_colorize = false;
        CenterLayer.RotationMode active_rotation_mode = CenterLayer.RotationMode.AUTO;
        CenterLayer.RotationMode inactive_rotation_mode = CenterLayer.RotationMode.AUTO;

        for (Xml.Attr* attribute = layer->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "file":
                    file = attr_content;
                    break;
                case "active_scale":
                    active_scale = double.parse(attr_content);
                    break;
                case "active_alpha":
                    active_alpha = double.parse(attr_content);
                    break;
                case "active_rotationmode":
                    switch (attr_content.down()) {
                        case "auto":
                           active_rotation_mode = CenterLayer.RotationMode.AUTO;
                           break;
                        case "turn_to_active":
                           active_rotation_mode = CenterLayer.RotationMode.TO_ACTIVE;
                           break;
                        case "turn_to_mouse":
                           active_rotation_mode = CenterLayer.RotationMode.TO_MOUSE;
                           break;
                        case "turn_to_hour":
                        case "turn_to_hour_12":
                           active_rotation_mode = CenterLayer.RotationMode.TO_HOUR_12;
                           break;
                        case "turn_to_hour_24":
                           active_rotation_mode = CenterLayer.RotationMode.TO_HOUR_24;
                           break;
                        case "turn_to_minute":
                           active_rotation_mode = CenterLayer.RotationMode.TO_MINUTE;
                           break;
                        case "turn_to_second":
                           active_rotation_mode = CenterLayer.RotationMode.TO_SECOND;
                           break;
                        default:
                           warning("Invalid value \"" + attr_content + "\" for attribute \"" + attr_name + "\" in <center_layer> element!");
                           break;
                    }
                    break;
                case "active_rotationspeed":
                    active_rotation_speed = double.parse(attr_content);
                    break;
                case "active_colorize":
                    active_colorize = bool.parse(attr_content);
                    break;
                case "inactive_scale":
                    inactive_scale = double.parse(attr_content);
                    break;
                case "inactive_alpha":
                    inactive_alpha = double.parse(attr_content);
                    break;
                case "inactive_rotationmode":
                    switch (attr_content.down()) {
                        case "auto":
                           inactive_rotation_mode = CenterLayer.RotationMode.AUTO;
                           break;
                        case "turn_to_active":
                           inactive_rotation_mode = CenterLayer.RotationMode.TO_ACTIVE;
                           break;
                        case "turn_to_mouse":
                           inactive_rotation_mode = CenterLayer.RotationMode.TO_MOUSE;
                           break;
                        case "turn_to_hour":
                        case "turn_to_hour_12":
                           inactive_rotation_mode = CenterLayer.RotationMode.TO_HOUR_12;
                           break;
                        case "turn_to_hour_24":
                           inactive_rotation_mode = CenterLayer.RotationMode.TO_HOUR_24;
                           break;
                        case "turn_to_minute":
                           inactive_rotation_mode = CenterLayer.RotationMode.TO_MINUTE;
                           break;
                        case "turn_to_second":
                           inactive_rotation_mode = CenterLayer.RotationMode.TO_SECOND;
                           break;
                        default:
                           warning("Invalid value \"" + attr_content + "\" for attribute \"" + attr_name + "\" in <center_layer> element!");
                           break;
                    }
                    break;
                case "inactive_rotationspeed":
                    inactive_rotation_speed = double.parse(attr_content);
                    break;
                case "inactive_colorize":
                    inactive_colorize = bool.parse(attr_content);
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <center_layer> element!");
                    break;
            }
        }

        double max_scale = GLib.Math.fmax(active_scale, inactive_scale);
        center_layers.add(new CenterLayer(directory + "/" + file, (int)(center_radius*max_scale), active_scale/max_scale,   active_rotation_speed,   active_alpha,   active_colorize,   active_rotation_mode,
                                                 inactive_scale/max_scale, inactive_rotation_speed, inactive_alpha, inactive_colorize, inactive_rotation_mode));
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <slice_layer> element from the theme.xml file.
    /////////////////////////////////////////////////////////////////////

    private void parse_slice_layers(Xml.Node* slice) {
        for (Xml.Node* layer = slice->children; layer != null; layer = layer->next) {
            if (layer->type == Xml.ElementType.ELEMENT_NODE) {
                string element_name = layer->name.down();

                if (element_name == "slice_layer") {
                    string file = "";
                    double scale = 1.0;
                    SliceLayer.Type type = SliceLayer.Type.FILE;
                    SliceLayer.Visibility visibility = SliceLayer.Visibility.ANY;
                    bool colorize = false;
                    string slice_caption_font = "sans 8";
                    int slice_caption_width = 50;
                    int slice_caption_height = 20;
                    int pos_x = 0;
                    int pos_y = 0;
                    Color slice_caption_color = new Color.from_rgb(1.0f, 1.0f, 1.0f);

                    for (Xml.Attr* attribute = layer->properties; attribute != null; attribute = attribute->next) {
                        string attr_name = attribute->name.down();
                        string attr_content = attribute->children->content;

                        switch (attr_name) {
                            case "file":
                                file = attr_content;
                                break;
                            case "scale":
                                scale = double.parse(attr_content);
                                break;
                            case "type":
                                if (attr_content == "icon")
                                    type = SliceLayer.Type.ICON;
                                else if (attr_content == "caption")
                                    type = SliceLayer.Type.CAPTION;
                                else if (attr_content != "file")
                                    warning("Invalid attribute content " + attr_content + " for attribute " + attr_name + " in <slice_layer> element!");
                                break;
                            case "colorize":
                                colorize = bool.parse(attr_content);
                                break;
                            case "font":
                                slice_caption_font = attr_content;
                                break;
                            case "width":
                                slice_caption_width = (int)(int.parse(attr_content) * Config.global.global_scale);
                                if (slice_caption_width % 2 == 1)
                                    --slice_caption_width;
                                break;
                            case "height":
                                slice_caption_height = (int)(int.parse(attr_content) * Config.global.global_scale);
                                if (slice_caption_height % 2 == 1)
                                    --slice_caption_height;
                                break;
                            case "x":
                                pos_x = (int)(double.parse(attr_content) * Config.global.global_scale);
                                break;
                            case "y":
                                pos_y = (int)(double.parse(attr_content) * Config.global.global_scale);
                                break;
                            case "color":
                                slice_caption_color = new Color.from_string(attr_content);
                                break;
                            case "visibility":
                                if (attr_content == "without_caption")
                                    visibility = SliceLayer.Visibility.WITHOUT_CAPTION;
                                else if (attr_content == "with_caption") {
                                    this.has_slice_captions = true;
                                    visibility = SliceLayer.Visibility.WITH_CAPTION;
                                } else if (attr_content != "any")
                                    warning("Invalid attribute content " + attr_content + " for attribute " + attr_name + " in <slice_layer> element!");
                                break;
                            default:
                                warning("Invalid attribute \"" + attr_name + "\" in <slice_layer> element!");
                                break;
                        }
                    }

                    if (file != "")
                        file = directory + "/" + file;

                    int size = 2*(int)(slice_radius*scale*max_zoom);
                    this.visible_slice_radius = Math.fmax(slice_radius*scale, this.visible_slice_radius);

                    if (slice->name.down() == "activeslice") {
                        if (type == SliceLayer.Type.ICON)         active_slice_layers.add(new SliceLayer.icon(file, size, pos_x, pos_y, colorize, visibility));
                        else if (type == SliceLayer.Type.CAPTION) active_slice_layers.add(new SliceLayer.caption(slice_caption_font,
                                                                             slice_caption_width, slice_caption_height,
                                                                             pos_x, pos_y, slice_caption_color, colorize, visibility));
                        else                                      active_slice_layers.add(new SliceLayer.file(file, size, pos_x, pos_y, colorize, visibility));
                    } else {
                        if (type == SliceLayer.Type.ICON)         inactive_slice_layers.add(new SliceLayer.icon(file, size, pos_x, pos_y, colorize, visibility));
                        else if (type == SliceLayer.Type.CAPTION) inactive_slice_layers.add(new SliceLayer.caption(slice_caption_font,
                                                                             slice_caption_width, slice_caption_height,
                                                                             pos_x, pos_y, slice_caption_color, colorize, visibility));
                        else                                      inactive_slice_layers.add(new SliceLayer.file(file, size, pos_x, pos_y, colorize, visibility));
                    }

                } else {
                    warning("Invalid child element \"" + element_name + "\" in <" + slice->name + "> element!");
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses a <caption> element from the theme.xml file.
    /////////////////////////////////////////////////////////////////////

    private void parse_caption(Xml.Node* caption) {
        for (Xml.Attr* attribute = caption->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;

            switch (attr_name) {
                case "font":
                    caption_font = attr_content;
                    break;
                case "width":
                    caption_width = (int)(int.parse(attr_content) * Config.global.global_scale);
                    if (caption_width % 2 == 1)
                        --caption_width;
                    break;
                case "height":
                    caption_height = (int)(int.parse(attr_content) * Config.global.global_scale);
                    if (caption_height % 2 == 1)
                        --caption_height;
                    break;
                case "position":
                    caption_position = double.parse(attr_content) * Config.global.global_scale;
                    break;
                case "color":
                    caption_color = new Color.from_string(attr_content);
                    break;
                default:
                    warning("Invalid attribute \"" + attr_name + "\" in <caption> element!");
                    break;
            }
        }

    }

}

}
