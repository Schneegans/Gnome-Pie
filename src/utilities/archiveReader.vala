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
/// This class can be used to unpack an archive to a directory.
/////////////////////////////////////////////////////////////////////////

public class ArchiveReader : GLib.Object {

    private Archive.Read        archive;
    private Archive.WriteDisk   writer;

    /////////////////////////////////////////////////////////////////////
    /// Constructs a new ArchiveReader
    /////////////////////////////////////////////////////////////////////

    public ArchiveReader() {
        this.archive = new Archive.Read();
        this.archive.support_format_all();
        this.archive.support_filter_all();

        this.writer = new Archive.WriteDisk();
        this.writer.set_options(
            Archive.ExtractFlags.TIME |
            Archive.ExtractFlags.PERM |
            Archive.ExtractFlags.ACL |
            Archive.ExtractFlags.FFLAGS
        );
        this.writer.set_standard_lookup();
    }

    /////////////////////////////////////////////////////////////////////
    /// Call this once after you created the ArchiveReader. Pass the
    /// path to the target archive location.
    /////////////////////////////////////////////////////////////////////

    public bool open(string path) {
        return this.archive.open_filename(path, 10240) == Archive.Result.OK;
    }

    /////////////////////////////////////////////////////////////////////
    /// Extracts all files from the previously opened archive.
    /////////////////////////////////////////////////////////////////////

    public bool extract_to(string directory) {
        while (true) {
            unowned Archive.Entry entry;
            var r = this.archive.next_header(out entry);

            if (r == Archive.Result.EOF) {
                break;
            }

            if (r != Archive.Result.OK) {
                warning(this.archive.error_string());
                return false;
            }

            entry.set_pathname(directory + "/" + entry.pathname());

            r = this.writer.write_header(entry);

            if (r != Archive.Result.OK) {
                warning(this.writer.error_string());
                return false;
            }

            if (entry.size() > 0) {
                while (true) {
                    size_t offset, size;
                    void *buff;

                    r = this.archive.read_data_block(out buff, out size, out offset);
                    if (r == Archive.Result.EOF) {
                        break;
                    }

                    if (r != Archive.Result.OK) {
                        warning(this.archive.error_string());
                        return false;
                    }

                    this.writer.write_data_block(buff, size, offset);
                }
            }

            r = this.writer.finish_entry();

            if (r != Archive.Result.OK) {
                warning(this.writer.error_string());
                return false;
            }
        }
        return true;
    }

    /////////////////////////////////////////////////////////////////////
    /// When all files have been added, close the directory again.
    /////////////////////////////////////////////////////////////////////

    public void close() {
        this.archive.close();
        this.writer.close();
    }
}

}
