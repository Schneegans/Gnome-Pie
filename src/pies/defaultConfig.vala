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
