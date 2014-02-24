mkjni
=====

Call Vala code from Java

Creates a Java class from a Vala class to be called from within Java using the Java Native Interface (JNI).
You can write libraries in Vala to be used from Java to speed up parts of that badass slow language.
Simply specify the vala file and the class within it to be made "public" to the Java code. This tiny mkjni will create the Java and the C files you need to compile a JNI library.

This is the initial release and it is limited. You must only use string, int or void as parameter and return types.
Also the arguments for mkjni are to be specified in a certain row:

1: vala file
2: vala class
3: java package
4: lib name

Note: mkjni creates all files (and directories for java packages) in the directory where it is called.

Example:

mkjni myclass.vala MyClass de.dasjott.myclass firstclass

The lib name is needed to be included within the java file, but it can be changed manually afterwards as well.

After the files are generated you can compile your lib which is included by the java class.

