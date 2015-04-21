/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2015 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////

namespace GnomePie {

/////////////////////////////////////////////////////////////////////////
/// An ActionGroup which displays the user's main menu. It's a bit ugly,
/// but it supports both, an older version and libgnome-menus-3 at the
/// same time.
/////////////////////////////////////////////////////////////////////////

public class MenuGroup : ActionGroup {
    /////////////////////////////////////////////////////////////////////
    /// Used to register this type of ActionGroup. It sets the display
    /// name for this ActionGroup, it's icon name and the string used in
    /// the pies.conf file for this kind of ActionGroups.
    /////////////////////////////////////////////////////////////////////

    public static GroupRegistry.TypeDescription register() {
        var description = new GroupRegistry.TypeDescription();
        description.name = _("Group: Main menu");
        description.icon = "start-here";
        description.description = _("Displays your main menu structure.");
        description.id = "menu";
        return description;
    }

    /////////////////////////////////////////////////////////////////////
    /// True, if this MenuGroup is the top most menu.
    /////////////////////////////////////////////////////////////////////

    public bool is_toplevel {get; construct set; default = true;}

    /////////////////////////////////////////////////////////////////////
    /// The menu tree displayed by the MenuGroup. Only set for the
    /// toplevel MenuGroup.
    /////////////////////////////////////////////////////////////////////

    private GMenu.Tree menu = null;

    /////////////////////////////////////////////////////////////////////
    /// A list of all sub menus of this MenuGroup.
    /////////////////////////////////////////////////////////////////////

    private Gee.ArrayList<MenuGroup?> childs;

    /////////////////////////////////////////////////////////////////////
    /// Two members needed to avoid useless, frequent changes of the
    /// stored Actions.
    /////////////////////////////////////////////////////////////////////

    private bool changing = false;
    private bool changed_again = false;

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members. Used for the toplevel menu.
    /////////////////////////////////////////////////////////////////////

    public MenuGroup(string parent_id) {
        GLib.Object(parent_id : parent_id, is_toplevel : true);
    }

    /////////////////////////////////////////////////////////////////////
    /// C'tor, initializes all members. Used for sub menus.
    /////////////////////////////////////////////////////////////////////

    public MenuGroup.sub_menu(string parent_id) {
        GLib.Object(parent_id : parent_id, is_toplevel : false);
    }

    construct {
        this.childs = new Gee.ArrayList<MenuGroup?>();

        if (this.is_toplevel) {
            #if HAVE_GMENU_3
                this.menu = new GMenu.Tree("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
                this.menu.changed.connect(this.reload);
            #endif

            this.load_toplevel();
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Starts to load the menu.
    /////////////////////////////////////////////////////////////////////

    private void load_toplevel() {
        #if HAVE_GMENU_3
            try {
                if (this.menu.load_sync()) {
                    this.load_contents(this.menu.get_root_directory(), this.parent_id);
                }
            } catch (GLib.Error e) {
                warning(e.message);
            }
        #else
            this.menu = GMenu.Tree.lookup ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
            this.menu.add_monitor(this.reload);
            var dir = this.menu.get_root_directory();
            this.load_contents(dir, this.parent_id);
        #endif
    }

    /////////////////////////////////////////////////////////////////////
    /// Parses the main menu recursively.
    /////////////////////////////////////////////////////////////////////

    private void load_contents(GMenu.TreeDirectory dir, string parent_id) {
        #if HAVE_GMENU_3
            var item = dir.iter();

            while (true) {
                var type = item.next();
                if (type == GMenu.TreeItemType.INVALID)
                    break;

                if (type == GMenu.TreeItemType.DIRECTORY && !item.get_directory().get_is_nodisplay()) {
                    // create a MenuGroup for sub menus

                    // get icon
                    var icon = item.get_directory().get_icon();

                    var sub_menu = PieManager.create_dynamic_pie(item.get_directory().get_name(), Icon.get_icon_name(icon));
                    var group = new MenuGroup.sub_menu(sub_menu.id);
                    group.add_action(new PieAction(parent_id, true));
                    group.load_contents(item.get_directory(), sub_menu.id);
                    childs.add(group);

                    sub_menu.add_group(group);

                    this.add_action(new PieAction(sub_menu.id));

                } else if (type == GMenu.TreeItemType.ENTRY ) {
                    // create an AppAction for entries
                    if (!item.get_entry().get_is_excluded()) {
                        this.add_action(ActionRegistry.new_for_app_info(item.get_entry().get_app_info()));
                    }
                }
            }
        #else
            foreach (var item in dir.get_contents()) {
                switch(item.get_type()) {
                    case GMenu.TreeItemType.DIRECTORY:
                        // create a MenuGroup for sub menus
                        if (!((GMenu.TreeDirectory)item).get_is_nodisplay()) {
                            var sub_menu = PieManager.create_dynamic_pie(
                                                              ((GMenu.TreeDirectory)item).get_name(),
                                                              ((GMenu.TreeDirectory)item).get_icon());
                            var group = new MenuGroup.sub_menu(sub_menu.id);
                            group.add_action(new PieAction(parent_id, true));
                            group.load_contents((GMenu.TreeDirectory)item, sub_menu.id);
                            childs.add(group);

                            sub_menu.add_group(group);

                            this.add_action(new PieAction(sub_menu.id));
                        }
                        break;

                    case GMenu.TreeItemType.ENTRY:
                        // create an AppAction for entries
                        if (!((GMenu.TreeEntry)item).get_is_nodisplay() && !((GMenu.TreeEntry)item).get_is_excluded()) {
                            this.add_action(new AppAction(((GMenu.TreeEntry)item).get_name(),
                                                          ((GMenu.TreeEntry)item).get_icon(),
                                                          ((GMenu.TreeEntry)item).get_exec()));
                        }
                        break;
                }
            }
        #endif
    }

    /////////////////////////////////////////////////////////////////////
    /// Reloads the menu.
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
                message("Main menu changed...");
                #if !HAVE_GMENU_3
                    this.menu.remove_monitor(this.reload);
                #endif

                this.clear();
                this.load_toplevel();

                this.changing = false;
                return false;
            });
        } else {
            this.changed_again = true;
        }
    }

    /////////////////////////////////////////////////////////////////////
    /// Deletes all generated Pies, when the toplevel menu is deleted.
    /////////////////////////////////////////////////////////////////////

    public override void on_remove() {
        if (this.is_toplevel)
            this.clear();
    }

    /////////////////////////////////////////////////////////////////////
    /// Clears this ActionGroup recursively.
    /////////////////////////////////////////////////////////////////////

    private void clear() {
        foreach (var child in childs)
            child.clear();

        if (!this.is_toplevel)
            PieManager.remove_pie(this.parent_id);

        this.delete_all();

        this.childs.clear();

        #if !HAVE_GMENU_3
            this.menu = null;
        #endif

    }
}

}
