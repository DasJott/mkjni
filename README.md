mkjni
=====

Call Vala code from Java

You can write libraries in Vala to be used from Java to speed up parts of that slow language.
Simply specify the vala file and the class within it to be made "public" to the Java code.
This tool will create the Java and the C files you need to compile a JNI library to be called from Java.

By now you must only use string, int or void as parameters and return types.

The arguments for mkjni are to be specified as follows:

Must-have:

-f, --file <vala file>    A valid vala file to start with

-c, --class <class name>  A class within the vala file to generate the jni from

-l, --lib <lib name>      Please specify how the library will be named
                          This is for the call to loadLibrary within the Java file
                          and can be changed manually later
                          Please specify w/o lib prefix and .so suffix!


Options:

-p, --pkg <package>       The Java package (namespace) to be created

-h, --help for showing help

Note: mkjni creates all files (and directories for java packages) in the directory where it is called.

Example:

  mkjni -f myclass.vala -c MyClass -p de.dasjott.myclass -l superjni


After the files are generated you can compile your lib which is included by the java class:

  gcc -shared -fPIC $(pkg-config --cflags --libs glib-2.0) -I/usr/lib/jvm/java-1.7.0-openjdk-amd64/include -olibsuperjni.so myclass.c de_dasjott_myclass_MyClass.c

while the -I parameter has to specify the directory where to find the jni.h!

