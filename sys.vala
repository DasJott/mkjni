/*
 * sys.vala
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


public class Sys : GLib.Object
{
  public string StdOut    { private set; get; default=""; }
  public string StdError  { private set; get; default=""; }
  public int    ErrorCode { private set; get; default=0;  }

  private string[] m_environment = null;

  public Sys(string[]? Environment=null)
  {
    if (Environment != null) {
      m_environment = Environment;
    } else {
      m_environment = Environ.get();
    }
  }

  public bool spawn_cmd(string sDir, string sCmd)
  {
    try {
      string[] argv;
      bool ok = parseCommand(sDir, sCmd, out argv);

      if (ok) {
        string sStdOut, sStdError; int nErrorCode;
        ok = Process.spawn_sync(sDir, argv, m_environment, SpawnFlags.SEARCH_PATH, null, out sStdOut, out sStdError, out nErrorCode);

        StdOut    = sStdOut;
        StdError  = sStdError;
        ErrorCode = nErrorCode;

        if (ErrorCode != 0) {
          stderr.printf("%s\n", StdError);
        } else {
          return ok;
        }
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }
    return false;
  }

  public bool parseCommand(string sDir, string sCmd, out string[] asArgs)
  {
    bool ok = false;

    string[] asTmpArgs = {};

    try {
      string[] argv;

      // TODO: parse $( foo ) pieces

      ok = Shell.parse_argv(sCmd, out argv);

      if (ok) {
        int i=0;
        var regWildcard = new Regex("^([^\\*]*)(\\*+)(.*)$");
        foreach (unowned string arg in argv) {
          MatchInfo info;
          if (regWildcard.match(arg, 0, out info)) {
            string[] asFiles = evalWildcard(sDir, info.fetch(1), info.fetch(3));
            foreach (string sFile in asFiles) {
              asTmpArgs += sFile;
            }
          } else {
            asTmpArgs += arg;
          }
          ++i;
        }
      }
      asArgs = asTmpArgs;
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
      asArgs = {};
    }

    return ok;
  }

  public string[] evalWildcard(string sDir, string prefix, string suffix)
  {
    string[] asFiles = {};

    var oDir = File.new_for_path(sDir);
    try {
      FileEnumerator e = oDir.enumerate_children(GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE);

      FileInfo info = null;
      while ( (info = e.next_file()) != null ) {
        string sFile = info.get_name();
        if (sFile.has_prefix(prefix) && sFile.has_suffix(suffix)) {
          asFiles += sFile;
        }
      }

    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }

    return asFiles;
  }
}

