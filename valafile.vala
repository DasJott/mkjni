/*
 * valafile.vala
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


public class ValaFile : GLib.Object
{
  private File m_oFile = null;

  public ValaFile(string sFilename) throws FileError
  {
    m_oFile = File.new_for_path(sFilename);

    if ( ! m_oFile.query_exists() ) {
      throw new FileError.EXIST("File \"%s\" not found\n", sFilename);
    }
  }

  public Class? parse(string sClassname)
  {
    if (m_oFile != null) {
      try {
        Class oClass = new Class(sClassname);

        int nOpenBraces = 0;
        bool bIsComment = false, bInClass = false;

        // the Regex's to find all the stuff
        var regComment    = new Regex("^.*/\\*+((?!\\*/).)*$");
        var regNoComment  = new Regex("\\*/+");
        var regClass      = new Regex("^ *(public{1,1} +)?class{1,1} +([a-zA-Z_0-9]+) *:? *[a-zA-Z_0-9<> ,.]* *({?)$");
        var regBraceOpen  = new Regex("^ *{[^}]*$");
        var regBraceClose = new Regex("^ *}[^{]*$");
        var regMethod     = new Regex("^ *(public|private)? *(static)? *([a-z0-9]+)? +([a-zA-Z0-9_]+) *\\({1,1}([a-zA-Z0-9<>_,\\*\\[\\] ]*)\\){1,1} *({?)$");

        var oStream = new DataInputStream( m_oFile.read() );
        string sLine;
        while ( (sLine = oStream.read_line(null)) != null ) {

          if (bIsComment) {
            if (regNoComment.match(sLine)) {
              bIsComment = false;
            }
          } else {
            if (regComment.match(sLine)) {
              bIsComment = true;
            }
          }

          if (!bIsComment) {

            if (!bInClass) {
              MatchInfo info;
              if (regClass.match( sLine, 0, out info)) {
                // 1: public, 2: Classname, 3: opening brace (or not)
                if ( info.fetch(2) == sClassname ) {
                  bInClass = true;
                  if ( info.fetch(3) == "{" ) {
                    ++nOpenBraces;
                  }
                }
              }
            } else {
              // we are in the desired class

              if (regBraceOpen.match(sLine)) {
                ++nOpenBraces;
              }
              if (regBraceClose.match(sLine)) {
                --nOpenBraces;
              }

              if (nOpenBraces < 1) {
                bInClass = false;
                return oClass;
              }

              if (nOpenBraces == 1) {
                // we are in the classes scope

                MatchInfo info;
                if (regMethod.match(sLine, 0, out info)) {
                  // 1: public/private, 2: static, 3: Return type, 4: Method name, 5: parameters (all), 6: opening brace (or not)
                  if ( info.fetch(1) == "public" ) {
                    var oMethod = new Class.Method( info.fetch(4) );
                    if ( info.fetch(2) == "static" ){
                      oMethod.isStatic = true;
                    }
                    oMethod.returnType = DataType.from_name( info.fetch(3) );
                    if ( setParameters( info.fetch(5), ref oMethod.params ) ) {
                      oClass.methods.append( oMethod );
                    }
                  }
                  if ( info.fetch(6) == "{" ) {
                    ++nOpenBraces;
                  }
                }
              }

            }
          }

        }
      } catch (Error e) {
        stderr.printf("%s\n", e.message);
      }
    }

    return null;
  }

  public bool compile2C(Class oClass)
  {
    if (m_oFile != null) {
      // TODO: compile the vala file to C code
      // TODO: and fill function signatures into Class info struct

      string sFilename = m_oFile.get_basename();
      string sHeader = sFilename;
      int nPos = sFilename.last_index_of(".");
      if (nPos > 0) {
        sHeader = sFilename.slice(0, nPos) + ".h";
      }

      string sCmd = "valac -C -h \"%s\" \"%s\"".printf(sHeader, sFilename);
      string sStdOut, sStdErr; int nErr = 0;

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
    }
    return false;
  }

  private bool setParameters(string sParams, ref List<Class.Method.Parameter> oParams)
  {
    bool ok = true;

    try {
      MatchInfo info;
      var regParam = new Regex("^ *((ref|out)? *)([a-zA-Z0-9]+) +([a-zA-Z0-9_]+)$");

      string[] asParams = sParams.split(",");
      foreach (string sParam in asParams) {
        ok = regParam.match( sParam, 0, out info );
        if (ok) {
          // 1: ref /out , 2: ref/out, 3: type, 4: name
          var oParam = new Class.Method.Parameter( info.fetch(4) );
          oParam.direction = info.fetch(2);
          oParam.type = DataType.from_name( info.fetch(3) );
          ok = (oParam.type != DataType.UNKNOWN);
          if (ok) {
            oParams.append( oParam );
          }
        }
        if (!ok) {
          stderr.printf("Fatal error - Invalid parameter: \"%s\"\n", sParam.strip());
          break;
        }
      }
    } catch (Error e) {
      stderr.printf("%s\n", e.message);
      ok = false;
    }

    return ok;
  }
}

