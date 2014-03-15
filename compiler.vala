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
  private string m_sWorkingDir = null;

  public Compiler(string sWorkDir)
  {
    m_sWorkingDir = sWorkDir;
  }

  public bool compile(List<string> pkgs)
  {
    return cmd( "gcc -c -fPIC $(pkg-config --cflags glib-2.0%s) -I%s *.c".printf(getPackages(pkgs), JniHeaderPath) );
  }

  public bool link(string sLibName, List<string> pkgs)
  {
    return cmd( "gcc -w -shared -o lib%s.so *.o $(pkg-config --libs --static glib-2.0%s)".printf(LibName, getPackages(pkgs)) );
  }

  public bool make(string sLibName, List<string> pkgs)
  {
    return cmd( "gcc -fPIC -shared -o lib%s.so $(pkg-config --cflags --libs --static glib-2.0%s) -I%s *.c".printf(LibName, getPackages(pkgs), JniHeaderPath) );
  }

  public bool clean()
  {
    return cmd( "rm -f *.o lib%s.so".printf(LibName) );
  }

  private string LibName { get; private set; }

  // gets packages string
  private string getPackages(List<string> pkgs)
  {
    string res = "";
    pkgs.foreach( (pkg) => {
      res += " ";
      res += pkg;
    });
    return res;
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
              m_jni_header_path = Path.get_dirname(sPath);
              break;
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
      string[] argv;
      bool ok = Shell.parse_argv(sCmd, out argv);
      if (ok) {
        ok = Process.spawn_sync(m_sWorkingDir, argv, null, SpawnFlags.SEARCH_PATH, null, out sStdOut, out sStdErr, out nErr);

        if (nErr != 0) {
          stderr.printf("%s\n", sStdErr);
        } else {
          return ok;
        }
      } else {
        stderr.printf("Error parsing command line\n");
      }

    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }
    return false;
  }
}

