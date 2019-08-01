/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2019 Simon Schneegans
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
