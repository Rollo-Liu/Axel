package org.axgl.render {

import flash.display3D.Context3DProgramType;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;

import org.axgl.Ax;
import org.axgl.AxU;

//TODO assign textures using var name (same as constants right now)
//TODO refactor - move shader in separate class and use this class to get fragment and vertex shaders together
public class GlslShader extends AxShader {
	public static function fromFiles(vertexShader:ByteArray, fragmentShader:ByteArray):GlslShader {
		var vs:String = vertexShader.toString();
		var fs:String = fragmentShader.toString();
		return new GlslShader(JSON.parse(vs), JSON.parse(fs));
	}

	public function GlslShader(vertexShader:Object, fragmentShader:Object) {
		AxU.assert(vertexShader['agalasm'], "Wrong vertex shader supplied");
		AxU.assert(fragmentShader['agalasm'], "Wrong fragment shader supplied");
		super(vertexShader['agalasm'].replace(/\n+/g, "\n").split('\n'), fragmentShader['agalasm'].replace(/\n+/g, "\n").split('\n'), 4);
		loadConsts(Context3DProgramType.VERTEX, vertexShader['consts']);
		loadConsts(Context3DProgramType.FRAGMENT, fragmentShader['consts']);
		loadVars(Context3DProgramType.VERTEX, vertexShader['varnames']);
		loadVars(Context3DProgramType.FRAGMENT, fragmentShader['varnames']);
	}

	public var textures:Vector.<AxTexture> = new Vector.<AxTexture>;
	protected var fragmentConstants:Array = [];
	protected var vertexConstants:Array = [];
	protected var vertexVars:Object = {};
	protected var fragmentVars:Object = {};
	protected var fragmentVarValues:Object = {};
	protected var vertexVarValues:Object = {};

	public function dispose():void {
		program.dispose();
	}

	public function setFragmentVarVector(name:String, value:Vector.<Number>):void {
		AxU.assert(value.length == 4, "Fragment vector should be of length 4");
		AxU.assert(fragmentVars[name] != undefined, "Wrong var name: " + name);
		fragmentVarValues[name] = value;
	}

	public function setVertexVarVector(name:String, value:Vector.<Number>):void {
		AxU.assert(value.length == 4, "Vertex vector should be of length 4");
		AxU.assert(vertexVars[name] != undefined, "Wrong var name: " + name);
		vertexVarValues[name] = value;
	}

	public function setVertexVarMatrix(name:String, value:Matrix3D):void {
		AxU.assert(vertexVars[name] != undefined, "Wrong var name: " + name);
		vertexVarValues[name] = value;
	}

	public function apply():void {
		applyConstantType(Context3DProgramType.VERTEX);
		applyConstantType(Context3DProgramType.FRAGMENT);
		applyVars(Context3DProgramType.VERTEX);
		applyVars(Context3DProgramType.FRAGMENT);
	}

	public function setTexture(i:uint, value:AxTexture):GlslShader {
		textures[i] = value;
		return this;
	}

	protected function loadConsts(type:String, consts:Object):void {
		if (consts) {
			for (var key:String in consts) {
				if (!consts.hasOwnProperty(key)) continue;
				var i:int = int(key.charAt(2));
				if (type == Context3DProgramType.VERTEX) {
					setVertexVector(i, Vector.<Number>(consts[key]));
				}
				else if (type == Context3DProgramType.FRAGMENT) {
					setFragmentVector(i, Vector.<Number>(consts[key]));
				}
			}
		}
	}

	protected function loadVars(type:String, vars:Object):void {
		if (vars) {
			var constants:Object = (type == Context3DProgramType.VERTEX) ? vertexConstants : fragmentConstants;
			for (var key:String in vars) {
				if (!vars.hasOwnProperty(key)) continue;
				if (vars[key].search(/[vf]c\d+/) == -1) continue; //Is not constant
				var i:int = int(vars[key].substr(2));
				if (constants[i] != undefined) continue; // Is local constant
				if (type == Context3DProgramType.VERTEX) {
					vertexVars[key] = i;
				}
				else if (type == Context3DProgramType.FRAGMENT) {
					fragmentVars[key] = i;
				}
			}
		}
	}

	protected function applyVars(type:String):void {
		AxU.assert(type == Context3DProgramType.VERTEX || type == Context3DProgramType.FRAGMENT);
		var varNames:Object = (type == Context3DProgramType.VERTEX) ? vertexVars : fragmentVars;
		var varValues:Object = (type == Context3DProgramType.VERTEX) ? vertexVarValues : fragmentVarValues;
		for (var name:String in varNames) {
			if (!varNames.hasOwnProperty(name)) continue;
			AxU.assert(varValues[name] != undefined, type + " var " + name + " is not set");
			if (varValues[name] is Vector.<Number>) {
				Ax.context.setProgramConstantsFromVector(type, varNames[name], varValues[name]);
			}
			else if (varValues[name] is Matrix3D) {
				Ax.context.setProgramConstantsFromMatrix(type, varNames[name], varValues[name], true);
			}
			else {
				throw new Error("Wrong constant type");
			}
		}
	}

	protected function applyConstantType(type:String):void {
		AxU.assert(type == Context3DProgramType.VERTEX || type == Context3DProgramType.FRAGMENT);
		var constants:Array = (type == Context3DProgramType.VERTEX) ? vertexConstants : fragmentConstants;

		for (var i:int = 0; i < constants.length; i++) {
			if (!constants[i]) continue;
			if (constants[i] is Vector.<Number>) {
				Ax.context.setProgramConstantsFromVector(type, i, constants[i]);
			}
			else if (constants[i] is Matrix3D) {
				Ax.context.setProgramConstantsFromMatrix(type, i, constants[i], true);
			}
			else {
				throw new Error("Wrong constant type");
			}
		}
	}

	protected function setFragmentVector(i:uint, value:Vector.<Number>):GlslShader {
		AxU.assert(value.length == 4, "Frament vector should be of length 4");
		fragmentConstants[i] = value;
		return this;
	}

	protected function setFragmentMatrix(i:uint, value:Matrix3D):GlslShader {
		fragmentConstants[i] = value;
		return this;
	}

	protected function setVertexVector(i:uint, value:Vector.<Number>):GlslShader {
		AxU.assert(value.length == 4, "Vertex vector should be of length 4");
		vertexConstants[i] = value;
		return this;
	}

	protected function setVertexMatrix(i:uint, value:Matrix3D):GlslShader {
		vertexConstants[i] = value;
		return this;
	}
}
}
