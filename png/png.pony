use "fileExt"
use "flow"

use "path:/usr/lib" if osx
use "lib:png"

use @memcpy[Pointer[None]](dst: Pointer[None], src: Pointer[None], n: USize)

struct PNGReadFnStruct
	var offset:USize
	let data:Pointer[U8] tag
	
	new create(data':Pointer[U8] tag) =>
		data = data'
		offset = 0

actor PNG

	let target:Flowable tag

	new create(target':Flowable tag) =>
		target = target'
	
	fun readNow(filePath:String):Bitmap iso^ ? =>
		let pngData = FileExt.fileToByteBlock(filePath)?
		let null = Pointer[None]
	
		var offset:USize = 0		
		if @png_sig_cmp(pngData.cpointer(offset), 0, LIBPNG.png_sig_size()) != 0 then
			error
		end
	
		let malloc_fn = @{(png_ptr:Pointer[_PngStruct], size:USize):Pointer[U8] =>
			if size == 0 then
				Pointer[None]
			end
			@pony_malloc(size)
		}
		let free_fn = @{(png_ptr:Pointer[_PngStruct], ptr:Pointer[None]) => 
			@pony_free(ptr)
		}
		let read_fn = @{(png_ptr:Pointer[_PngStruct] tag, data:Pointer[None], length:USize) => 
			let readStructPtr = @png_get_io_ptr[NullablePointer[PNGReadFnStruct]](png_ptr)
			try
				var readStruct = readStructPtr()?
				 @memcpy(data, readStruct.data.offset(readStruct.offset), length)
				readStruct.offset = readStruct.offset + length
			end
		}
				
		let pngPtr = @png_create_read_struct_2(LIBPNG.png_libpng_ver_string().cpointer(), null, null, null, null, malloc_fn, free_fn)
		if pngPtr.is_null() then
			error
		end
				
		let infoPtr = @png_create_info_struct(pngPtr)
		if infoPtr.is_null() then
			error
		end
				
		let readerInfo = PNGReadFnStruct(pngData.cpointer(0))
		@png_set_read_fn(pngPtr, NullablePointer[PNGReadFnStruct](readerInfo), read_fn)
		@png_set_sig_bytes(pngPtr, 0)
		@png_read_info(pngPtr, infoPtr)
	
		let bitdepth = @png_get_bit_depth(pngPtr, infoPtr)
		let channels = @png_get_channels(pngPtr, infoPtr)
		let color_type = @png_get_color_type(pngPtr, infoPtr)
				
		// Convert palette color to true color
		if color_type == LIBPNG.png_color_type_palette() then
			@png_set_palette_to_rgb[None](pngPtr)
		end
	
		// Convert low bit colors to 8 bit colors
		if bitdepth < 8 then
			if (color_type == LIBPNG.png_color_type_gray()) or (color_type == LIBPNG.png_color_type_gray_alpha()) then
				@png_set_expand_gray_1_2_4_to_8[None](pngPtr)
			else
				@png_set_packing[None](pngPtr)
			end
		end
	
		if @png_get_valid[Bool](pngPtr, infoPtr, LIBPNG.png_info_trns()) then
			@png_set_tRNS_to_alpha[None](pngPtr)
		end

		// Convert high bit colors to 8 bit colors
		if bitdepth == 16 then
			@png_set_strip_16[None](pngPtr)
		end

		// Convert gray color to true color
		if (color_type == LIBPNG.png_color_type_gray()) or (color_type == LIBPNG.png_color_type_gray_alpha()) then
			@png_set_gray_to_rgb[None](pngPtr)
		end

		// Update the changes
		@png_read_update_info[None](pngPtr, infoPtr)
	
		let height:USize = @png_get_image_height[USize](pngPtr, infoPtr)
		let width:USize = @png_get_image_width[USize](pngPtr, infoPtr)
	
		recover iso 
			let bitmap = Bitmap(width, height)
		
			// pass an array of row pointers to libpng, and it puts the bits into those
			let rowPointers = bitmap.rowPointers()
			@png_read_image[None](pngPtr, rowPointers)
			bitmap.rowPointersFree(rowPointers)
		
			bitmap
		end
	
	be read(filePath:String) =>		
		try
			let bitmap = readNow(filePath)?
			target.flowReceived(consume bitmap)
			target.flowFinished()
		else
			target.flowReceived(recover Bitmap(10,10) end)
			target.flowFinished()
		end
		
		
		
		
		
		
		

