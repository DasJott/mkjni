# mkjni

## Call Vala code from Java

Vala code might be faster or just better to write or simply more beautiful.<br/>
Write some functionality in Vala, specify a class you want to "export" to Java and mkjni creates a jni lib and the Java Class for you.<br/>
So it feels like you could call the Vala class from Java!<br/>

## Limitations:
### Only possible types:
You *MUST ONLY* use the following types: string, int, int8, double, float, char, bool, string[], int[], int8[], float[], double[], char[]<br/>
**The type int8 in Vala is transformed to byte in Java! So is int8[] in Vala transformed to byte[] in Java**<br/>
<br/>
There is created only *ONE* instance of the Vala class, not matter how many instances you create in Java!<br/>
It is only tested on Ubuntu Linux and won't run on Windows. This might change in the future.<br/>

## Usage
  **mkjni [PARAMS][OPTIONS] &lt;FILE(S)&gt;**

### Params (must-have):

Parameter                      | Description
------------------------------ | -----------------------------------------------------
-c, --class &lt;class name&gt; | A class within the vala file to generate the jni from
-l, --lib &lt;lib name&gt;     | Please specify the desired name of the library<br/>The name is w/o lib prefix and .so suffix!

### Options:

Option                         | Description
------------------------------ | ----------------------------------------------------
-p, --pkg &lt;package(s)&gt;   | Packages to be included (Vala --pkg and pkg-config) &#42;
-j, --jns &lt;package&gt;      | The Java namespace (package) to be created
-cc &lt;compiler&gt;           | The compiler to be used (default: gcc)
-X --ccmd &lt;command(s)&gt;   | Additional command, passed to the compiler &#42;
-V --vcmd &lt;command(s)&gt;   | Additional command, passed to valac &#42;
-e --ext &lt;lib(s)&gt;        | External dependency's library name. Don't forget the the vapi file. &#42;
-d                             | Create Java file in package directory
-n                             | Not compile, just generate files
-o                             | Only compile, do not link
-t                             | Use tmp directory for processing
-v                             | Verbose - tell what's going on
-h, --help                     | for showing help

&#42;) *This option can be used multiple times in one call or takes comma separated list*<br/>
<br/>
**Note: mkjni creates all files (and directories for java packages) in the directory where it is called.**

## Examples:
  **mkjni -v -t -c MyClass -j de.dasjott.myclass -l superjni *.vala**<br/>
  **mkjni -v -t -c MyClass -j de.dasjott.myclass -l superjni -e addlib addlib.vapi *.vala**<br/>
  **mkjni -c MyClass -l superjni -V --disable-assert -V --target-glib=2.32 -X -O3 -p gio-1.0 *.vala**<br/>
  **mkjni -c MyClass -l superjni -V --disable-assert,--target-glib=2.32 -X -O3 -p gio-1.0 *.vala**<br/>

You should be provided with a result like libsuperjni.so for these examples and a Java file MyClass.java in your current directory.

## Bugs
If you find bugs, don't feed them, so they'll die over time.<br/>
You could as well fix them yourself, as you have the code.<br/>
Or you just call me to come by to squish them. Maybe I will ;)<br/>
