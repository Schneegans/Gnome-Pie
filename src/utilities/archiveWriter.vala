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
/// This class can be used to pack a directory of files recursively into
/// a *.tar.gz archive.
/////////////////////////////////////////////////////////////////////////

public class ArchiveWriter : GLib.Object {

    private Archive.Write archive;

    /////////////////////////////////////////////////////////////////////
    /// Constructs a new ArchiveWriter
    /////////////////////////////////////////////////////////////////////

    public ArchiveWriter() {
        this.archive = new Archive.Write();
        this.archive.add_filter_gzip();
        this.archive.set_format_pax_restricted();

    }

    /////////////////////////////////////////////////////////////////////
    /// Call this once after you created the ArchiveWriter. Pass the
    /// path to the target archive location.
    /////////////////////////////////////////////////////////////////////

    public bool open(string path) {
        return this.archive.open_filename(path) == Archive.Result.OK;
    }

    /////////////////////////////////////////////////////////////////////
    /// Adds all files of a given directory to the previously opened
    /// archive.
    /////////////////////////////////////////////////////////////////////

    public bool add(string directory) {
        return add_directory(directory, directory);
    }

    /////////////////////////////////////////////////////////////////////
    /// When all files have been added, close the directory again.
    /////////////////////////////////////////////////////////////////////

    public void close() {
        this.archive.close();
    }

    /////////////////////////////////////////////////////////////////////
    /// Private helper function which traveres a directory recursively.
    /////////////////////////////////////////////////////////////////////

    private bool add_directory(string directory, string relative_to) {
        try {
            var d = Dir.open(directory);
            string name;
            while ((name = d.read_name()) != null) {
                string path = Path.build_filename(directory, name);
                if (FileUtils.test(path, FileTest.IS_DIR)) {
                    if (!add_directory(path, relative_to)) {
                        return false;
                    }

                } else if (FileUtils.test(path, FileTest.IS_REGULAR)) {
                    if (!add_file(path, relative_to)) {
                        return false;
                    }

                } else {
                    warning("Packaging theme: Ignoring irregular file " + name);
                }
            }
        } catch (Error e) {
            warning (e.message);
            return false;
        }

        return true;

    }

    /////////////////////////////////////////////////////////////////////
    /// Private halper which adds a file to the archive.
    /////////////////////////////////////////////////////////////////////

    public bool add_file(string path, string relative_to) {
        var entry = new Archive.Entry();
        entry.set_pathname(path.replace(relative_to, ""));

        Posix.Stat st;
        Posix.stat(path, out st);
        entry.copy_stat(st);
        entry.set_size(st.st_size);

        if (this.archive.write_header(entry) == Archive.Result.OK) {
            try {
                var reader = File.new_for_path(path).read();
                uint8[] buffer = new uint8[4096];

                buffer.length = (int) reader.read(buffer);

                while(buffer.length > 0) {
#if VALA_0_42
                    this.archive.write_data(buffer);
#else
                    this.archive.write_data(buffer, buffer.length);
#endif
                    buffer.length = (int) reader.read(buffer);
                }

                this.archive.finish_entry();
            } catch (Error e) {
                warning (e.message);
                return false;
            }

        } else {
            warning("Failed to include file " + path + " into archive");
            return false;
        }

        return true;
    }
}

}
