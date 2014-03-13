/*
 * compiler.vala
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


public class Compiler : GLib.Object
{
  private List<string> m_oPackages = null;

  public Compiler(string sLibName, List<string> pkgs)
  {
    LibName = sLibName;
    m_oPackages = pkgs.copy();
  }

  public bool compile()
  {
    return cmd( "gcc -c -fPIC $(pkg-config --cflags glib-2.0%s) -I%s *.c".printf(Packages, JniHeaderPath) );
  }

  public bool link()
  {
    return cmd( "gcc -w -shared -o lib%s.so *.o $(pkg-config --libs --static glib-2.0%s)".printf(LibName, Packages) );
  }

  public bool make()
  {
    return cmd( "gcc -fPIC -shared -o lib%s.so $(pkg-config --cflags --libs --static glib-2.0%s) -I%s *.c".printf(LibName, Packages, JniHeaderPath) );
  }

  private string LibName { get; private set; }

  // gets packages string
  private string Packages
  {
    owned get {
      string res = "";
      m_oPackages.foreach( (pkg) => {
        res += " ";
        res += pkg;
      });
      return res;
    }
  }

  // gets the path to jni.h
  private string JniHeaderPath
  {
    get {
      if (m_jni_header_path == "") {
        string sFind;
        if ( cmd("find /usr/lib -name \"jni.h\"", out sFind) ) {
          string[] asPaths = sFind.split("\n");
          foreach (string sPath in asPaths) {
            if (sPath.has_suffix("/jni.h")) {
              int nPos = sPath.last_index_of("/");
              if (nPos > 0) {
                m_jni_header_path = sPath.slice(0, nPos);
                break;
              }
            }
          }
        }
      }
      return m_jni_header_path;
    }
  }
  private string m_jni_header_path = "";

  private bool cmd(string sCmd, out string sStdOut=null)
  {
    string sStdErr; int nErr = 0;
    try {
      bool ok = Process.spawn_command_line_sync(sCmd, out sStdOut, out sStdErr, out nErr);

      if (nErr != 0) {
        stderr.printf("%s\n", sStdErr);
      } else {
        return ok;
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }
    return false;
  }
}

