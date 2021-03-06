package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	public class Utils
	{
		public static function getTexture(textureData : Class, context3D : Context3D) : Texture
		{
			if(null == context3D) return null;
			
			var myTextureData : Bitmap = new textureData;
			var texture : Texture = context3D.createTexture(myTextureData.width,myTextureData.height,Context3DTextureFormat.BGRA,false);
			var ws : int = myTextureData.bitmapData.width;
			var hs : int = myTextureData.bitmapData.height;
			var level : int = 0;
			var temp : BitmapData;
			var transform : Matrix = new Matrix();
			temp = new BitmapData(ws, hs, true, 0);
			while(ws >= 1 && hs >= 1){
				temp.draw(myTextureData.bitmapData, transform);
				texture.uploadFromBitmapData(temp, level);
				transform.scale(.5,.5);
				level++;
				ws >>= 1;
				hs >>= 1;
				if(hs && ws){ //如果宽高都大于0,则清除临时位图,并继续缩小绘制
					temp.dispose();
					temp = new BitmapData(ws,hs,true,0);
				}
			}
			temp.dispose();
			
			return texture;
		}
		
		public static function generateMipMapsCube(source : BitmapData, target : CubeTexture, side:uint, mipmap : BitmapData = null, alpha : Boolean = false) : void
		{
			var w : uint = source.width,
				h : uint = source.height;
			var i : uint;
			var regen : Boolean = mipmap != null;
			mipmap ||= new BitmapData(w, h, alpha);
			
			m_matrix.a = 1;
			m_matrix.d = 1;
			
			m_rect.width = w;
			m_rect.height = h;
			
			while (w >= 1 && h >= 1) {
				if (alpha) mipmap.fillRect(m_rect, 0);
				mipmap.draw(source, m_matrix, null, null, null, true);
				target.uploadFromBitmapData(mipmap,side, i++);
				w >>= 1;
				h >>= 1;
				m_matrix.a *= .5;
				m_matrix.d *= .5;
				m_rect.width = w;
				m_rect.height = h;
			}
			
			if (!regen)
				mipmap.dispose();
		}
		
		public static function getTextureByBmd(textureData : BitmapData, context3D : Context3D) : Texture
		{
			var texture : Texture = context3D.createTexture(textureData.width,textureData.height,Context3DTextureFormat.BGRA,false);
			var ws : int = textureData.width;
			var hs : int = textureData.height;
			var level : int = 0;
			var temp : BitmapData;
			var transform : Matrix = new Matrix();
			temp = new BitmapData(ws, hs, true, 0);
			while(ws >= 1 && hs >= 1){
				temp.draw(textureData, transform);
				texture.uploadFromBitmapData(temp, level);
				transform.scale(.5,.5);
				level++;
				ws >>= 1;
				hs >>= 1;
				if(hs && ws){ //如果宽高都大于0,则清除临时位图,并继续缩小绘制
					temp.dispose();
					temp = new BitmapData(ws,hs,true,0);
				}
			}
			temp.dispose();
			
			return texture;
		}
		
		public static function nextPowerOfTwo(v:uint): uint
		{
			v--;
			v |= v >> 1;
			v |= v >> 2;
			v |= v >> 4;
			v |= v >> 8;
			v |= v >> 16;
			v++;
			return v;
		}

		
		//计算平面投影矩阵，n为平面法向量，p为平面上一点
		public static function getReflectionMatrix(n:Vector3D,p:Vector3D):Vector.<Number>{
			n.normalize();
			var d:Number=-n.dotProduct(p);
			
			var raw:Vector.<Number>=Vector.<Number>([-2*n.x*n.x+1,-2*n.y*n.x,-2*n.z*n.x,0,
				-2*n.x*n.y,-2*n.y*n.y+1,-2*n.z*n.y,0,
				-2*n.x*n.z,-2*n.y*n.z,-2*n.z*n.z+1,0,
				-2*n.x*d,-2*n.y*d,-2*n.z*d,1]);
			return raw;
		}
		
		//计算光照投影矩阵
		public static function getShadowMatrix(n : Vector3D, p : Vector3D, light : Vector3D, out : Vector.<Number> = null) : Vector.<Number>
		{
			n.normalize();
			//平行光的话，需要标准化光线方向，并逆转平面法线
			if(light.w == 0){
				light.normalize();
				n.scaleBy(-1);
			}
			var d:Number=-n.dotProduct(p);
			var k:Number=n.x*light.x+n.y*light.y+n.z*light.z+d*light.w;
			
			if(null == out) out = new Vector.<Number>();
			
			out.push(k-n.x*light.x,	-n.x*light.y,	-n.x*light.z,	-n.x*light.w);
			out.push(-n.y*light.x,	k-n.y*light.y,	-n.y*light.z,	-n.y*light.w);
			out.push(-n.z*light.x,	-n.z*light.y,	k-n.z*light.z,	-n.z*light.w);
			out.push(-d*light.x,	-d*light.y,	-d*light.z,	k-d*light.w);
			
			return out;
		}
		
		//向量左乘矩阵
		public static function subjectMat(vec : Vector3D, mat : Matrix3D, out : Vector3D = null) : Vector3D
		{
			var data : Vector.<Number> = mat.rawData;
			
			out ||= new Vector3D();
			
			out.x = (vec.x * data[0] + vec.y * data[4] + vec.z * data[8] + vec.w * data[12]);
			out.y = (vec.x * data[1] + vec.y * data[5] + vec.z * data[9] + vec.w * data[13]);
			out.z = (vec.x * data[2] + vec.y * data[6] + vec.z * data[10] + vec.w * data[14]);
			out.w = (vec.x * data[3] + vec.y * data[7] + vec.z * data[11] + vec.w * data[15]);
			
			return out;
		}
		
		public static function subjectMat2(vec : Vector3D, mat : Matrix3D, out : Vector3D = null) : Vector3D
		{
			var data : Vector.<Number> = mat.rawData;
			
			out ||= new Vector3D();
			
			out.x = (vec.x * data[0] + vec.y * data[1] + vec.z * data[2] + vec.w * data[3]);
			out.y = (vec.x * data[4] + vec.y * data[5] + vec.z * data[6] + vec.w * data[7]);
			out.z = (vec.x * data[8] + vec.y * data[9] + vec.z * data[10] + vec.w * data[11]);
			out.w = (vec.x * data[12] + vec.y * data[13] + vec.z * data[14] + vec.w * data[15]);
			
			return out;
		}
		
		public static function lerp(a : Number, b : Number, t : Number) : Number
		{
			return a - (a * t) + (b * t);
		}
		
		private static var m_matrix		: Matrix = new Matrix();
		private static var m_rect			: Rectangle = new Rectangle();
		
		public static const WHITE			: uint = 0xffffffff;
		public static const BLACK			: uint = 0xff000000;
		public static const RED			: uint = 0xffff0000;
		public static const GREEN			: uint = 0xff00ff00;
		public static const BLUE			: uint = 0xff0000ff;
		public static const YELLOW 		: uint = 0xffffff00;
		public static const CYAN			: uint = 0xff00ffff;
		public static const MAGENTA		: uint = 0xffff00ff;
		
		public static const BEACH_SAND	: uint = 0xfffff99d;
		public static const DESERT_SAND	: uint = 0xfffacd87;
		
		public static const LIGHTGREEN	: uint = 0xff3cb878;
		public static const PUREGREEN		: uint = 0xff00a651;
		public static const DARKGREEN		: uint = 0xff007236;
		
		public static const LIGHT_YELLOW_GREEN	: uint = 0xff7cc576;
		public static const PURE_YELLOW_GREEN		: uint = 0xff39b54a;
		public static const DARK_YELLOW_GREEN		: uint = 0xff197b30;
		
		public static const LIGHTBROWN	: uint = 0xffc69c6d;
		public static const DARKBROWN 	: uint = 0xff736487;
	}
}