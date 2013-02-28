package org.axgl.render
{
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;

	import org.axgl.Ax;
	import org.axgl.AxSprite;

	import org.axgl.util.AxCache;

	public class SimpleFilter
	{
		public var enabled:Boolean = true;
		protected var matrix:Matrix3D;

		public function SimpleFilter(projection:Matrix3D = null)
		{
			matrix = (projection != null) ? projection : Ax.camera.baseProjection;
		}

		public function apply(source:AxTexture, destination:AxTexture = null):void
		{
			if (!enabled) return;

			if (destination)
			{
				Ax.context.setRenderToTexture(destination.texture, false, 0);
			}
			else
			{
				Ax.context.setRenderToBackBuffer();
			}
			Ax.context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			var vertexBuffer:VertexBuffer3D = AxCache.vertexBuffer(source.width, source.height, source.width/source.rawWidth, source.height/source.rawHeight);
			Ax.context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			Ax.context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);

			setupShader(source);

			Ax.context.drawTriangles(AxSprite.SPRITE_INDEX_BUFFER, 0, 2);
		}


		protected static const SIMPLE_VERTEX_SHADER:Array = [
			"mov v1, va1", "m44 op, va0, vc0"
		];
		protected static const SIMPLE_FRAGMENT_SHADER:Array = [
			"tex oc, v1, fs0 <2d,nearest,mipnone>"
		];

		protected function setupShader(source:AxTexture):void
		{
			var shader:AxShader = AxCache.shader("simple_post_process_shader", SIMPLE_VERTEX_SHADER, SIMPLE_FRAGMENT_SHADER, 4);
			Ax.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, Ax.camera.baseProjection, true);
			Ax.context.setTextureAt(0, source.texture);
			Ax.context.setProgram(shader.program);
			Ax.shader = shader;
		}
	}
}
