/*
 * cmdargs.vala
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


public class CmdArgs : GLib.Object
{
  private string m_sTmpDir = null;

  public string AppName { private set; get; default="";    }
  public string VFile   { private set; get; default="";    } // -f --file
  public string VClass  { private set; get; default="";    } // -c --class
  public string Package { private set; get; default="";    } // -j --jns
  public string LibName { private set; get; default="";    } // -l --lib
  public bool   PkgDir  { private set; get; default=false; } // -d
  public bool   Verbose { private set; get; default=false; } // -v
  public bool   NotLink { private set; get; default=false; } // -o
  public bool   UseTmp  { private set; get; default=false; } // -t

  public List<string> VPackages = new List<string>();        // -p --pkg

  private CmdArgs() {}

  public static CmdArgs? parse(string[] args)
  {
    var oCmd = new CmdArgs();
    if ( oCmd.parsePrivate(args) ) {
      return oCmd;
    }
    return null;
  }

  private bool parsePrivate(string[] args)
  {
    {
      string sApp = args[0];
      int nPos = sApp.last_index_of("/");
      AppName = sApp.substring(nPos+1);
    }

    string opt = null;

    for (int i=1; i<args.length; ++i) {
      if (opt != null) {
        switch (opt) {
          case "f": VFile   = args[i]; break;
          case "c": VClass  = args[i]; break;
          case "j": Package = args[i]; break;
          case "l": LibName = args[i]; break;
          case "p":
            VPackages.append( args[i] );
            break;
        }
        opt = null;
      } else {
        switch (args[i]) {
          case "-f":
          case "--file":
            opt = "f";
            break;
          case "-c":
          case "--class":
            opt = "c";
            break;
          case "-j":
          case "--jns":
            opt = "j";
            break;
          case "-l":
          case "--lib":
            opt = "l";
            break;
          case "-p":
          case "--pkg":
            opt = "p";
            break;
          case "-d":
            PkgDir = true;
            break;
          case "-v":
            Verbose = true;
            break;
          case "-o":
            NotLink = true;
            break;
          case "-t":
            UseTmp = true;
            break;
          case "?":
          case "-?":
          case "-h":
          case "--help":
            printHelp();
            return false;
          default:
            stderr.printf("Unknown option %s\n", args[i]);
            printHelp();
            return false;
        }
      }
    }

    if (checkArgs()) {
      if (UseTmp) {
        if (!prepareTmp()) {
          return false;
        }
      }
      return true;
    }
    printHelp();
    return false;
  }

  private bool checkArgs()
  {
    if (
         AppName != ""
      && VFile   != ""
      && VClass  != ""
      && LibName != ""
    ) {
      return true;
    }
    stderr.printf("Too less parameters!\n");
    return false;
  }

  private bool prepareTmp()
  {
    try {
      if (Verbose) { stdout.printf("Create temp directory..."); }
      string sTmpDir = getTmpDir();
      if (sTmpDir != null) {
        if (Verbose) { stdout.printf("ok :)\nCopying vala files to temp directory..."); }
        string sSrcDir = Path.get_dirname(VFile);
        bool ok = copyValaFiles(sSrcDir, sTmpDir);
        if (ok) {
          VFile = Path.build_path(sTmpDir, Path.get_basename(VFile));
          if (Verbose) { stdout.printf("ok :)\n"); }
        } else {
          if (Verbose) { stdout.printf("not ok :(\n"); }
          stdout.printf("Can not copy to temp directory\n");
        }
        return ok;
      } else {
        if (Verbose) { stdout.printf("not ok :(\n"); }
      }
    } catch (Error e) {
      if (Verbose) { stdout.printf("not ok :(\n"); }
      stderr.printf("%s\n", e.message);
    }
    return false;
  }

  private string getTmpDir() throws Error
  {
    if (m_sTmpDir == null) {
      m_sTmpDir = DirUtils.make_tmp("mkjni-makedir");
      cleanUp();
    }
    return m_sTmpDir;
  }

  public bool cleanUp(bool bDeleteTmpFolder=false)
  {
    if (m_sTmpDir != null) {

      var oDir = File.new_for_path(m_sTmpDir);
      if (oDir.query_exists()) {
        try {
          FileEnumerator e = oDir.enumerate_children(GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE);

          FileInfo info = null;
          while ( (info = e.next_file()) != null ) {
            try {
              var oFile = File.new_for_path( Path.build_path(m_sTmpDir, info.get_name()) );
              oFile.delete();
            } catch (Error e) {
            }
          }
          e.unref();
          if (bDeleteTmpFolder) {
            try {
              oDir.delete();
            } catch (Error e) {
            }
          }
        } catch (Error e) {
          stderr.printf("%s\n", e.message);
        }
      }

    }

    return true;
  }

  /**
   * copies files with .vala suffix from sSrcDir to sDstDir
   */
  private bool copyValaFiles(string sSrcDir, string sDstDir)
  {
    try {
      var oSrcDir = File.new_for_path(sSrcDir);
      FileEnumerator e = oSrcDir.enumerate_children(GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE);

      FileInfo info = null;
      while ( (info = e.next_file()) != null ) {
        if (info.get_file_type () == FileType.REGULAR && info.get_name().has_suffix(".vala")) {
          var src = File.new_for_path( Path.build_path(sSrcDir, info.get_name()) );
          var dst = File.new_for_path( Path.build_path(sDstDir, info.get_name()) );

          bool ok = src.copy(dst, FileCopyFlags.OVERWRITE);
          if (!ok) {
            stderr.printf("Error copying file \"%s\"\n", info.get_name());
          }
        }
      }
      e.unref();
      return true;
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }
    return false;
  }

  public void printHelp()
  {
    stderr.printf("\n");
    stderr.printf("-- %s - make jni files from vala --\n", AppName);
    stderr.printf("\n");
    stderr.printf("usage: %s [PARAMS][OPTIONS]\n", AppName);
    stderr.printf("\n");
    stderr.printf("---- Must-have parameters: ----\n");
    stderr.printf("\n");
    stderr.printf("-f, --file <vala file>    The Vala file containing the class\n");
    stderr.printf("\n");
    stderr.printf("-c, --class <class name>  The Vala class to generate the jni from\n");
    stderr.printf("\n");
    stderr.printf("-l, --lib <lib name>      Please specify the desired name of the library\n");
    stderr.printf("                          The name is w/o lib prefix and .so suffix!\n");
    stderr.printf("\n");
    stderr.printf("---- Options: ----\n");
    stderr.printf("\n");
    stderr.printf("-p, --pkg <package>       Packages to be included (Vala --pkg and pkg-config)\n");
    stderr.printf("\n");
    stderr.printf("-j, --jns <package>       The Java namespace (package) to be created\n");
    stderr.printf("\n");
    stderr.printf("-d                        Create Java file in package directory\n");
    stderr.printf("\n");
    stderr.printf("-o                        Only compile, do not link\n");
    stderr.printf("\n");
    stderr.printf("-t                        Use tmp directory for processing\n");
    stderr.printf("\n");
    stderr.printf("-v                        Verbose - tell what's going on\n");
    stderr.printf("\n");
    stderr.printf("-h, --help, -?, ?         Show this help\n");
    stderr.printf("\n");
  }

}

