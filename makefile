bitmap_lib_dir=../pony.bitmap/lib

all: check-folders copy-libs
	corral run -- ponyc -p ./lib -o ./build/ ./png
	./build/png

test: check-folders copy-libs
	corral run -- ponyc -V=0 -p ./lib -o ./build/ ./png
	./build/png


check-folders:
	@mkdir -p ./build

copy-libs:
	@cp ${bitmap_lib_dir}/*.a ./lib/


	
corral-fetch:
	@corral clean -q
	@corral fetch -q

corral-local:
	-@rm corral.json
	-@rm lock.json
	@corral init -q
	@corral add /Volumes/Development/Development/pony/pony.fileExt -q
	@corral add /Volumes/Development/Development/pony/pony.flow -q
	@corral add /Volumes/Development/Development/pony/pony.bitmap -q
	@corral add ./ -q

corral-git:
	-@rm corral.json
	-@rm lock.json
	@corral init -q
	@corral add github.com/KittyMac/pony.fileExt.git -q
	@corral add github.com/KittyMac/pony.flow.git -q
	@corral add github.com/KittyMac/pony.bitmap.git -q
	@corral add ./ -q

ci: bitmap_lib_dir = ./_corral/github_com_KittyMac_pony_bitmap/lib/
ci: corral-git corral-fetch all

dev: corral-local corral-fetch all