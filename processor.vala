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
      var oValaFile = new ValaFile(c.VFile);
      Class oClass = oValaFile.parse(c.VClass);
      if (oClass != null) {
        var oJavaFile = new JavaFile(c.LibName);
        ok = oJavaFile.create(oClass, c.Package, c.PkgDir);
        JNIFiles oJniFiles = null;
        if (ok) {
          oJniFiles = new JNIFiles(oClass, c.Package);
          ok = oJniFiles.createHeader();
        }
        if (ok) {
          ok = oJniFiles.createImplementation();
        }
        if (ok) {
          // we need to be more specific here
          //oValaFile.compile2C(oClass);
        }
      } else {
        stdout.printf("Ooops, class is null!\n");
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
      ok = false;
    }

    return ok;
  }
}

