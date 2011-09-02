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
    
    public static Gee.ArrayList<Type> types {get; private set;}
    
    
    /////////////////////////////////////////////////////////////////////
    /// Three maps associating a displayable name for each Action, 
    /// whether it has a custom icon and a name for the pies.conf
    /// file with it's type.
    /////////////////////////////////////////////////////////////////////
    
    public static Gee.HashMap<Type, string> names {get; private set;}
    public static Gee.HashMap<Type, bool> icon_name_editables {get; private set;}
    public static Gee.HashMap<Type, string> settings_names {get; private set;}
    
    
    /////////////////////////////////////////////////////////////////////
    /// Registers all Action types.
    /////////////////////////////////////////////////////////////////////
    
    public static void init() {
        types = new Gee.ArrayList<Type>();
    
        names = new Gee.HashMap<Type, string>();
        icon_name_editables = new Gee.HashMap<Type, bool>();
        settings_names = new Gee.HashMap<Type, string>();
    
        string name = "";
        bool icon_name_editable = true;
        string settings_name = "";
        
        AppAction.register(out name, out icon_name_editable, out settings_name);
        types.add(typeof(AppAction));
        names.set(typeof(AppAction), name);
        icon_name_editables.set(typeof(AppAction), icon_name_editable);
        settings_names.set(typeof(AppAction), settings_name);
        
        KeyAction.register(out name, out icon_name_editable, out settings_name);
        types.add(typeof(KeyAction));
        names.set(typeof(KeyAction), name);
        icon_name_editables.set(typeof(KeyAction), icon_name_editable);
        settings_names.set(typeof(KeyAction), settings_name);
        
        PieAction.register(out name, out icon_name_editable, out settings_name);
        types.add(typeof(PieAction));
        names.set(typeof(PieAction), name);
        icon_name_editables.set(typeof(PieAction), icon_name_editable);
        settings_names.set(typeof(PieAction), settings_name);
        
        UriAction.register(out name, out icon_name_editable, out settings_name);
        types.add(typeof(UriAction));
        names.set(typeof(UriAction), name);
        icon_name_editables.set(typeof(UriAction), icon_name_editable);
        settings_names.set(typeof(UriAction), settings_name);
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
    /// A helper method which creates an AppAction for given *.desktop
    /// file.
    /////////////////////////////////////////////////////////////////////
    
    public static Action? new_for_desktop_file(string file_name) {
        var file = new DesktopAppInfo.from_filename(file_name);
        
        string[] icons = file.get_icon().to_string().split(" ");
        string final_icon = "application-default-icon";
        
        // search for available icons
        foreach (var icon in icons) {
            if (Gtk.IconTheme.get_default().has_icon(icon)) {
                final_icon = icon;
                break;
            }
        }
        
        return new AppAction(file.get_display_name() , final_icon, file.get_commandline());
    }
}

}
