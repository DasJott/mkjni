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
  NONE, UNKNOWN, VOID, STRING, INT, BOOL;

  public static DataType from_name(string sName)
  {
    switch (sName) {
      case "void":   return VOID;
      case "int":    return INT;
      case "bool":   return BOOL;
      case "string": return STRING;
      case ""      : return NONE;
      default:       return UNKNOWN;
    }
  }

  public bool returns_something()
  {
    switch (this) {
      case INT:
      case BOOL:
      case STRING: return true;
      default:     return false;
    }
  }

  public string to_vala_string()
  {
    switch (this) {
      case VOID:   return "void";
      case INT:    return "int";
      case BOOL:   return "bool";
      case STRING: return "string";
      default:     return "";
    }
  }

  public string to_java_string()
  {
    switch (this) {
      case VOID:   return "void";
      case INT:    return "int";
      case BOOL:   return "boolean";
      case STRING: return "String";
      default:     return "";
    }
  }

  public string to_jni_string()
  {
    switch (this) {
      case VOID:   return "void";
      case INT:    return "jint";
      case BOOL:   return "jboolean";
      case STRING: return "jstring";
      default:     return "";
    }
  }
}

