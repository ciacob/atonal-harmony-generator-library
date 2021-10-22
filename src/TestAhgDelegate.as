package {
	import flash.display.Sprite;
	import flash.utils.getTimer;
	
	import ro.ciacob.maidens.generator.atonalharmony.AhgDelegate;
	import ro.ciacob.maidens.generator.atonalharmony.GmUnit;

	public final class TestAhgDelegate extends Sprite {
		
		public function TestAhgDelegate() {
			var conf : Object = {
				"lowestPermittedNote": 41,
				"harmonicRhythmDuration": {
					"value": [
						1,
						4
					],
					"label": "1/4"
				},
				"initialSopranoDirectionIsUp": true,
				"seedNumber": 1,
				"useRests": true,
				"harmonicRanks": [
					{
						"label": "3m 6M\n50",
						"values": [
							[
								3,
								9
							],
							50
						]
					},
					{
						"label": "*p\n10",
						"values": [
							[
								0,
								5,
								7,
								12
							],
							10
						]
					},
					{
						"label": "2M 7m 4+\n1",
						"values": [
							[
								2,
								10,
								6
							],
							1
						]
					},
					{
						"label": "2m 7M\n-50",
						"values": [
							[
								1,
								11
							],
							-50
						]
					}
				],
				"useSeededRandomness": true,
				"consolidateAdjacentSamePitchNotes": true,
				"deterministicsStrength": 0.65,
				"sopranoDirectionalityWeight": 0.75,
				"analysisWindow": 5,
				"targetDuration": "2/1",
				"climaxPosition": 0.618,
				"likelinessOfNonSynchronousRhythms": 0.125,
				"durations": [
					{
						"label": "1/2\n50",
						"values": [
							[
								1,
								2
							],
							50
						]
					},
					{
						"label": "1/4\n10",
						"values": [
							[
								1,
								4
							],
							10
						]
					},
					{
						"label": "1/8\n5",
						"values": [
							[
								1,
								8
							],
							5
						]
					},
					{
						"label": "1/1\n1",
						"values": [
							[
								1
							],
							1
						]
					}
				],
				"notesToRestsRatio": 0.75,
				"climaxUsesHighRankHarmony": false,
				"highestPermittedNote": 79
			}
			
			var start : int = getTimer();
			var ahg : AhgDelegate = new AhgDelegate (conf);
			var out : Vector.<GmUnit> = ahg.generate();
			var end : int = getTimer();
			var elapsedSecs : int = ((end - start) / 1000);
		}
	}
}