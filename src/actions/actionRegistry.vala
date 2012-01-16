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
/// A which has knowledge on all possible acion types.
/////////////////////////////////////////////////////////////////////////

public class ActionRegistry : GLib.Object {
    
    /////////////////////////////////////////////////////////////////////
    /// A list containing all available Action types.
    /////////////////////////////////////////////////////////////////////
    
    public static Gee.ArrayList<Type> types { get; private set; }
    
    /////////////////////////////////////////////////////////////////////
    /// Three maps associating a displayable name for each Action, 
    /// whether it has a custom icon and a name for the pies.conf
    /// file with it's type.
    /////////////////////////////////////////////////////////////////////
    
    public static Gee.HashMap<Type, TypeDescription?> descriptions { get; private set; }
    
    public class TypeDescription {
        public string name { get; set; default=""; }
        public string icon { get; set; default=""; }
        public string description { get; set; default=""; }
        public string id { get; set; default=""; }
        public bool icon_name_editable { get; set; default=false; }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Registers all Action types.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        types = new Gee.ArrayList<Type>();
        descriptions = new Gee.HashMap<Type, TypeDescription?>();
    
        TypeDescription type_description = null;
        
        AppAction.register(out type_description);
        
        if (type_description == null) debug("ysdvxdfv");
        
        types.add(typeof(AppAction));
        descriptions.set(typeof(AppAction), type_description);
        
        KeyAction.register(out type_description);
        if (type_description == null) debug("ysdvxdfv");
        types.add(typeof(KeyAction));
        descriptions.set(typeof(KeyAction), type_description);
        
        PieAction.register(out type_description);
        if (type_description == null) debug("ysdvxdfv");
        types.add(typeof(PieAction));
        descriptions.set(typeof(PieAction), type_description);
        
        UriAction.register(out type_description);
        if (type_description == null) debug("ysdvxdfv");
        types.add(typeof(UriAction));
        descriptions.set(typeof(UriAction), type_description);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an Action, appropriate for the 
    /// given URI. This can result in an UriAction or in an AppAction,
    /// depending on the Type of the URI. 
    /////////////////////////////////////////////////////////////////////

    public static Action? new_for_uri(string uri, string? name = null) {
        var file = GLib.File.new_for_uri(uri);
        var scheme = file.get_uri_scheme();
        
        string final_icon = "";
        string final_name = file.get_basename();

        switch (scheme) {
            case "application":
                var file_name = uri.split("//")[1];
                
                var desktop_file = GLib.File.new_for_path("/usr/share/applications/" + file_name);
                if (desktop_file.query_exists())
                    return new_for_desktop_file(desktop_file.get_path());

                break;
                
            case "trash":
                final_icon = "user-trash";
                final_name = _("Trash");
                break;
                
            case "http": case "https":
                final_icon = "www";
                break;
                
            case "ftp": case "sftp":
                final_icon = "folder-remote";
                break;
                
            default:
                try {
                    var info = file.query_info("*", GLib.FileQueryInfoFlags.NONE);
                    
                    if (info.get_content_type() == "application/x-desktop")
                        return new_for_desktop_file(file.get_parse_name());
                    
                    // search for an appropriate icon
                    var gicon = info.get_icon();                
                    string[] icons = gicon.to_string().split(" ");
                    
                    foreach (var icon in icons) {
                        if (Gtk.IconTheme.get_default().has_icon(icon)) {
                            final_icon = icon;
                            break;
                        }
                    }
                    
                } catch (GLib.Error e) {
                    warning(e.message);
                }

                break;
        }
        
        if (!Gtk.IconTheme.get_default().has_icon(final_icon))
                final_icon = "application-default-icon";
        
        if (name != null)
            final_name = name;
        
        return new UriAction(final_name, final_icon, uri);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given AppInfo.
    /////////////////////////////////////////////////////////////////////
    
    public static Action? new_for_app_info(GLib.AppInfo info) {        
        string[] icons = info.get_icon().to_string().split(" ");
        string final_icon = "application-default-icon";
        
        // search for available icons
        foreach (var icon in icons) {
            if (Gtk.IconTheme.get_default().has_icon(icon)) {
                final_icon = icon;
                break;
            }
        }
        
        return new AppAction(info.get_display_name() , final_icon, info.get_commandline());
    }
    
    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given *.desktop
    /// file.
    /////////////////////////////////////////////////////////////////////
    
    public static Action? new_for_desktop_file(string file_name) {
        // check whether its a desktop file to open one of Gnome-Pie's pies
        if (file_name.has_prefix(Paths.launchers)) {
            string id = file_name.substring((long)file_name.length - 11, 3);
            return new PieAction(id);
        }
        
        var info = new DesktopAppInfo.from_filename(file_name);
        return new_for_app_info(info);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given mime type.
    /////////////////////////////////////////////////////////////////////
    
    public static Action? default_for_mime_type(string type) {
        var info = AppInfo.get_default_for_type(type, false);
        return new_for_app_info(info);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// A helper method which creates an AppAction for given uri scheme.
    /////////////////////////////////////////////////////////////////////
    
    public static Action? default_for_uri(string uri) {
        var info = AppInfo.get_default_for_uri_scheme(uri);
        return new_for_app_info(info);
    }
}

}
