use "fileExt"
use "ponytest"
use "files"
use "flow"

use @sleep[I32](seconds: I32)

actor Main is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None

	fun tag tests(test: PonyTest) =>
		//test(_TestClear)
		//test(_TestFillRect)
		//test(_TestBlit)
		//test(_TestBlitOutside)
		
		test(_TestReadPNG)




actor Sprite is Flowable
	// test actor to read a PNG and save it back to a file
	
	be flowFinished() =>
		true
	
	be flowReceived(dataIso:Any iso) =>
		try
			let bitmap = (consume dataIso) as Bitmap
			FileExt.bitmapToFile(bitmap, "/tmp/png.raw")?
		end
	
	be read(filePath:String) =>
		let png = PNG(this)
		png.read(filePath)


class iso _TestReadPNG is UnitTest
	fun name(): String => "read png"

	fun apply(h: TestHelper) =>
		Sprite.read("sample.png")
	



class iso _TestClear is UnitTest
	fun name(): String => "bitmap clear"

	fun apply(h: TestHelper) =>
		let b = Bitmap(100, 100)
		b.clear(RGBA.blue())
		try
			FileExt.bitmapToFile(b, "/tmp/clear.raw")?
		end
		

class iso _TestFillRect is UnitTest
	fun name(): String => "bitmap fill rect"

	fun apply(h: TestHelper) =>
		let b = Bitmap(100, 100)
		b.fillRect(Rect(0,0,50,50), RGBA(255,0,0,255))
		b.fillRect(Rect(50,0,50,50), RGBA(0,255,0,255))
		b.fillRect(Rect(50,50,50,50), RGBA(0,0,255,255))
		b.fillRect(Rect(0,50,50,50), RGBA(255,255,0,255))
		try
			FileExt.bitmapToFile(b, "/tmp/fillRect.raw")?
		end

class iso _TestBlit is UnitTest
	fun name(): String => "bitmap blit"

	fun apply(h: TestHelper) =>
		let b = Bitmap(100, 100)
		b.clear(RGBA(255,255,255,255))
		
		let c = Bitmap(50, 50)
		c.clear(RGBA(0,0,0,255))
		
		b.blit(25, 25, c)
		
		try
			FileExt.bitmapToFile(b, "/tmp/blit.raw")?
		end

class iso _TestBlitOutside is UnitTest
	fun name(): String => "bitmap blit outside"

	fun apply(h: TestHelper) =>
		let b = Bitmap(100, 100)
		b.clear(RGBA(255,255,255,255))

		let c = Bitmap(50, 50)
		c.clear(RGBA(0,0,0,255))

		b.blit(75, 75, c)

		try
			FileExt.bitmapToFile(b, "/tmp/blit_outside.raw")?
		end
