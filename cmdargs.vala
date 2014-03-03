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
  public string AppName { private set; get; default=""; }
  public string VFile   { private set; get; default=""; } // -f --file
  public string VClass  { private set; get; default=""; } // -c --class
  public string Package { private set; get; default=""; } // -p --pkg
  public string LibName { private set; get; default=""; } // -l --lib

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
    AppName = args[0];

    string opt = null;

    for (int i=1; i<args.length; ++i) {
      if (opt != null) {
        switch (opt) {
          case "f": VFile   = args[i]; break;
          case "c": VClass  = args[i]; break;
          case "p": Package = args[i]; break;
          case "l": LibName = args[i]; break;
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
          case "-p":
          case "--pkg":
            opt = "p";
            break;
          case "-l":
          case "--lib":
            opt = "l";
            break;
          case "?":
          case "-?":
          case "-h":
          case "--help":
            printHelp();
            return false;
          default:
            return false;
        }
      }
    }

    if (checkArgs()) {
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

  public void printHelp()
  {
    stderr.printf("\n");
    stderr.printf("-- %s - make jni files from vala --\n", AppName);
    stderr.printf("\n");
    stderr.printf("usage: %s [PARAMS][OPTIONS]\n", AppName);
    stderr.printf("\n");
    stderr.printf("---- Must-have parameters: ----\n");
    stderr.printf("\n");
    stderr.printf("-f, --file <vala file>    A valid vala file to start with\n");
    stderr.printf("\n");
    stderr.printf("-c, --class <class name>  A class within the vala file to generate the jni from\n");
    stderr.printf("\n");
    stderr.printf("-l, --lib <lib name>      Please specify how the library will be named\n");
    stderr.printf("                          This is for the call to loadLibrary within the Java file\n");
    stderr.printf("                          and can be changed manually later\n");
    stderr.printf("                          Please specify w/o lib prefix and .so suffix!\n");
    stderr.printf("\n");
    stderr.printf("---- Options: ----\n");
    stderr.printf("\n");
    stderr.printf("-p, --pkg <package>       The Java package (namespace) to be created\n");
    stderr.printf("\n");
    stderr.printf("-h, --help, -?, ?         Show this help\n");
    stderr.printf("\n");
  }

}

