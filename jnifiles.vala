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

  public bool createHeader(string sDir=".")
  {
    File oFile = getFile(Path.build_filename(sDir, fileNameHeader));

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

  public bool createImplementation(string sDir=".")
  {
    File oFile = getFile(Path.build_filename(sDir, fileNameImpl));

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
        string sVarInstance = "g_instance_of_%s".printf(m_oClass.c_getType());
        oStream.put_string("%s* %s = NULL;\n".printf(m_oClass.c_getType(), sVarInstance));
        oStream.put_string("%s* getInstance(void)\n".printf(m_oClass.c_getType()));
        oStream.put_string("{\n");
        oStream.put_string("  if (%s == NULL) {\n".printf(sVarInstance));
        oStream.put_string("    %s = %s;\n".printf(sVarInstance, m_oClass.c_getConstructor()));
        oStream.put_string("  }\n");
        oStream.put_string("  return %s;\n".printf(sVarInstance));
        oStream.put_string("}\n");

        // destroy singleton
        oStream.put_string("void destroyInstance(void)\n");
        oStream.put_string("{\n");
        oStream.put_string("  if (%s != NULL) {\n".printf(sVarInstance));
        oStream.put_string("    %s = NULL;\n".printf(sVarInstance));
        oStream.put_string("  }\n");
        oStream.put_string("}\n");
        oStream.put_string("\n");

        // the method calls
        var sbMethods = new StringBuilder();
        m_oClass.methods.foreach( (oMethod) => {
          sbMethods.append( "%s\n".printf( getMethodSignature(oMethod, true) ) );
          sbMethods.append( "{\n" );

          sbMethods.append( getVariableDeclarations(oMethod) );
          sbMethods.append( getMethodCall(oMethod, "getInstance()") );
          sbMethods.append( getVariableCleanup(oMethod) );
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

  /*
   *
   * name: JNIFiles.getMethodSignature Creates a method signature as a string from a data struct
   * @param oMethod The method to create the signature of
   * @param bParamNames Give the params names
   * @return the method signature as a string
   *
   */
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

  // receive the parameters from java and cast them to vala-c-code
  private string getVariableDeclarations(Class.Method oMethod)
  {
    StringBuilder sb = new StringBuilder();

    int i = 0;
    oMethod.params.foreach( (oParam) => {
      string gtype  = oParam.type.to_glib_string();  // parameter type - glib type
      //string jtype  = oParam.type.to_java_string();  // parameter type - java name
      string jvar   = oParam.name + i.to_string();   // name of method parameter name (java)
      string gvar   = oParam.cname;                  // name of (casted) variable whithin method (glib)
      string arrlen = oParam.arrlength;              // if param is an array, this is the name of the matching length variable

      string sCast = "";
      switch (oParam.type) {
      case DataType.ARR_INT:
        {
          sCast += "%s %s;\n".printf(gtype, gvar);
          sCast += "int %s;\n".printf(arrlen);
          sCast += "{\n";
          sCast += "  %s = (*pEnv)->GetArrayLength(pEnv, %s);\n".printf(arrlen, jvar);
          sCast += "  %s = (%s)(*pEnv)->GetIntArrayElements(pEnv, %s, 0);\n".printf(gvar, gtype, jvar);
          sCast += "}\n";
        } break;
      case DataType.ARR_FLOAT:
        {
          sCast += "%s %s;\n".printf(gtype, gvar);
          sCast += "int %s;\n".printf(arrlen);
          sCast += "{\n";
          sCast += "  %s = (*pEnv)->GetArrayLength(pEnv, %s);\n".printf(arrlen, jvar);
          sCast += "  %s = (%s)(*pEnv)->GetFloatArrayElements(pEnv, %s, 0);\n".printf(gvar, gtype, jvar);
          sCast += "}\n";
        } break;
      case DataType.ARR_DOUBLE:
        {
          sCast += "%s %s;\n".printf(gtype, gvar);
          sCast += "int %s;\n".printf(arrlen);
          sCast += "{\n";
          sCast += "  %s = (*pEnv)->GetArrayLength(pEnv, %s);\n".printf(arrlen, jvar);
          sCast += "  %s = (%s)(*pEnv)->GetDoubleArrayElements(pEnv, %s, 0);\n".printf(gvar, gtype, jvar);
          sCast += "}\n";
        } break;
      case DataType.ARR_CHAR:
        {
          sCast += "%s %s;\n".printf(gtype, gvar);
          sCast += "int %s;\n".printf(arrlen);
          sCast += "{\n";
          sCast += "  %s = (*pEnv)->GetArrayLength(pEnv, %s);\n".printf(arrlen, jvar);
          sCast += "  %s = (%s)(*pEnv)->GetCharArrayElements(pEnv, %s, 0);\n".printf(gvar, gtype, jvar);
          sCast += "}\n";
        } break;
      case DataType.ARR_BYTE:
        {
          sCast += "%s %s;\n".printf(gtype, gvar);
          sCast += "int %s;\n".printf(arrlen);
          sCast += "{\n";
          sCast += "  %s = (*pEnv)->GetArrayLength(pEnv, %s);\n".printf(arrlen, jvar);
          sCast += "  %s = (%s)(*pEnv)->GetByteArrayElements(pEnv, %s, 0);\n".printf(gvar, gtype, jvar);
          sCast += "}\n";
        } break;
      case DataType.ARR_STRING:
        {
          sCast += "%s %s;\n".printf(gtype, gvar);
          sCast += "int %s;\n".printf(arrlen);
          sCast += "{\n";
          sCast += "  %s = (*pEnv)->GetArrayLength(pEnv, %s);\n".printf(arrlen, jvar);
          sCast += "  %s = (%s) malloc(%s*sizeof(%s));\n".printf(gvar, gtype, arrlen, DataType.STRING.to_glib_string());
          sCast += "  int i=0;\n";
          sCast += "  for(i=0;i<%s;++i) {\n".printf(arrlen);
          sCast += "    %s js = (%s)(*pEnv)->GetObjectArrayElement(pEnv, %s, i);\n".printf(
                      DataType.STRING.to_jni_string(), DataType.STRING.to_jni_string(), jvar
                    );
          sCast += "    %s gs = (%s)(*pEnv)->GetStringUTFChars(pEnv, js, 0);\n".printf(
                      DataType.STRING.to_glib_string(), DataType.STRING.to_glib_string()
                    );
          sCast += "    %s[i] = g_strdup(gs);\n".printf(gvar);
          sCast += "    (*pEnv)->ReleaseStringUTFChars(pEnv, js, gs);\n";
          sCast += "  }\n";
          sCast += "}\n";
        } break;
      case DataType.STRING:
        {
          sCast = "%s %s = (%s)(*pEnv)->GetStringUTFChars(pEnv, %s, 0);\n".printf(gtype, gvar, gtype, jvar);
        } break;
      default:
        {
          sCast = "%s %s = (%s) %s;\n".printf(gtype, gvar, gtype, jvar);
        } break;
      }
      if (sCast != "") { sb.append(sCast); }
      ++i;
    });

    return sb.str;
  }

  // call vala-c-code generate return value
  private string getMethodCall(Class.Method oMethod, string sInstance)
  {
    string sCall = "";
    if (oMethod.returnType.returns_something()) {
      if (oMethod.returnType == DataType.STRING) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "const char* tmp = (const char*) %s(%s);\n".printf(
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (*pEnv)->NewStringUTF(pEnv, tmp);\n";
        sCall += "}\n";
      } else if (oMethod.returnType == DataType.ARR_STRING) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "int %s=0;\n".printf(oMethod.returnLength);
        sCall += "gchar** tmp = %s(%s);\n".printf(
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (%s)(*pEnv)->NewObjectArray(pEnv, %s, (*pEnv)->FindClass(pEnv, \"java/lang/String\"), (*pEnv)->NewStringUTF(pEnv, \"\"));\n".printf(
          oMethod.returnType.to_jni_string(),
          oMethod.returnLength
        );
        sCall += "int i;\n";
        sCall += "for (i=0; i<%s;++i) {\n".printf(oMethod.returnLength);
        sCall += "jstring str = (*pEnv)->NewStringUTF(pEnv, tmp[i]);\n";
        sCall += "(*pEnv)->SetObjectArrayElement(pEnv, ret, i, str);\n";
        sCall += "(*pEnv)->DeleteLocalRef(pEnv, str);\n";
        sCall += "}\n";
        sCall += "}\n";
      } else if (oMethod.returnType == DataType.ARR_INT) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "int %s=0;\n".printf(oMethod.returnLength);
        sCall += "%s* tmp = (%s*) %s(%s);\n".printf(
          DataType.INT.to_jni_string(),
          DataType.INT.to_jni_string(),
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (*pEnv)->NewIntArray(pEnv, %s);\n".printf(
          oMethod.returnLength
        );
        sCall += "(*pEnv)->SetIntArrayRegion(pEnv, ret, 0, %s, tmp);\n".printf(oMethod.returnLength);
        sCall += "}\n";
      } else if (oMethod.returnType == DataType.ARR_FLOAT) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "int %s=0;\n".printf(oMethod.returnLength);
        sCall += "%s* tmp = (%s*) %s(%s);\n".printf(
          DataType.FLOAT.to_jni_string(),
          DataType.FLOAT.to_jni_string(),
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (*pEnv)->NewFloatArray(pEnv, %s);\n".printf(
          oMethod.returnLength
        );
        sCall += "(*pEnv)->SetFloatArrayRegion(pEnv, ret, 0, %s, tmp);\n".printf(oMethod.returnLength);
        sCall += "}\n";
      } else if (oMethod.returnType == DataType.ARR_DOUBLE) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "int %s=0;\n".printf(oMethod.returnLength);
        sCall += "%s* tmp = (%s*) %s(%s);\n".printf(
          DataType.DOUBLE.to_jni_string(),
          DataType.DOUBLE.to_jni_string(),
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (*pEnv)->NewDoubleArray(pEnv, %s);\n".printf(
          oMethod.returnLength
        );
        sCall += "(*pEnv)->SetDoubleArrayRegion(pEnv, ret, 0, %s, tmp);\n".printf(oMethod.returnLength);
        sCall += "}\n";
      } else if (oMethod.returnType == DataType.ARR_CHAR) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "int %s=0;\n".printf(oMethod.returnLength);
        sCall += "%s* tmp = (%s*) %s(%s);\n".printf(
          DataType.CHAR.to_jni_string(),
          DataType.CHAR.to_jni_string(),
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (*pEnv)->NewCharArray(pEnv, %s);\n".printf(
          oMethod.returnLength
        );
        sCall += "(*pEnv)->SetCharArrayRegion(pEnv, ret, 0, %s, tmp);\n".printf(oMethod.returnLength);
        sCall += "}\n";
      } else if (oMethod.returnType == DataType.ARR_BYTE) {
        sCall += "%s ret;\n".printf(oMethod.returnType.to_jni_string());
        sCall += "{\n";
        sCall += "int %s=0;\n".printf(oMethod.returnLength);
        sCall += "%s* tmp = (%s*) %s(%s);\n".printf(
          DataType.BYTE.to_jni_string(),
          DataType.BYTE.to_jni_string(),
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
        sCall += "ret = (*pEnv)->NewByteArray(pEnv, %s);\n".printf(
          oMethod.returnLength
        );
        sCall += "(*pEnv)->SetByteArrayRegion(pEnv, ret, 0, %s, tmp);\n".printf(oMethod.returnLength);
        sCall += "}\n";
      } else {
        sCall = "%s ret = (%s) %s(%s);\n".printf(
          oMethod.returnType.to_jni_string(),
          oMethod.returnType.to_jni_string(),
          m_oClass.c_getName(oMethod),
          getCCallParams(oMethod, sInstance)
        );
      }
    } else {
      sCall = "%s(%s);\n".printf(
        m_oClass.c_getName(oMethod),
        getCCallParams(oMethod, sInstance)
      );
    }

    return sCall;
  }

  // get parameters to call vala-c-code methods
  private string getCCallParams(Class.Method oMethod, string sInstance)
  {
    string sParams = "";

    if (!oMethod.isStatic) {
      // static methods need no instance
      sParams += sInstance;
    }

    oMethod.params.foreach( (oParam) => {
      if (sParams != "") { sParams += ", "; }
      sParams += oParam.cname;
      if (oParam.type.isArray()) {
        sParams += ",";
        sParams += oParam.arrlength;
      }
    });
    if (oMethod.returnType.isArray()) {
      if (sParams != "") { sParams += ", "; }
      sParams += "&";
      sParams += oMethod.returnLength;
    }
    return sParams;
  }

  // get code to clean up
  private string getVariableCleanup(Class.Method oMethod)
  {
    string sCode = "";

    int i=0;
    oMethod.params.foreach( (oParam) => {
      switch (oParam.type) {
      case DataType.STRING:
        {
          sCode = "(*pEnv)->ReleaseStringUTFChars(pEnv, %s, %s);\n".printf( oParam.name + i.to_string(), oParam.cname );
        } break;
      case DataType.ARR_INT:
        {
          sCode = "(*pEnv)->ReleaseIntArrayElements(pEnv, %s, %s, 0);\n".printf( oParam.name + i.to_string(), oParam.cname );
        } break;
      case DataType.ARR_FLOAT:
        {
          sCode = "(*pEnv)->ReleaseFloatArrayElements(pEnv, %s, %s, 0);\n".printf( oParam.name + i.to_string(), oParam.cname );
        } break;
      case DataType.ARR_DOUBLE:
        {
          sCode = "(*pEnv)->ReleaseDoubleArrayElements(pEnv, %s, %s, 0);\n".printf( oParam.name + i.to_string(), oParam.cname );
        } break;
      case DataType.ARR_CHAR:
        {
          sCode = "(*pEnv)->ReleaseCharArrayElements(pEnv, %s, %s, 0);\n".printf( oParam.name + i.to_string(), oParam.cname );
        } break;
      case DataType.ARR_BYTE:
        {
          sCode = "(*pEnv)->ReleaseByteArrayElements(pEnv, %s, %s, 0);\n".printf( oParam.name + i.to_string(), oParam.cname );
        } break;
      case DataType.ARR_STRING:
        {
          sCode = "free(%s);\n".printf(oParam.cname);
        } break;
      }
      ++i;
    });

    return sCode;
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

