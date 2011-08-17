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
this program.  If not, see <http:www.gnu.org/licenses/>. 
*/

using GLib.Math;

namespace GnomePie {

public class Theme : GLib.Object {
    
    public string directory        {get; private set; default="";}
    public string name             {get; private set; default="";}
    public string description      {get; private set; default="";}
    public string author           {get; private set; default="";}
    public string email            {get; private set; default="";}
    public double radius           {get; private set; default=150;}
    public double max_zoom         {get; private set; default=1.2;}
    public double zoom_range       {get; private set; default=0.2;}
    public double transition_time  {get; private set; default=0.5;}
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
    public double slice_gap        {get; private set; default=14.0;}
    public bool   caption          {get; private set; default=false;}
    public double caption_size     {get; private set; default=100.0;}
    public double font_size        {get; private set; default=12.0;}
    public double caption_position {get; private set; default=0.0;}
    public Color  caption_color    {get; private set; default=new Color();}
    
    public Gee.ArrayList<CenterLayer?> center_layers         {get; private set;}
    public Gee.ArrayList<SliceLayer?>  active_slice_layers   {get; private set;}
    public Gee.ArrayList<SliceLayer?>  inactive_slice_layers {get; private set;}
    
    public Theme(string dir) {
        this.center_layers =         new Gee.ArrayList<CenterLayer?>();
        this.active_slice_layers =   new Gee.ArrayList<SliceLayer?>();
        this.inactive_slice_layers = new Gee.ArrayList<SliceLayer?>();
        
        this.directory = dir;
        
        this.load();
    }
    
    public void load() {
        this.center_layers.clear();
        this.active_slice_layers.clear();
        this.inactive_slice_layers.clear();
    
        Xml.Parser.init();
        string path = this.directory + "/theme.xml";
        
        Xml.Doc* themeXML = Xml.Parser.parse_file(path);
        if (themeXML == null) {
            warning("Error parsing theme: \"" + path + "\" not found!");
            return;
        }

        Xml.Node* root = themeXML->get_root_element();
        if (root == null) {
            delete themeXML;
            warning("Invalid theme \"" + this.directory + "\": theme.xml is empty!");
            return;
        }
        
        this.parse_root(root);
        
        delete themeXML;
        Xml.Parser.cleanup();
        
        this.radius *= max_zoom;
    }
    
    public void load_images() {
        foreach (var layer in this.center_layers)
            layer.load_image();
        foreach (var layer in this.active_slice_layers)
            layer.load_image();
        foreach (var layer in this.inactive_slice_layers)
            layer.load_image();
    }
    
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
    
    private void parse_slices(Xml.Node* slices) {
        for (Xml.Attr* attribute = slices->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;
            
            switch (attr_name) {
                 case "radius":
                    slice_radius = double.parse(attr_content) * Config.global.global_scale;
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
    
    private void parse_slice_layers(Xml.Node* slice) {
        for (Xml.Node* layer = slice->children; layer != null; layer = layer->next) {
            if (layer->type == Xml.ElementType.ELEMENT_NODE) {
                string element_name = layer->name.down();
                
                if (element_name == "slice_layer") {
                    string file = "";
                    double scale = 1.0;
                    bool is_icon = false;
                    bool colorize = false;
                    
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
                                    is_icon = true;
                                else if (attr_content == "icon")
                                    warning("Invalid attribute content " + attr_content + " for attribute " + attr_name + " in <slice_layer> element!");
                                break;
                            case "colorize":
                                colorize = bool.parse(attr_content);
                                break;
                            default:
                                warning("Invalid attribute \"" + attr_name + "\" in <slice_layer> element!");
                                break;
                        }
                    }
                    
                    if (file != "")
                        file = directory + "/" + file;
                    
                    int size = 2*(int)(slice_radius*scale*max_zoom);

                    if (slice->name.down() == "activeslice") {
                        active_slice_layers.add(new SliceLayer(file, size, colorize, is_icon));
                    } else {
                        inactive_slice_layers.add(new SliceLayer(file, size, colorize, is_icon));
                    }

                } else {
                    warning("Invalid child element \"" + element_name + "\" in <" + slice->name + "> element!");
                }
            }
        }
    }
    
    private void parse_caption(Xml.Node* caption) {
        for (Xml.Attr* attribute = caption->properties; attribute != null; attribute = attribute->next) {
            string attr_name = attribute->name.down();
            string attr_content = attribute->children->content;
            
            switch (attr_name) {
                case "fontsize":
                    font_size = double.parse(attr_content) * Config.global.global_scale;
                    break;
                case "maxsize":
                    caption_size = double.parse(attr_content) * Config.global.global_scale;
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
