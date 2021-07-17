/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2021 Simon Schneegans
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

#if VALA_0_42
                    uint8[] buff;
                    r = this.archive.read_data_block(out buff, out offset);
#else
                    void* buff;
                    r = this.archive.read_data_block(out buff, out size, out offset);
#endif
                    if (r == Archive.Result.EOF) {
                        break;
                    }

                    if (r != Archive.Result.OK) {
                        warning(this.archive.error_string());
                        return false;
                    }

#if VALA_0_42
                    this.writer.write_data_block(buff, offset);
#else
                    this.writer.write_data_block(buff, size, offset);
#endif
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
