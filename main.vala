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


class Main
{
  public static int main(string[] args)
  {
    bool ok = false;

    var oArgs = CmdArgs.parse(args);
    if (oArgs != null) {
      var oProc = new Processor();
      ok = oProc.run(oArgs);
    } else {
      stderr.printf("Error parsing command line\n");
    }

    if (ok) {
      return 0;
    }
    return 1;
  }
}
