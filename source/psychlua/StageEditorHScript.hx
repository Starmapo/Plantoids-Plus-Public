package psychlua;

class StageEditorHScript extends BaseHScript
{
	override function preset()
	{
		super.preset();

		for (func in ["debugPrint", "createGlobalCallback"])
			set(func, function() {});

		set('customSubstate', null);
		set('customSubstateName', "unnamed");
	}
}
