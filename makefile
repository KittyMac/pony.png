all: check-folders copy-libs
	stable env /Volumes/Development/Development/pony/ponyc/build/release/ponyc -p ./lib -o ./build/ ./png
	./build/png

check-folders:
	@mkdir -p ./build

copy-libs:
	@cp ../pony.bitmap/lib/*.a ./lib/

test: check-folders copy-libs
	stable env /Volumes/Development/Development/pony/ponyc/build/release/ponyc -V=0 -p ./lib -o ./build/ ./png
	./build/png