package;

import flixel.input.gamepad.FlxGamepad;
import openfl.Lib;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var curSelected:Int = 0;

	#if cpp
	var pauseMusic:FlxSound;
	var perSongOffset:FlxText;

	var offsetChanged:Bool = false;
	var lastOffset:Float = 0;
	var oldOffset:Float = 0;
	#end

	public function new(x:Float, y:Float)
	{
		super();

		#if cpp
		oldOffset = lastOffset = PlayState.songOffset;
		#end

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += Difficulty.fromInt(PlayState.storyDifficulty).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		#if cpp
		perSongOffset = new FlxText(5, FlxG.height - 18, 0, "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds value to global offset, per song.', 12);
		perSongOffset.scrollFactor.set();
		perSongOffset.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(perSongOffset);
		#end

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upPcontroller:Bool = false;
		var downPcontroller:Bool = false;
		var leftPcontroller:Bool = false;
		var rightPcontroller:Bool = false;
		var oldOffset:Float = 0;
		var accepted:Bool = controls.ACCEPT;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && KeyBinds.gamepad)
		{
			upPcontroller = gamepad.justPressed.DPAD_UP;
			downPcontroller = gamepad.justPressed.DPAD_DOWN;
			leftPcontroller = gamepad.justPressed.DPAD_LEFT;
			rightPcontroller = gamepad.justPressed.DPAD_RIGHT;
		}

		if (controls.UP_P || upPcontroller)
		{
			changeSelection(-1);
		}
		else if (controls.DOWN_P || downPcontroller)
		{
			changeSelection(1);
		}
		#if cpp
		else if (controls.LEFT_P || leftPcontroller)
		{
			PlayState.songOffset -= 1;
		}
		else if (controls.RIGHT_P || rightPcontroller)
		{
			PlayState.songOffset += 1;
		}

		if(accepted && oldOffset != PlayState.songOffset) {
			// pre lowercasing the song name (update)
			var songPath = 'assets/data/' + Song.fixSongname(PlayState.SONG.song) + '/';
			trace('Changing Offset from $oldOffset to ${PlayState.songOffset}');
			sys.FileSystem.rename(songPath + oldOffset + '.offset', songPath + PlayState.songOffset + '.offset');
		}

		if(lastOffset != PlayState.songOffset) {
			perSongOffset.text = "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds the value to offset on the song.';
			lastOffset = PlayState.songOffset;

			if(!offsetChanged)
			{
				grpMenuShit.clear();

				menuItems = ['Restart Song', 'Exit to menu'];

				for (i in 0...menuItems.length)
				{
					var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
					songText.isMenuItem = true;
					songText.targetY = i;
					grpMenuShit.add(songText);
				}

				changeSelection();

				cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
				offsetChanged = true;
			}
		}
		#end

		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					FlxG.resetState();
				case "Exit to menu":
					PlayState.loadRep = false;
					PlayState.instance.destoryStuff();
					if (FlxG.save.data.fpsCap > 290)
						(cast (Lib.current.getChildAt(0), Main)).setFPSCap(290);

					FlxG.switchState(new MainMenuState());
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var i:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = i - curSelected;
			i++;

			if (item.targetY == 0)
				item.alpha = 1;
			else
				item.alpha = 0.6;
		}
	}
}