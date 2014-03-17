# mkjni

## Call Vala code from Java

Vala code might be faster or just better to write orsimply more beautiful.
Write some functionality in Vala, specify a class you want to "export" to Java and mkjni creates a jni lib and the Java Class for you.
So it feels like you could call the Vala class from Java!

## Limitations:
**Parameters and return types must be string, int, bool ot void!**

## Usage
  **mkjni [PARAMS][OPTIONS] &lt;FILE(S)&gt;**

### Params (must-have):

-------------------------------|-----------------------------------------------------
-c, --class &lt;class name&gt; |A class within the vala file to generate the jni from
-l, --lib &lt;lib name&gt;     |Please specify the desired name of the library
                               |The name is w/o lib prefix and .so suffix!

### Options:
-------------------------------|-----------------------------------------------------
-p, --pkg &lt;package&gt;      |Packages to be included (Vala --pkg and pkg-config)
-j, --jns &lt;package&gt;      |The Java namespace (package) to be created
-cc &lt;compiler&gt;           |The compiler to be used (default: gcc)
-d                             |Create Java file in package directory
-n                             |Not compile, just generate files
-o                             |Only compile, do not link
-t                             |Use tmp directory for processing
-v                             |Verbose - tell what's going on
-h, --help                     |for showing help


**Note: mkjni creates all files (and directories for java packages) in the directory where it is called.**

## Example:

  **mkjni -v -t -c MyClass -j de.dasjott.myclass -l superjni *.vala**

You should be provided with a result like libsuperjni.so for this example and a Java file MyClass.java in your current directory.

## Bugs
If you find bugs, don't feed them, so they'll die over time.
You could as well fix them yourself, as you have the code.
Or you just call me to come by to squish them. Maybe I will ;)
