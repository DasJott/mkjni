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
        oClass.filename = getGenericFilename();

        int nOpenBraces = 0;
        string sNamespace = "";
        bool bIsComment = false, bInClass = false, bIsInNamespace = false;

        // the Regex's to find all the stuff
        var regComment    = new Regex("^.*/\\*+((?!\\*/).)*$");
        var regNoComment  = new Regex("\\*/+");
        var regClass      = new Regex("^ *(public{1,1} +)?class{1,1} +([a-zA-Z_0-9]+) *:? *[a-zA-Z_0-9<> ,.]* *({?)$");
        var regNamespace  = new Regex("^ *(namespace{1,1}) +([a-zA-Z_0-9]+) *({?)$");
        var regBraceOpen  = new Regex("^[^}]*{[^}]*$");
        var regBraceClose = new Regex("^[^{]*}[^{]*$");
        var regMethod     = new Regex("^ *(public|private)? *(static)? *([a-z0-9\\[\\]]+)? +([a-zA-Z0-9_]+) *\\({1,1}([a-zA-Z0-9<>_,\\*\\[\\] ]*)\\){1,1} *({?)$");

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

            if (regBraceOpen.match(sLine)) {
              ++nOpenBraces;
            }
            if (regBraceClose.match(sLine)) {
              --nOpenBraces;
            }

            if (!bInClass) {
              MatchInfo info;
              if (regClass.match( sLine, 0, out info)) {
                // 1: public, 2: Classname, 3: opening brace (or not)
                if ( info.fetch(2) == sClassname ) {
                  bInClass = true;
                  oClass.namespce = sNamespace;
                }
                if ( info.fetch(3) == "{" ) {
                  ++nOpenBraces;
                }
              } else if (regNamespace.match(sLine, 0, out info)){
                // 1: namespace, 2: Erik, 3: opening brace (or not)
                bIsInNamespace = true;
                sNamespace = info.fetch(2);
                if ( info.fetch(3) == "{" ) {
                  ++nOpenBraces;
                }
              }
            } else {
              // we are in the desired class

              if (bIsInNamespace && nOpenBraces < 1) {
                sNamespace = "";
                bIsInNamespace = false;
              }

              if ((!bIsInNamespace && nOpenBraces < 1) || (bIsInNamespace && nOpenBraces < 2)) {
                bInClass = false;
                return oClass;
              }

              if ((!bIsInNamespace && nOpenBraces == 1) || (bIsInNamespace && nOpenBraces == 2)) {
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
                    } else {
                      // TODO: Maybe breakup and exit?
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

  public bool compile2C(string[]? pkgs=null, string[]? flags=null)
  {
    if (m_oFile != null) {
      string sWorkDir  = m_oFile.get_basename();
      string sFilename = m_oFile.get_path();
      string sHeader   = getGenericFilename() + ".h";

      return compile2Ccode(sWorkDir, {sFilename}, pkgs, flags, sHeader);
    }
    return false;
  }

  public static bool compile2Ccode(string sWorkDir, string[] asFiles, string[]? pkgs=null, string[]? flags=null, string? sHeader=null)
  {
    string sHdr = "";
    if (sHeader != null && sHeader != "") {
      sHdr = " --header=%s".printf(sHeader);
    }

    string sPkgs = "";
    if (pkgs != null) {
      foreach (string pkg in pkgs) {
        sPkgs += " --pkg=%s".printf(pkg);
      }
    }

    string sFlags = "";
    if (flags != null) {
      foreach (string flag in flags) {
        sFlags += " %s".printf(flag);
      }
    }

    string sFiles = "";
    foreach (string sFile in asFiles){
      sFiles += " %s".printf(sFile);
    }

    string sCmd = "valac%s%s -C%s %s".printf(sFlags, sPkgs, sHdr, sFiles);

    var shell = new Sys();
    return shell.spawn_cmd(sWorkDir, sCmd);
  }

  private bool setParameters(string sParams, ref List<Class.Method.Parameter> oParams)
  {
    bool ok = true;

    try {
      MatchInfo info;
      var regParam = new Regex("^ *((ref|out)? *)([a-zA-Z0-9\\[\\]]+) +([a-zA-Z0-9_]+)$");

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

  public string getPath()
  {
    string sPath = Path.get_dirname( m_oFile.get_path() );
    if (!sPath.has_suffix("/")) {
      sPath += "/";
    }
    return sPath;
  }

  public string getGenericFilename()
  {
    string sBasename = m_oFile.get_basename();
    int nPos = sBasename.last_index_of(".");
    if (nPos > 0) {
      return sBasename.slice(0, nPos);
    }
    return "";
  }

  public string getHeaderName()
  {
    return getGenericFilename() + ".h";
  }
}

