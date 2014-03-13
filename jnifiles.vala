/*
 * jnifiles.vala
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


public class JNIFiles : GLib.Object
{
  private Class m_oClass = null;
  private string m_sPackage = "";

  public JNIFiles(Class oClass, string sPackage="")
  {
    m_oClass = oClass;
    m_sPackage = sPackage;

    string sPath = "";
    if (sPackage != "") {
      sPath = sPackage.replace(".", "_");
      sPath += "_";
    }
    classPath = sPath + oClass.name;
  }

  public string classPath      { get; construct set; }
  public string fileNameHeader { owned get { return classPath + ".h"; } }
  public string fileNameImpl   { owned get { return classPath + ".c"; } }

  public bool createHeader()
  {
    File oFile = getFile(fileNameHeader);

    if (oFile != null) {
      try {
        var oStream = new DataOutputStream( oFile.create(FileCreateFlags.REPLACE_DESTINATION) );

        oStream.put_string("/*\n");
        oStream.put_string(" * %s\n".printf(oFile.get_basename()));
        oStream.put_string(" * file generated by mkjni\n");
        oStream.put_string(" */\n");
        oStream.put_string("\n");
        oStream.put_string("#include <jni.h>\n");
        oStream.put_string("\n");
        oStream.put_string("#ifndef _Included_%s\n".printf(classPath));
        oStream.put_string("#define _Included_%s\n".printf(classPath));
        oStream.put_string("#ifdef __cplusplus\n");
        oStream.put_string("extern \"C\" {\n");
        oStream.put_string("#endif\n");
        oStream.put_string("\n");

        var sbMethods = new StringBuilder();
        m_oClass.methods.foreach( (oMethod) => {
          sbMethods.append( "%s;\n".printf( getMethodSignature(oMethod, false) ) );
        });
        oStream.put_string(sbMethods.str);

        oStream.put_string("\n");
        oStream.put_string("#ifdef __cplusplus\n");
        oStream.put_string("}\n");
        oStream.put_string("#endif\n");
        oStream.put_string("#endif\n");

        return true;
      } catch (Error e) {
        stderr.printf("%s\n", e.message);
      }
    }

    return false;
  }

  public bool createImplementation()
  {
    File oFile = getFile(fileNameImpl);

    if (oFile != null) {
      try {
        var oStream = new DataOutputStream( oFile.create(FileCreateFlags.REPLACE_DESTINATION) );

        oStream.put_string("/*\n");
        oStream.put_string(" * %s\n".printf(oFile.get_basename()));
        oStream.put_string(" * file generated by mkjni\n");
        oStream.put_string(" */\n");
        oStream.put_string("\n");
        oStream.put_string("#include \"%s.h\"\n".printf(m_oClass.filename));
        oStream.put_string("#include \"%s.h\"\n".printf(classPath));
        oStream.put_string("\n");

        // singleton construct method
        string sVarInstance = "g_instance_of_%s".printf(m_oClass.name);
        oStream.put_string("%s* %s = NULL;\n".printf(m_oClass.name, sVarInstance));
        oStream.put_string("%s* getInstance(void)\n".printf(m_oClass.name));
        oStream.put_string("{\n");
        oStream.put_string("if (%s == NULL) {\n".printf(sVarInstance));
        oStream.put_string("%s = %s;\n".printf(sVarInstance, m_oClass.c_getConstructor()));
        oStream.put_string("}\n");
        oStream.put_string("return %s;\n".printf(sVarInstance));
        oStream.put_string("}\n");

        // destroy singleton
        oStream.put_string("void destroyInstance(void)\n");
        oStream.put_string("{\n");
        oStream.put_string("  if (%s != NULL) {\n".printf(sVarInstance));
        oStream.put_string("    %s = NULL;\n".printf(sVarInstance));
        oStream.put_string("  }\n");
        oStream.put_string("}\n");
        oStream.put_string("\n");

        var sbMethods = new StringBuilder();
        m_oClass.methods.foreach( (oMethod) => {
          sbMethods.append( "%s\n".printf( getMethodSignature(oMethod, true) ) );
          sbMethods.append( "{\n" );

          sbMethods.append( getVariableDeclarations(oMethod) );
          //sbMethods.append( "%s* pInstance = getInstance();\n".printf(m_oClass.name) );
          sbMethods.append( getMethodCall(oMethod, "getInstance()") );
          if (oMethod.returnType.returns_something()) {
            sbMethods.append( "return ret;\n" );
          }
          sbMethods.append( "}\n" );
          sbMethods.append( "\n" );
        });
        oStream.put_string(sbMethods.str);

        oStream.put_string("\n");

        return true;
      } catch (Error e) {
        stderr.printf("%s\n", e.message);
      }
    }

    return false;
  }

  private string getMethodSignature(Class.Method oMethod, bool bParamNames)
  {
    var sbMethod = new StringBuilder();

    if (oMethod.returnType != DataType.UNKNOWN) {
      sbMethod.append("JNIEXPORT");
      sbMethod.append(" %s".printf(oMethod.returnType.to_jni_string()));
      sbMethod.append(" JNICALL");
      sbMethod.append(" Java_%s_%s".printf(classPath, oMethod.name));

      string sParams;
      if (bParamNames) {
        sParams = "JNIEnv* pEnv, jclass oClass";
      } else {
        sParams = "JNIEnv*, jclass";
      }
      int i = 0;
      oMethod.params.foreach( (oParam) => {
        sParams += ", ";
        sParams += oParam.type.to_jni_string();
        if (bParamNames) {
          sParams += " ";
          sParams += oParam.name;
          sParams += i.to_string();
        }
        ++i;
      });
      sbMethod.append("(%s)".printf(sParams));
    }

    return sbMethod.str;
  }

  private string getVariableDeclarations(Class.Method oMethod)
  {
    StringBuilder sb = new StringBuilder();

    int i = 0;
    oMethod.params.foreach( (oParam) => {
      string sCast = "";
      switch (oParam.type) {
      case DataType.INT:
        {
          sCast = "int %s = (int) %s;\n";
        } break;
      case DataType.BOOL:
        {
          sCast = "bool %s = (bool) %s;\n";
        } break;
      case DataType.STRING:
        {
          sCast = "const char* %s = (*pEnv)->GetStringUTFChars(pEnv, %s, 0);\n";
        } break;
      }
      if (sCast != "") {
        sb.append( sCast.printf(oParam.name + "_", oParam.name + i.to_string()) );
      }
      ++i;
    });

    return sb.str;
  }

  private string getMethodCall(Class.Method oMethod, string sInstance)
  {
    string sCall = "";
    if (oMethod.returnType.returns_something()) {
      if (oMethod.returnType == DataType.STRING) {
        sCall = "const char* tmp = (const char*) %s(%s%s);\n".printf(
          m_oClass.c_getName(oMethod),
          sInstance,
          getCCallParams(oMethod)
        );
        sCall += "%s ret = (*pEnv)->NewStringUTF(pEnv, tmp);\n".printf(
          oMethod.returnType.to_jni_string()
        );
      } else {
        sCall = "%s ret = (%s) %s(%s%s);\n".printf(
          oMethod.returnType.to_jni_string(),
          oMethod.returnType.to_jni_string(),
          m_oClass.c_getName(oMethod),
          sInstance,
          getCCallParams(oMethod)
        );
      }
    } else {
      sCall = "%s(%s%s);\n".printf(
        m_oClass.c_getName(oMethod),
        sInstance,
        getCCallParams(oMethod)
      );
    }

    return sCall;
  }

  private string getCCallParams(Class.Method oMethod)
  {
    string sParams = "";
    oMethod.params.foreach( (oParam) => {
      sParams += ", ";
      sParams += oParam.name;
      sParams += "_";
    });
    return sParams;
  }

  private File? getFile(string sFilename)
  {
    try {
      var oFile = File.new_for_path( sFilename );
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

