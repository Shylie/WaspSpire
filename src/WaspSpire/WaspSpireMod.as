package WaspSpire 
{
	import Bezel.Bezel;
	import Bezel.BezelCoreMod;
	import Bezel.Lattice.Lattice;
	import Bezel.Logger;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Shy
	 */
	public class WaspSpireMod extends MovieClip implements BezelCoreMod
	{
		public function get VERSION(): String { return "0.0.1"; }
		public function get GAME_VERSION(): String { return "1.2.1a"; }
		public function get BEZEL_VERSION(): String { return "2.0.6"; }
		public function get MOD_NAME(): String { return "Wasp Spire"; }
		
		CONFIG::debug
		public function get COREMOD_VERSION(): String { return String(Math.random()); }
		CONFIG::release
		public function get COREMOD_VERSION(): String { return VERSION; }
		
		internal static var bezel: Bezel;
		internal static var logger: Logger;
		internal static var instance: WaspSpireMod;
		
		public function WaspSpireMod()
		{
			super();
			
			instance = this;
			logger = Logger.getLogger(MOD_NAME);
		}
		
		public function bind(modLoader: Bezel, gos: Object): void
		{
			bezel = modLoader;
		}
		
		public function unload(): void
		{
			
		}
		
		public function loadCoreMod(lattice: Lattice): void
		{
			addTowerShotWaspField(lattice);
			addIngameCreatorCreateTowerShotTypeCheck(lattice);
			addIngameControllerTowerShotHitsTargetTypeCheck(lattice);
		}
		
		private function addTowerShotWaspField(lattice: Lattice): void
		{
			var FILE_NAME: String = "com/giab/games/gcfw/entity/TowerShot.class.asasm";
			
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
			var FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameCreator.class.asasm";
			
			var offset: int = lattice.findPattern(FILE_NAME, /getlocal0\ngetproperty QName\(PackageNamespace\(""\), "core"\)\ngetproperty QName\(PackageNamespace\(""\), "towerShots"\)\ngetlocal 8\ncallpropvoid QName\(Namespace\("http:\/\/adobe.com\/AS3\/2006\/builtin"\), "push"\), 1/);
			
			logger.log("", "Applying IngameCreator Coremod: " + String(offset));
			
			lattice.patchFile(
				FILE_NAME,
				offset - 2,
				0,
				' \
				getlocal 8 \n \
				pushtrue \n \
				setproperty QName(PackageNamespace(""), "isWasp") \n \
				'
			);
		}
		
		private function addIngameControllerTowerShotHitsTargetTypeCheck(lattice: Lattice): void
		{
			var FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameController.class.asasm";
			
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
				notwasp: \n \
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
		
		/*
			getlocal0
            getproperty QName(PackageNamespace(""),"core")
            getproperty QName(PackageNamespace(""),"gemWasps")
            findpropstrict QName(PackageNamespace("com.giab.games.gcfw.entity"),"GemWasp")
            getlocal 4 // gem
            getlocal1
            getproperty QName(PackageNamespace(""),"x")
            getlocal1
            getproperty QName(PackageNamespace(""),"y")
            constructprop QName(PackageNamespace("com.giab.games.gcfw.entity"),"GemWasp"), 3
            callpropvoid QName(Namespace("http://adobe.com/AS3/2006/builtin"),"push"), 1
		*/
	}
}