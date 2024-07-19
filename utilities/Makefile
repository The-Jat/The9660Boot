.PHONY: all clean

all: build_dir build/Read9660


build_dir:
	mkdir -p build

build/Read9660: Read9660.c
	gcc $< -o $@

run:
	./build/Read9660 ../image.iso
clean:
	rm -rf build

