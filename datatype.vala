/*
 * datatype.vala
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


public enum DataType {
  NONE, UNKNOWN, VOID, STRING, INT, BYTE, BOOL, FLOAT, DOUBLE, CHAR,
  ARR_STRING, ARR_INT, ARR_DOUBLE, ARR_FLOAT, ARR_CHAR, ARR_BYTE;

  public static DataType from_name(string sName)
  {
    switch (sName) {
      case "void"     : return VOID;
      case "int"      : return INT;
      case "int8"     : return BYTE;
      case "float"    : return FLOAT;
      case "double"   : return DOUBLE;
      case "char"     : return CHAR;
      case "bool"     : return BOOL;
      case "string"   : return STRING;
      case "string[]" : return ARR_STRING;
      case "int[]"    : return ARR_INT;
      case "double[]" : return ARR_DOUBLE;
      case "float[]"  : return ARR_FLOAT;
      case "char[]"   : return ARR_CHAR;
      case "int8[]"   : return ARR_BYTE;
      case ""         : return NONE;
      default         : return UNKNOWN;
    }
  }

  public bool returns_something()
  {
    return this != VOID;
  }

  public string to_vala_string()
  {
    switch (this) {
      case VOID:       return "void";
      case INT:        return "int";
      case BYTE:       return "int8";
      case BOOL:       return "bool";
      case FLOAT:      return "float";
      case DOUBLE:     return "double";
      case CHAR:       return "char";
      case STRING:     return "string";
      case ARR_STRING: return "string[]";
      case ARR_INT:    return "int[]";
      case ARR_FLOAT:  return "float[]";
      case ARR_DOUBLE: return "double[]";
      case ARR_CHAR:   return "char[]";
      case ARR_BYTE:   return "int8[]";
      default:         return "";
    }
  }

  public string to_java_string()
  {
    switch (this) {
      case VOID:       return "void";
      case INT:        return "int";
      case BYTE:       return "byte";
      case BOOL:       return "boolean";
      case FLOAT:      return "float";
      case DOUBLE:     return "double";
      case CHAR:       return "char";
      case STRING:     return "String";
      case ARR_STRING: return "String[]";
      case ARR_INT:    return "int[]";
      case ARR_FLOAT:  return "float[]";
      case ARR_DOUBLE: return "double[]";
      case ARR_CHAR:   return "char[]";
      case ARR_BYTE:   return "byte[]";
      default:         return "";
    }
  }

  public string to_jni_string()
  {
    switch (this) {
      case VOID:       return "void";
      case INT:        return "jint";
      case BYTE:       return "jbyte";
      case BOOL:       return "jboolean";
      case FLOAT:      return "jfloat";
      case DOUBLE:     return "jdouble";
      case CHAR:       return "jchar";
      case STRING:     return "jstring";
      case ARR_STRING: return "jobjectArray";
      case ARR_INT:    return "jintArray";
      case ARR_FLOAT:  return "jfloatArray";
      case ARR_DOUBLE: return "jdoubleArray";
      case ARR_CHAR:   return "jcharArray";
      case ARR_BYTE:   return "jbyteArray";
      default:         return "";
    }
  }

  public string to_glib_string()
  {
    switch (this) {
      case VOID:       return "void";
      case INT:        return "gint";
      case BYTE:       return "gbyte";
      case BOOL:       return "gboolean";
      case FLOAT:      return "gfloat";
      case DOUBLE:     return "gdouble";
      case CHAR:       return "gchar";
      case STRING:     return "gchar*";
      case ARR_INT:    return "gint*";
      case ARR_STRING: return "gchar**";
      case ARR_FLOAT:  return "gfloat*";
      case ARR_DOUBLE: return "gdouble*";
      case ARR_CHAR:   return "gchar*";
      case ARR_BYTE:   return "gbyte*";
      default:         return "";
    }
  }

  public bool isArray()
  {
    return (
         (this == ARR_INT)
      || (this == ARR_STRING)
      || (this == ARR_DOUBLE)
      || (this == ARR_FLOAT)
      || (this == ARR_CHAR)
      || (this == ARR_BYTE)
    );
  }
}

