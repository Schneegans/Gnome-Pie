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
/// This class provides functions to check whether an archive contains a
/// valid Gnome-Pie theme.
/////////////////////////////////////////////////////////////////////////

public class ThemeImporter : ArchiveReader {

    public bool     is_valid_theme;
    public string   theme_name;

    /////////////////////////////////////////////////////////////////////
    /// Returns
    /////////////////////////////////////////////////////////////////////

    public new bool open(string path) {

        this.is_valid_theme = false;
        this.theme_name = "";

        var tmp_reader = new ArchiveReader();

        if (tmp_reader.open(path)) {
            try {
                var tmp_dir = GLib.DirUtils.make_tmp("gnomepieXXXXXX");
                if (tmp_reader.extract_to(tmp_dir)) {
                    var tmp_theme = new Theme(tmp_dir);
                    if (tmp_theme.load()) {
                        is_valid_theme = true;
                        theme_name = tmp_theme.name;
                    }
                }
            } catch (Error e) {
                warning(e.message);
            }
        }

        tmp_reader.close();

        return base.open(path);
    }
}

}
