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
      if (c.Verbose) { verbose("Getting vala class..."); }
      Class oClass = null;
      ValaFile oValaFile = null;
      foreach (string sVFile in c.VFiles) {
        ValaFile oTmpFile = new ValaFile(sVFile);
        if (!oTmpFile.isVapi()) {
          Class oTmpClass = oTmpFile.parse(c.VClass);
          if (oTmpClass != null) {
            oClass = oTmpClass;
            oValaFile = oTmpFile;
            break;
          }
        }
      }

      if (oClass != null) {
        if (c.Verbose) { verbose("ok :)\nCreating Java file..."); }
        var oJavaFile = new JavaFile(c.LibName);
        ok = oJavaFile.create(oClass, c.Package, c.PkgDir);
        if (ok && c.Verbose) { verbose("ok :)\n"); }

        JNIFiles oJniFiles = null;
        if (ok) {
          if (c.Verbose) { verbose("Creating JNI header..."); }
          oJniFiles = new JNIFiles(oClass, c.Package);
          ok = oJniFiles.createHeader(oValaFile.getPath());
          if (ok && c.Verbose) { verbose("ok :)\n"); }
        }
        if (ok) {
          if (c.Verbose) { verbose("Creating JNI implementation..."); }
          ok = oJniFiles.createImplementation(oValaFile.getPath());
          if (ok && c.Verbose) { verbose("ok :)\n"); }
        }

        if (ok) {
          if (c.Verbose) { verbose("Make C code from Vala code..."); }
          ok = ValaFile.compile2Ccode(oValaFile.getPath(), c.VFiles, c.VPackages, c.ValaCmds, oValaFile.getHeaderName());
          if (ok && c.Verbose) { verbose("ok :)\n"); }
        }

        if (ok && c.Compile) {
          if (c.Verbose) { verbose("Compiling sources..."); }
          var oGcc = new Compiler(c.Compler, oValaFile.getPath());
          ok = oGcc.compile(c.VPackages, c.CompCmds);
          if (ok && c.Verbose) { verbose("ok :)\n"); }

          if (!c.NotLink) {
            if (c.Verbose) { verbose("Link objects to \"lib%s.so\"...", c.LibName); }
            ok = oGcc.link(c.LibName, c.VPackages, c.ExtLibs);
            if (ok && c.Verbose) { verbose("ok :)\n"); }
          }
        }

        if (ok && c.UseTmp && c.Compile && !c.NotLink) {
          if (c.Verbose) { verbose("Copying results from tmp..."); }

          string sLibName = "lib%s.so".printf(c.LibName);

          var oLibSrc = File.new_for_path( Path.build_filename(oValaFile.getPath(), sLibName) );
          var oLibDst = File.new_for_path( Path.build_filename(".", sLibName) );
          oLibSrc.copy(oLibDst, FileCopyFlags.OVERWRITE);

          if (ok && c.Verbose) { verbose("ok :)\n"); }
        }

        c.cleanUp(true);

        if (!ok) {
          if (c.Verbose) { verbose("not ok :(\n"); }
        } else {
          verbose("\nFinished successfully :)\n");
        }
      } else {
        stderr.printf("Error retrieving class information\n");
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
      ok = false;
    }

    return ok;
  }

  public static void verbose(string sText, ...)
  {
    string sPrint = sText.vprintf(va_list());
    print(sPrint);
  }

}

