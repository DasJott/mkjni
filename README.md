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
-l, --lib <lib name>      Please specify the desired name of the library
                          The name is w/o lib prefix and .so suffix!


Options:

-p, --pkg <package>       Packages to be included (Vala --pkg and pkg-config)
-j, --jns <package>       The Java namespace (package) to be created
-d                        Create Java file in package directory
-o                        Only compile, do not link
-t                        Use tmp directory for processing
-v                        Verbose - tell what's going on

-h, --help                for showing help


Note: mkjni creates all files (and directories for java packages) in the directory where it is called.

Example:

  mkjni -v -t -f myclass.vala -c MyClass -j de.dasjott.myclass -l superjni

You should be provided with a result like libsuperjni.so for this example and a Java file MyClass.java in your current directory.
