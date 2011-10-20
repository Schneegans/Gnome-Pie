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

/////////////////////////////////////////////////////////////////////
/// This group displays a list of all running application windows.
/////////////////////////////////////////////////////////////////////

public class WindowListGroup : ActionGroup {
    
    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in 
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////
    
    public static void register(out string name, out string icon, out string settings_name) {
        name = _("Window List");
        icon = "harddrive";
        settings_name = "window_list";
    }

    /////////////////////////////////////////////////////////////////////
    /// Two members needed to avoid useless, frequent changes of the 
    /// stored Actions.
    /////////////////////////////////////////////////////////////////////

    private bool changing = false;
    private bool changed_again = false;
    
    
    private Bamf.Matcher applications;
    
    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members.
    /////////////////////////////////////////////////////////////////////
    
    public WindowListGroup(string parent_id) {
        GLib.Object(parent_id : parent_id);
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads all windows.
    /////////////////////////////////////////////////////////////////////
    
    construct {
        this.applications = Bamf.Matcher.get_default();
        
        this.applications.view_opened.connect(reload);
        this.applications.view_closed.connect(reload);
        
        this.load();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads all currently opened windows and creates actions for them.
    /////////////////////////////////////////////////////////////////////
    
    private void load() {
        unowned GLib.List<Bamf.Window?> windows = this.applications.get_windows();

        foreach (var window in windows) {
            if (window.get_window_type() == Bamf.WindowType.NORMAL) {
                var application = this.applications.get_application_for_window(window);
                
                string name = window.get_name();
                
                if (name.length > 30)
                    name = name.substring(0, 30) + "...";
                
                var action = new SigAction(
                    name,
                    application.get_icon(),
                    "%lu".printf(window.get_xid()) 
                );
                action.activated.connect(() => {
                    Wnck.Screen.get_default().force_update();
                
                    var xid = (X.Window)uint64.parse(action.real_command);
                    var win = Wnck.Window.get(xid);
                    var time = Gtk.get_current_event_time(); 
                    
                    if (win.get_workspace() != null 
                        && win.get_workspace() != win.get_screen().get_active_workspace()) 
				        win.get_workspace().activate(time);
			
			        if (win.is_minimized()) 
				        win.unminimize(time);
			
			        win.activate_transient(time);
                });
                this.add_action(action);
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Reloads all running applications.
    /////////////////////////////////////////////////////////////////////
    
    private void reload() {
        // avoid too frequent changes...
        if (!this.changing) {
            this.changing = true;
            Timeout.add(200, () => {
                if (this.changed_again) {
                    this.changed_again = false;
                    return true;
                }

                // reload
                this.delete_all();
                this.load();
                
                this.changing = false;
                return false;
            });
        } else {
            this.changed_again = true;
        }    
    }
}

}
