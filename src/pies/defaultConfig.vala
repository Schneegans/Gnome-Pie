/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2017 by Simon Schneegans
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
/// A helper class which creates a user-specific default configuration.
/////////////////////////////////////////////////////////////////////////

namespace Pies {

    public void create_default_config() {

        // add a pie with playback controls
        var multimedia = PieManager.create_persistent_pie(_("Multimedia"), "media-playback-start", new Trigger.from_string("<Control><Alt>m"));
            multimedia.add_action(new KeyAction(_("Next Track"), "media-skip-forward", "XF86AudioNext", true));
            multimedia.add_action(new KeyAction(_("Stop"), "media-playback-stop", "XF86AudioStop"));
            multimedia.add_action(new KeyAction(_("Previous Track"), "media-skip-backward", "XF86AudioPrev"));
            multimedia.add_action(new KeyAction(_("Play/Pause"), "media-playback-start", "XF86AudioPlay"));

        // add a pie with the users default applications
        var apps = PieManager.create_persistent_pie(_("Applications"), "applications-accessories", new Trigger.from_string("<Control><Alt>a"));
            apps.add_action(ActionRegistry.default_for_mime_type("text/plain"));
            apps.add_action(ActionRegistry.default_for_mime_type("audio/ogg"));
            apps.add_action(ActionRegistry.default_for_mime_type("video/ogg"));
            apps.add_action(ActionRegistry.default_for_mime_type("image/jpg"));
            apps.add_action(ActionRegistry.default_for_uri("http"));
            apps.add_action(ActionRegistry.default_for_uri("mailto"));

        // add a pie with the users bookmarks and devices
        var bookmarks = PieManager.create_persistent_pie(_("Bookmarks"), "user-bookmarks", new Trigger.from_string("<Control><Alt>b"));
            bookmarks.add_group(new BookmarkGroup(bookmarks.id));
            bookmarks.add_group(new DevicesGroup(bookmarks.id));

        // add a pie with session controls
        var session = PieManager.create_persistent_pie(_("Session"), "system-log-out", new Trigger.from_string("<Control><Alt>q"));
            session.add_group(new SessionGroup(session.id));

        // add a pie with a main menu
        var menu = PieManager.create_persistent_pie(_("Main Menu"), "start-here", new Trigger.from_string("<Control><Alt>space"));
            menu.add_group(new MenuGroup(menu.id));

        // add a pie with window controls
        var window = PieManager.create_persistent_pie(_("Window"), "preferences-system-windows", new Trigger.from_string("<Control><Alt>w"));
            window.add_action(new KeyAction(_("Scale"), "go-top", "<Control><Alt>s"));
            window.add_action(new KeyAction(_("Minimize"), "go-bottom", "<Alt>F9", true));
            window.add_action(new KeyAction(_("Close"), "window-close", "<Alt>F4"));
            window.add_action(new KeyAction(_("Maximize"), "view-fullscreen", "<Alt>F10"));
            window.add_action(new KeyAction(_("Restore"), "view-restore", "<Alt>F5"));

        // add a pie with window list group
        if (GLib.Environment.get_variable("XDG_SESSION_TYPE") != "wayland") {
            var alt_tab = PieManager.create_persistent_pie("Alt Tab", "preferences-system-windows", new Trigger.from_string("<Control><Alt>T"));
            alt_tab.add_group(new WindowListGroup(alt_tab.id));
        }

        // save the configuration to file
        Pies.save();
    }
}

}
