package Hive 
{
	import com.giab.games.gcfw.entity.Tower;
	
	/**
	 * ...
	 * @author Shy
	 */
	public class HiveBuilding extends Tower 
	{
		public function HiveBuilding(pFieldX:int, pFieldY:int, pMossAlpha:Number=0, pMossHue:Number=0, pSnowAlpha:Number=0) 
		{
			super(pFieldX, pFieldY, pMossAlpha, pMossHue, pSnowAlpha);
		}
	}
}