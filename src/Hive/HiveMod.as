package Hive 
{
	import Bezel.Bezel;
	import Bezel.BezelCoreMod;
	import Bezel.Lattice.Lattice;
	import Bezel.Logger;
	import Bezel.Utils.Keybind;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	
	/**
	 * ...
	 * @author Shy
	 */
	public class HiveMod extends MovieClip implements BezelCoreMod
	{
		public static const MODIFIER_KEY: String = "(Hive) Alternate building type modifier";
		
		public function get VERSION(): String { return "0.0.1"; }
		public function get GAME_VERSION(): String { return "1.2.1a"; }
		public function get BEZEL_VERSION(): String { return "2.0.6"; }
		public function get MOD_NAME(): String { return "Hive"; }
		
		CONFIG::debug
		public function get COREMOD_VERSION(): String { return String(Math.random()); }
		CONFIG::release
		public function get COREMOD_VERSION(): String { return VERSION; }
		
		internal static var bezel: Bezel;
		internal static var logger: Logger;
		internal static var instance: HiveMod;
		internal static var gameObjects: Object;
		
		public static var modifierKeyPressed: Boolean;
		
		public function HiveMod()
		{
			super();
			
			instance = this;
			logger = Logger.getLogger(MOD_NAME);
		}
		
		public function bind(modLoader: Bezel, gameObjects: Object): void
		{
			bezel = modLoader;
			HiveMod.gameObjects = gameObjects;
			
			addEventListeners();
		}
		
		public function unload(): void
		{
			removeEventListeners();
		}
		
		public function loadCoreMod(lattice: Lattice): void
		{
			addTowerWaspField(lattice);
			addTowerShotWaspField(lattice);
			addIngameCreatorCreateTowerShotTypeCheck(lattice);
			addBuildTowerCoremod(lattice);
			addIngameControllerTowerShotHitsTargetTypeCheck(lattice);
		}
		
		private function addEventListeners(): void
		{
			gameObjects.main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, true);
			gameObjects.main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, true);
		}
		
		private function removeEventListeners(): void
		{
			gameObjects.main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, true);
			gameObjects.main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp, true);
		}
		
		private function onKeyDown(e: KeyboardEvent): void
		{
			modifierKeyPressed = e.altKey;
		}
		
		private function onKeyUp(e: KeyboardEvent): void
		{
			modifierKeyPressed = e.altKey;
		}
		
		private function addTowerWaspField(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/entity/Tower.class.asasm";
			
			var offset: int = lattice.findPattern(FILE_NAME, /trait slot QName\(PackageNamespace\(""\), "notShootingSleepingHive"\)/);
			
			logger.log("", "Applying Tower Coremod: " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset - 1,
				0,
				'trait slot QName(PackageNamespace(""), "isWasp") type QName(PackageNamespace(""), "Boolean") value False() end'
			);
		}
		
		private function addTowerShotWaspField(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/entity/TowerShot.class.asasm";
			
			var offset: int = lattice.findPattern(FILE_NAME, /trait slot QName\(PackageNamespace\(""\), "ctr"\)/);
			
			logger.log("", "Applying TowerShot Coremod: " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset - 1,
				0,
				'trait slot QName(PackageNamespace(""), "isWasp") type QName(PackageNamespace(""), "Boolean") value False() end'
			);
		}
		
		private function addIngameCreatorCreateTowerShotTypeCheck(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameCreator.class.asasm";
			
			var offset: int = lattice.findPattern(FILE_NAME, /trait method QName\(PackageNamespace\(""\), "createTowerShot"\)/);
			offset = lattice.findPattern(FILE_NAME, /setlocal 8/, offset);
			
			logger.log("", "Applying IngameCreator::createTowerShot Coremod: " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset,
				0,
				' \
				getlocal 8 \n \
				getlocal1 \n \
				getproperty QName(PackageNamespace(""), "isWasp") \
				setproperty QName(PackageNamespace(""), "isWasp") \
				'
			);
		}
		
		private function addIngameControllerTowerShotHitsTargetTypeCheck(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameController.class.asasm";
			
			var offset: int = lattice.findPattern(FILE_NAME, /trait method QName\(PackageNamespace\(""\), "towerShotHitsTarget"\)/);
			offset = lattice.findPattern(FILE_NAME, /getproperty QName\(PackageNamespace\(""\), "_showShotImpactEffects"\)/, offset);
			
			logger.log("", "Applying IngameController Coremod (Part 1): " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset - 2,
				0,
				' \
				getlocal1 \n \
				getproperty QName(PackageNamespace(""), "isWasp") \n \
				iffalse notwasp \n \
				getlocal0 \n \
				getproperty QName(PackageNamespace(""), "core") \n \
				getproperty QName(PackageNamespace(""), "gemWasps") \n \
				findpropstrict QName(PackageNamespace("com.giab.games.gcfw.entity"), "GemWasp") \n \
				getlocal1 \n \
				getproperty QName(PackageNamespace(""), "originGem") \n \
				getlocal1 \n \
				getproperty QName(PackageNamespace(""), "lastX") \n \
				getlocal1 \n \
				getproperty QName(PackageNamespace(""), "lastY") \n \
				constructprop QName(PackageNamespace("com.giab.games.gcfw.entity"), "GemWasp"), 3 \n \
				callpropvoid QName(Namespace("http://adobe.com/AS3/2006/builtin"), "push"), 1 \n \
				jump wasp \n \
				notwasp: \
				'
			);
			
			offset = lattice.findPattern(FILE_NAME, /getproperty QName\(PackageNamespace\(""\), "cnt"\)/, offset);
			
			logger.log("", "Applying IngameController Coremod (Part 2): " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset - 2,
				0,
				'wasp:'
			);
		}
		
		private function addBuildTowerCoremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameCreator.class.asasm";
			
			var offset: int = lattice.findPattern(FILE_NAME, /trait method QName\(PackageNamespace\(""\), "buildTower"\)/);
			offset = lattice.findPattern(FILE_NAME, /setlocal 4/, offset);
			
			logger.log("", "Applying IngameCreator::buildTower Coremod: " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset,
				0,
				' \
				getlocal 4 \n \
				getlex QName(PackageNamespace("com.giab.games.gcfw"), "GV") \n \
				getproperty QName(PackageNamespace(""), "main") \n \
				getproperty QName(PackageNamespace(""), "bezel") \n \
				pushstring "' + MOD_NAME + '" \n \
				callproperty QName(PackageNamespace(""), "getModByName"), 1 \n \
				getproperty QName(PackageNamespace(""), "loaderInfo") \n \
				getproperty QName(PackageNamespace(""), "applicationDomain") \n \
				pushstring "Hive.HiveMod" \n \
				callproperty QName(PackageNamespace(""), "getDefinition"), 1 \n \
				getproperty QName(PackageNamespace(""), "modifierKeyPressed") \n \
				setproperty QName(PackageNamespace(""), "isWasp") \
				'
			);
		}
	}
}