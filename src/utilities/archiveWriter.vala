/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
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
                uint8 buffer[4096];

                var len = reader.read(buffer);

                while(len > 0) {
                    this.archive.write_data(buffer, len);
                    len = reader.read(buffer);
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
