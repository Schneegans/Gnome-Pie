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

namespace GnomePie {

    public class PieWindow : Gtk.Window {
    
        private Pie pie {private get; private set;}
        private KeybindingManager bindings {get; private set;}
    
        public PieWindow(Pie pie, string stroke) {
            init();
            _pie = pie;
            
            bindings.bind_global_press(stroke, () => {
                this.show();
            });
		    
		    bindings.bind_local_release(stroke, () => {
		        if (!Settings.global.click_to_activate)
		            activate_pie();
		    });
		    
		    bindings.bind_local_press(stroke, () => {
		        if (Settings.global.click_to_activate) 
		            this.pie.hide();
		    });
		    
		    bindings.bind_local_press("Escape", () => { 
		        this.pie.hide();
		    });
		    
		    bindings.bind_local_press("Return", () => { 
		        activate_pie();
		    });
		    
		    bindings.bind_local_press("space", () => { 
		        activate_pie();
		    });
        }
        
        private bool draw(Gtk.Widget da, Gdk.EventExpose event) {
            double mouse_x = 0.0;
	        double mouse_y = 0.0;
	        get_pointer(out mouse_x, out mouse_y);
	        mouse_x -= width_request*0.5;
	        mouse_y -= height_request*0.5;
	        
	        var ctx = Gdk.cairo_create(window);
            ctx.set_operator(Cairo.Operator.OVER);
            ctx.translate(width_request*0.5, height_request*0.5);
        
            pie.draw(ctx, mouse_x, mouse_y);

            return true;
        }
        
        private void mouse_released(int button, int x, int y) {
            if (button == 1) 
    	        activate_pie();
        }
        
        private void activate_pie() {
            WindowUtils.unfix_focus_on(this);
	        this.has_focus = 0;
	        pie.activate();
        }
        
        public override void show() {
            base.show();
            WindowUtils.fix_focus_on(this);

            Timeout.add ((uint)(1000.0/Settings.global.refresh_rate), () => {
	            this.queue_draw();
	            return visible;
	        });
        }
        
        private void init() {
            int size = (int)(fmax(2*Settings.global.theme.radius + 4*Settings.global.theme.slice_radius, 2*Settings.global.theme.center_radius));

            this.set_title("Gnome-Pie");
            this.set_size_request (size, size);
            this.set_skip_taskbar_hint(true);
            this.set_skip_pager_hint(true);
            this.set_keep_above(true);
            this.set_type_hint(Gdk.WindowTypeHint.SPLASHSCREEN);
            this.set_colormap(screen.get_rgba_colormap());
            this.set_decorated(false);
            this.set_app_paintable(true);
            this.set_resizable(false);
            this.set_accept_focus(false);
            
            this.bindings = new KeybindingManager();
            
            Settings.global.notify["open-at-mouse"].connect((s, p) => {
                if(Settings.global.open_at_mouse) this.set_position(Gtk.WindowPosition.MOUSE);
                else                              this.set_position(Gtk.WindowPosition.CENTER);
            }); 
            
            Settings.global.notify["theme"].connect((s, p) => {
                size = (int)(fmax(2*Settings.global.theme.radius + 4*Settings.global.theme.slice_radius, 2*Settings.global.theme.center_radius));
                this.set_size_request (size, size);
            });
            
            if(Settings.global.open_at_mouse) this.set_position(Gtk.WindowPosition.MOUSE);
            else                              this.set_position(Gtk.WindowPosition.CENTER);
                
            add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
            add_events(Gdk.EventMask.KEY_RELEASE_MASK);
            add_events(Gdk.EventMask.KEY_PRESS_MASK);
            
            this.button_release_event.connect ((e) => {
                mouse_released((int) e.button, (int) e.x, (int) e.y);
                return true;
            });
            
            this.key_release_event.connect ((e) => {
                if(e.is_modifier == 0) {
                    bindings.on_key_release(e.keyval, e.state);
                }
                return true;
            });
            
            this.key_press_event.connect ((e) => {
                if(e.is_modifier == 0) {
                    bindings.on_key_press(e.keyval, e.state);
                }
                return true;
            });

            this.expose_event.connect(this.draw);
            this.destroy.connect(Gtk.main_quit);
        }
        
        public static void create_all() {
            
            Xml.Parser.init();
            Xml.Doc* piesXML = Xml.Parser.parse_file("pies.conf");
            bool   error_occrured = false;
            
            if (piesXML != null) {

                Xml.Node* root = piesXML->get_root_element();
                if (root != null) {
                    for (Xml.Node* node = root->children; node != null; node = node->next) {
                        if (node->type == Xml.ElementType.ELEMENT_NODE) {
                            
                            string hotkey = "";
                            int    quick_action = -1;
                        
                            for (Xml.Attr* attribute = node->properties; attribute != null; attribute = attribute->next) {
                                string attr_name = attribute->name.down();
                                string attr_content = attribute->children->content;
                                
                                switch (attr_name) {
                                    case "hotkey":
                                        hotkey = attr_content;
                                        break;
                                    case "quickaction":
                                        quick_action = int.parse(attr_content);
                                        break;
                                    default:
                                        warning("Invalid setting \"" + attr_name + "\" in pies.conf!");
                                        break;
                                }
                            }
                            
                            var pie = new Pie(quick_action);
                            
                            for (Xml.Node* slice = node->children; slice != null; slice = slice->next) {
                                if (slice->type == Xml.ElementType.ELEMENT_NODE) {
                                    string name="";
                                    string icon="";
                                    string command="";
                                    string type="";
                                    
                                    for (Xml.Attr* attribute = slice->properties; attribute != null; attribute = attribute->next) {
                                        string attr_name = attribute->name.down();
                                        string attr_content = attribute->children->content;

                                        switch (attr_name) {
                                            case "name":
                                                name = attr_content;
                                                break;
                                            case "icon":
                                                icon = attr_content;
                                                break;
                                            case "command":
                                                command = attr_content;
                                                break;
                                            case "type":
                                                type = attr_content;
                                                break;
                                            default:
                                                warning("Invalid setting \"" + attr_name + "\" in pies.conf!");
                                                break;
                                        }
                                    }
                                    
                                    Action action=null;
                                    
                                    switch (type) {
                                        case "app":
                                            action = new AppAction(name, icon, command);
                                            break;
                                        case "key":
                                            action = new KeyAction(name, icon, command);
                                            break;
                                        default:
                                            warning("Invalid type \"" + type + "\" in pies.conf!");
                                            break;
                                    }
                                    
                                    if (action != null) pie.add_slice(action);
                                }
                            }
        
                            var window = new PieWindow(pie, hotkey);
                            pie.on_hide.connect((t) => {window.hide();});
                            
                        }
                    }
                   
                    Xml.Parser.cleanup();
                    
                } else {
                    warning("Error loading pies: pies.conf is empty! The cake is a lie...");
                    error_occrured = true;
                }
                
                delete piesXML;
                
            } else {
                warning("Error loading pies: pies.conf not found! The cake is a lie...");
                error_occrured = true;
            }
        }
    }
}
