all: copy-libs
	stable env /Volumes/Development/Development/pony/ponyc/build/release/ponyc -p ./lib -o ./build/ ./png
	./build/png

copy-libs:
	@cp ../pony.bitmap/lib/*.a ./lib/

