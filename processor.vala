/*
 * processor.vala
 *
 * Copyright 2014 Jott <das.jott at gmail com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */


public class Processor : GLib.Object
{
  public bool run(CmdArgs c)
  {
    bool ok = false;

    try {
      if (c.Verbose) { stdout.printf("Parsing vala file..."); }
      var oValaFile = new ValaFile(c.VFile);
      Class oClass = oValaFile.parse(c.VClass);
      if (oClass != null) {

        if (c.Verbose) { stdout.printf("ok!\nCreating Java file..."); }
        var oJavaFile = new JavaFile(c.LibName);
        ok = oJavaFile.create(oClass, c.Package, c.PkgDir);
        if (ok && c.Verbose) { stdout.printf("ok :)\n"); }

        JNIFiles oJniFiles = null;
        if (ok) {
          if (c.Verbose) { stdout.printf("Creating JNI header..."); }
          oJniFiles = new JNIFiles(oClass, c.Package);
          ok = oJniFiles.createHeader();
          if (ok && c.Verbose) { stdout.printf("ok :)\n"); }
        }
        if (ok) {
          if (c.Verbose) { stdout.printf("Creating JNI implementation..."); }
          ok = oJniFiles.createImplementation();
          if (ok && c.Verbose) { stdout.printf("ok :)\n"); }
        }

        if (ok) {
          if (c.Verbose) { stdout.printf("Make C code from Vala code..."); }
          string sValaFiles = oValaFile.getPath() + "*.vala";
          ok = ValaFile.compile2Ccode(sValaFiles, c.VPackages);
          if (ok && c.Verbose) { stdout.printf("ok :)\n"); }
        }

        if (ok) {
          if (c.Verbose) { stdout.printf("Connect Vala and Java..."); }
          ok = oValaFile.compile2C(c.VPackages);
          if (ok && c.Verbose) { stdout.printf("ok :)\n"); }
        }

        if (ok) {
          if (c.Verbose) { stdout.printf("Compiling sources..."); }
          var oGcc = new Compiler(oValaFile.getPath());
          ok = oGcc.compile(c.VPackages);
          if (ok && c.Verbose) { stdout.printf("ok :)\n"); }

          if (!c.NotLink) {
            if (c.Verbose) { stdout.printf("Link objects to \"lib%s.so\"...", c.LibName); }
            ok = oGcc.link(c.LibName, c.VPackages);
            if (ok && c.Verbose) { stdout.printf("ok :)\n"); }
          }
        }

        if (ok && c.UseTmp) {
          if (c.Verbose) { stdout.printf("Copying results from tmp..."); }

          var oLibSrc = File.new_for_path( Path.build_path(oValaFile.getPath(), c.LibName) );
          var oLibDst = File.new_for_path( Path.build_path(".", c.LibName) );
          oLibSrc.copy(oLibDst, FileCopyFlags.OVERWRITE);

          if (ok && c.Verbose) { stdout.printf("ok :)\n"); }
        }

        if (!ok) {
          if (c.Verbose) { stdout.printf("not ok :(\n"); }
        } else {
          stdout.printf("\nFinished successfully :)\n");
        }
      } else {
        stderr.printf("Error retrieving class information\n");
      }
    } catch (Error e) {
      stderr.printf("\nERROR:\n%s\n", e.message);
      ok = false;
    }

    return ok;
  }

}

