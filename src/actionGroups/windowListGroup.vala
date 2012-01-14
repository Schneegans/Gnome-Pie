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
    
    public static void register(out GroupRegistry.TypeDescription description) {
        description = GroupRegistry.TypeDescription();
        description.name = _("Group: Window List");
        description.icon = "window-manager";
        description.description = _("Shows a Slice for each of your opened Windows. Almost like Alt-Tab.");
        description.id = "window_list";
    }

    /////////////////////////////////////////////////////////////////////
    /// Two members needed to avoid useless, frequent changes of the 
    /// stored Actions.
    /////////////////////////////////////////////////////////////////////

    private bool changing = false;
    private bool changed_again = false;
    
    private Wnck.Screen screen;
    
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
        this.screen = Wnck.Screen.get_default();
    
        this.screen.window_opened.connect(reload);
        this.screen.window_closed.connect(reload);
        
        this.load();
    }
    
    /////////////////////////////////////////////////////////////////////
    /// Loads all currently opened windows and creates actions for them.
    /////////////////////////////////////////////////////////////////////
    
    private void load() {
        unowned GLib.List<Wnck.Window?> windows = this.screen.get_windows();
        
        var matcher = Bamf.Matcher.get_default();

        foreach (var window in windows) {
            if (window.get_window_type() == Wnck.WindowType.NORMAL
            	&& !window.is_skip_pager() && !window.is_skip_tasklist()) {
                var application = window.get_application();
                var bamf_app = matcher.get_application_for_xid((uint32)window.get_xid());
                
                string name = window.get_name();
                
                if (name.length > 30)
                    name = name.substring(0, 30) + "...";
                
                var action = new SigAction(
                    name,
                    (bamf_app == null) ? application.get_icon_name().down() : bamf_app.get_icon(),
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
            Timeout.add(500, () => {
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
