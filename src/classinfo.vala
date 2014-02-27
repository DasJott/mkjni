/*
 * classinfo.vala
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


public class Class
{
  public Class(string sName) { name = sName; }
  public string name = "";
  public List<Class.Method> methods = new List<Class.Method>();

  public string c_getConstructor()
  {
    return name + "_new()";
  }
  public string c_getName(Method oMethod)
  {
    return name + "_" + oMethod.name;
  }

  public class Method
  {
    // TODO: space for c functions to be called from jni
    public Method(string sName) { name = sName; }
    public string name = "";
    public DataType returnType = DataType.NONE;
    public bool isStatic = false;
    public List<Class.Method.Parameter> params = new List<Class.Method.Parameter>();

    public class Parameter
    {
      public Parameter(string sName) { name = sName;}
      public string name = "";
      public DataType type = DataType.NONE;
      public string direction = "";
    }
  }
}


