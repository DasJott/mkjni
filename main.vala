/*
 * main.vala
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


class Main : GLib.Object
{
  /**
   * args:
   * 1: vala file
   * 2: vala class
   * 3: java package
   * 4: lib name
  */
  public static int main(string[] args)
  {
    //test(); return 0;

    bool ok = false;

    try {
      var oValaFile = new ValaFile(args[1]);
      Class oClass = oValaFile.parse(args[2]);
      if (oClass != null) {
        var oJavaFile = new JavaFile(args[4]);
        ok = oJavaFile.create(oClass, args[3]);
        JNIFiles oJniFiles = null;
        if (ok) {
          oJniFiles = new JNIFiles(oClass, args[3]);
          ok = oJniFiles.createHeader();
        }
        if (ok) {
          ok = oJniFiles.createImplementation();
        }
        if (ok) {
          oValaFile.compile2C(oClass);
        }
      } else {
        stdout.printf("Ooops, class is null!\n");
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }

    if (ok) {
      stdout.printf("Success!\n");
    } else {
      stdout.printf("Errrrrr!\n");
    }

    return 0;
  }

  /*
  private static void test()
  {
    try {
      MatchInfo info;

      var regParam = new Regex("^ *((ref|out)? *)([a-zA-Z0-9]+) +([a-zA-Z0-9_]+)$");

      string[] ss = new string[] {
        "Class oClass",
        "out Class oClass",
      };

      foreach (string s in ss) {
        stdout.printf("# \"%s\"\n", s);

        if ( regParam.match(s, 0, out info) ) {
          stdout.printf("Match!\n");
          for (int i=0; i<info.get_match_count(); ++i) {
            stdout.printf("%i: \"%s\"\n", i, info.fetch(i));
          }
        } else {
          stdout.printf("No match!\n");
        }
        stdout.printf("\n");
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }
  }
  */
}
