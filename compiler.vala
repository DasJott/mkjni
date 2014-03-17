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


public class Compiler
{
  private string m_sCompiler = null;
  private string m_sWorkingDir = null;

  public Compiler(string sCompiler, string sWorkDir)
  {
    m_sCompiler = sCompiler;
    m_sWorkingDir = sWorkDir;
  }

  public bool compile(string[] pkgs)
  {
    // never change these command lines!
    string sPkgConfig;
    bool ok = cmd( "pkg-config --cflags glib-2.0 gobject-2.0%s".printf(getPackages(pkgs)), out sPkgConfig);
    if (ok) {
      ok = cmd( "%s -fPIC -c %s -I%s *.c".printf(m_sCompiler, sPkgConfig, JniHeaderPath) );
    }
    return ok;
  }

  public bool link(string sLibName, string[] pkgs)
  {
    // never change these command lines!
    string sPkgConfig;
    bool ok = cmd( "pkg-config --libs --static glib-2.0 gobject-2.0%s".printf(getPackages(pkgs)), out sPkgConfig);
    if (ok) {
      ok = cmd( "%s -w -shared -o lib%s.so *.o %s".printf(m_sCompiler, sLibName, sPkgConfig) );
    }
    return ok;
  }

  public bool make(string sLibName, string[] pkgs)
  {
    string sPkgConfig;
    bool ok = cmd( "pkg-config --cflags --libs --static glib-2.0 gobject-2.0%s".printf(getPackages(pkgs)), out sPkgConfig );
    if (ok) {
      ok = cmd( "%s -fPIC -shared -o lib%s.so %s -I%s *.c".printf(m_sCompiler, sLibName, sPkgConfig, JniHeaderPath) );
    } return ok;
  }

  public bool clean()
  {
    //return cmd( "rm -f *.o lib%s.so".printf(LibName) );
    return false;
  }

  // gets packages string
  private string getPackages(string[] pkgs)
  {
    string res = "";
    foreach (string pkg in pkgs) {
      res += " ";
      res += pkg;
    }
    return res;
  }

  // gets the path to jni.h
  private string JniHeaderPath
  {
    get {
      if (m_jni_header_path == "") {
        string sFind;
        // TODO: Make this OS independent
        if ( cmd("find /usr/lib -name \"jni.h\"", out sFind) ) {
          string[] asPaths = sFind.split("\n");
          foreach (string sPath in asPaths) {
            if (sPath.has_suffix("/jni.h")) {
              m_jni_header_path = Path.get_dirname(sPath);
              break;
            }
          }
        }
        if (m_jni_header_path == "") {
          stderr.printf("error: could not find jni.h\n");
        }
      }
      return m_jni_header_path;
    }
  }
  private string m_jni_header_path = "";

  private bool cmd(string sCmd, out string sStdOut=null)
  {
    var shell = new Sys();
    bool ok = shell.spawn_cmd(m_sWorkingDir, sCmd);
    sStdOut = shell.StdOut;
    return ok;
  }
}

