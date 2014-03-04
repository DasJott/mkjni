/*
 * javafile.vala
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


public class JavaFile : GLib.Object
{
  private string m_sLibName = "jott-1.0";

  public JavaFile(string sLoadLib)
  {
    m_sLibName = sLoadLib;
  }

  public bool create(Class oClass, string? sPackage=null, bool bPkgDir=false)
  {
    File oFile = getFile(oClass, sPackage, bPkgDir);

    if (oFile != null) {
      try {
        var oStream = new DataOutputStream( oFile.create(FileCreateFlags.REPLACE_DESTINATION) );

        oStream.put_string("/*\n");
        oStream.put_string(" * %s\n".printf(oFile.get_basename()));
        oStream.put_string(" * file generated by mkjni\n");
        oStream.put_string(" */\n");
        oStream.put_string("\n");
        if (sPackage != null && sPackage != "") {
          oStream.put_string("package %s;\n".printf(sPackage));
          oStream.put_string("\n");
        }
        oStream.put_string("class %s\n".printf(oClass.name));
        oStream.put_string("{\n");
        //oStream.put_string("  static { System.loadLibrary(\"glib-2.0\"); }\n");
        oStream.put_string("  static { System.loadLibrary(\"%s\"); }\n".printf(m_sLibName));
        oStream.put_string("\n");

        var sbMethod = new StringBuilder();

        oClass.methods.foreach( (oMethod) => {
          if (oMethod.returnType != DataType.UNKNOWN) {
            sbMethod.append("  public");
            sbMethod.append( oMethod.isStatic ? " static" : "" );
            sbMethod.append(" native");
            sbMethod.append(" %s".printf(oMethod.returnType.to_java_string()));
            sbMethod.append(" %s".printf(oMethod.name));
            string sParams = "";
            oMethod.params.foreach( (oParam) => {
              if (sParams != "") { sParams += ", "; }
              //oStream.put_string("%s", oParam.direction);
              sParams += oParam.type.to_java_string();
              sParams += " ";
              sParams += oParam.name;
            });
            sbMethod.append("(%s);\n".printf(sParams));
          }
        });
        oStream.put_string(sbMethod.str);
        oStream.put_string("}\n");
        oStream.put_string("\n");

      } catch (Error e) {
        stderr.printf("%s\n", e.message);
        return false;
      }
    }

    return true;
  }

  private File? getFile(Class oClass, string sPackage, bool bPkgDir)
  {
    try {
      string sPath = "";
      if (bPkgDir && sPackage != null && sPackage != "") {
        if (sPackage.contains("/")) {
          stderr.printf("Error: Specified package name not valid\n");
        } else {
          sPath = sPackage.replace(".", "/");
          File oFile = File.new_for_path( sPath );
          if (!oFile.query_exists()) {
            oFile.make_directory_with_parents();
          }
          sPath += "/";
        }
      }

      string sFilepath = sPath + oClass.name + ".java";

      var oFile = File.new_for_path( sFilepath );
      if (oFile.query_exists()) {
        oFile.delete();
      }
      return oFile;

    } catch (Error e) {
      stderr.printf("%s\n", e.message);
    }
    return null;
  }
}
