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
/// A simple about dialog.
/////////////////////////////////////////////////////////////////////////

public class AboutWindow: Gtk.AboutDialog {

    /////////////////////////////////////////////////////////////////////
    /// C'tor, creates a new about dialog. The entries are sorted alpha-
    /// betically.
    /////////////////////////////////////////////////////////////////////

    public AboutWindow () {
        string[] devs = {
            "Simon Schneegans <code@simonschneegans.de>",
            "Gabriel Dubatti <gdubatti@gmail.com>",
            "Glitsj16 <glitsj16@riseup.net>",
            "Francesco Piccinno <stack.box@gmail.com>",
            "György Balló <ballogyor@gmail.com>",
            "Tiago de Oliveira Corrêa <tcorreabr@gmail.com>"
        };
        string[] artists = {
            "Simon Schneegans <code@simonschneegans.de>"
        };
        string[] translators = {
            "Simon Schneegans <code@simonschneegans.de> (DE, EN)",
            "Riccardo Traverso <gr3yfox.fw@gmail.com> (IT)",
            "Magnun Leno <magnun@codecommunity.org> (PT-BR)",
            "Kim Boram <Boramism@gmail.com> (KO)",
            "Eduardo Anabalon <lalo1412@gmail.com> (ES)",
            "Moo <hazap@hotmail.com> (LT)",
            "Gabriel Dubatti <gdubatti@gmail.com> (ES)",
            "Grégoire Bellon-Gervais <greggbg@gmail.com> (FR)",
            "Raphaël Rochet <raphael@rri.fr> (FR)",
            "Alex Maxime <cad.maxime@gmail.com> (FR)",
            "Eugene Roskin <pams@imail.ru> (RU)",
            "Ashed <craysy@gmail.com> (RU)",
            "Ting Zhou <tzhou@haverford.edu> (ZH-CN)",
            "Martin Dinov <martindinov@yahoo.com> (BG)",
            "Heimen Stoffels <vistausss@outlook.com> (NL-NL)"
        };

        // sort translators
        GLib.List<string> translator_list = new GLib.List<string>();
        foreach (var translator in translators)
            translator_list.append(translator);

        translator_list.sort((a, b) => {
            return a.ascii_casecmp(b);
        });

        string translator_string = "";
        foreach (var translator in translator_list)
               translator_string += translator + "\n";

        GLib.Object (
            artists : artists,
            authors : devs,
            translator_credits : translator_string,
            copyright : "Copyright 2011-2018 Simon Schneegans <code@simonschneegans.de>",
            program_name: "Gnome-Pie",
            logo_icon_name: "gnome-pie",
            website: "http://simmesimme.github.io/gnome-pie.html",
            website_label: "Homepage",
            version: Daemon.version
        );
    }
}

}
