package psychlua;

import Type.ValueType;
import haxe.Constraints;
import substates.GameOverSubstate;

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
//
class ReflectionFunctions
{
	public static function implement(funk:BaseLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "getProperty", function(variable:String, ?allowMaps:Bool = false)
		{
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
				return funk.getVarInArray(funk.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], allowMaps);
			return funk.getVarInArray(funk.getTargetInstance(), variable, allowMaps);
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false)
		{
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				funk.setVarInArray(funk.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], value, allowMaps);
				return true;
			}
			funk.setVarInArray(funk.getTargetInstance(), variable, value, allowMaps);
			return true;
		});
		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false)
		{
			var myClass:Dynamic = Type.resolveClass(classVar);
			if (myClass == null)
			{
				funk.onError('getPropertyFromClass: Class $classVar not found');
				return null;
			}

			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				var obj:Dynamic = funk.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length - 1)
					obj = funk.getVarInArray(obj, split[i], allowMaps);

				return funk.getVarInArray(obj, split[split.length - 1], allowMaps);
			}
			return funk.getVarInArray(myClass, variable, allowMaps);
		});
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false)
		{
			var myClass:Dynamic = Type.resolveClass(classVar);
			if (myClass == null)
			{
				funk.onError('getPropertyFromClass: Class $classVar not found');
				return null;
			}

			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				var obj:Dynamic = funk.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length - 1)
					obj = funk.getVarInArray(obj, split[i], allowMaps);

				funk.setVarInArray(obj, split[split.length - 1], value, allowMaps);
				return value;
			}
			funk.setVarInArray(myClass, variable, value, allowMaps);
			return value;
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false)
		{
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if (split.length > 1)
				realObject = funk.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(funk.getTargetInstance(), obj);

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable, allowMaps);
				return result;
			}

			var leArray:Dynamic = realObject[index];
			if (leArray != null)
			{
				var result:Dynamic = null;
				if (Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = LuaUtils.getGroupStuff(leArray, variable, allowMaps);
				return result;
			}
			funk.onError("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!");
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false)
		{
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if (split.length > 1)
				realObject = funk.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(funk.getTargetInstance(), obj);

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				LuaUtils.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			var leArray:Dynamic = realObject[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt)
				{
					leArray[variable] = value;
					return value;
				}
				LuaUtils.setGroupStuff(leArray, variable, value, allowMaps);
			}
			return value;
		});
		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false)
		{
			var groupOrArray:Dynamic = Reflect.getProperty(funk.getTargetInstance(), obj);
			if (Std.isOfType(groupOrArray, FlxTypedGroup))
			{
				var sex = groupOrArray.members[index];
				if (!dontDestroy)
					sex.kill();
				groupOrArray.remove(sex, true);
				if (!dontDestroy)
					sex.destroy();
				return;
			}
			groupOrArray.remove(groupOrArray[index]);
		});

		Lua_helper.add_callback(lua, "callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null)
		{
			return funk.callMethodFromObject(funk.game, funcToRun, args);
		});
		Lua_helper.add_callback(lua, "callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null)
		{
			return funk.callMethodFromObject(Type.resolveClass(className), funcToRun, args);
		});

		Lua_helper.add_callback(lua, "createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null)
		{
			variableToSave = variableToSave.trim().replace('.', '');
			if (!funk.game.variables.exists(variableToSave))
			{
				if (args == null)
					args = [];
				var myType:Dynamic = Type.resolveClass(className);

				if (myType == null)
				{
					funk.onError('createInstance: Variable $variableToSave is already being used and cannot be replaced!');
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);
				if (obj != null)
					funk.game.variables.set(variableToSave, obj);
				else
					funk.onError('createInstance: Failed to create $variableToSave, arguments are possibly wrong.');

				return (obj != null);
			}
			else
				funk.onError('createInstance: Variable $variableToSave is already being used and cannot be replaced!');
			return false;
		});
		Lua_helper.add_callback(lua, "addInstance", function(objectName:String, ?inFront:Bool = false)
		{
			if (funk.game.variables.exists(objectName))
			{
				var obj:Dynamic = funk.game.variables.get(objectName);
				funk.addObject(obj);
			}
			else
				funk.onError('addInstance: Can\'t add what doesn\'t exist~ ($objectName)');
		});
	}

	static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if (args == null)
			args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		// trace('start: $obj');
		if (obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = LuaUtils.getVarInArray(obj, split[i].trim());
			// trace(obj, split[i]);
		}

		funcToRun = cast obj;
		// trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}
}
