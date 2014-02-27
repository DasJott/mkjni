# Make file for mkjni
# Written by Akshay Shekher <voldyman666@gmail.com>

sourcefiles = src/classinfo.vala src/function.vala src/jnifiles.vala src/valafile.vala src/datatype.vala src/javafile.vala src/main.vala

all: clean
	mkdir build
	valac --quiet --pkg gtk+-3.0 -o build/mkjni ${sourcefiles}

clean:
	if [ -a build] ; \
	then\
		rm -r build/; \
	fi;
