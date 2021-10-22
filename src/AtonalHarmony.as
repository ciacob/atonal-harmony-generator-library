package {
	import ro.ciacob.maidens.generator.atonalharmony.AhgDelegate;
	import ro.ciacob.maidens.generator.atonalharmony.GmUnit;
	import ro.ciacob.maidens.generator.atonalharmony.GmUnitLayer;
	import ro.ciacob.maidens.generators.GeneratorBase;
	import ro.ciacob.maidens.generators.MusicEntry;
	import ro.ciacob.maidens.generators.constants.GeneratorBaseKeys;
	import ro.ciacob.maidens.generators.constants.parts.PartRanges;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.Time;

	public class AtonalHarmony extends GeneratorBase {
		
		private static const BANNER_MESSAGE : String = 'Now generating, please wait...';
		private static const STAR_SYMBOL : String = '';
		
		private var _tmp : AhgDelegate;

		private static const WEIGHTS_LIST : Array = [ -50, -10, -5, -1, 1, 5, 10, 50 ];
		
		private static const INTERVALS_CLASSES_TABLE : Array = [
			{label: '4p 5p', value: [5, 7, 12]},
			{label: '2m 7M', value: [1, 11, 12]},
			{label: '2M 7m 4+', value: [2, 10, 6, 12]},
			{label: '3m 6M', value: [3, 9, 12]},
			{label: '3M 6m', value: [4, 8, 12]},
		];
		
		private static const DURATIONS_TABLE : Array = [
			{label: '1/1', value: [1]},
			{label: '1/2', value: [1,2]},
			{label: '1/4', value: [1,4]},
			{label: '1/8', value: [1,8]},
			{label: '1/16', value: [1,16]},
		];
		
		/**
		 * Returns the available harmonic ranks in a format that can be used by the `PickupComponent`
		 * class.
		 */
		private function get AVAILABLE_HARMONIC_RANKS () : Array {
			return (_availableHarmonicRanks || (_availableHarmonicRanks = _compileAvailableHarmRanks()));
		}
		
		private function get AVAILABLE_DURATIONS () : Array {
			return (_availableDurations || (_availableDurations = _compileAvailableDurations()))
		};

		private var _intervalLabels:Array;
		private var _weightsLabels:Array;
		private var _durationsLabels:Array;
		private var _intervalValues:Array;
		private var _durationsValues:Array;
		private var _availableHarmonicRanks:Array;
		private var _availableDurations:Array;
		private var _output : Object;
		private var _isGenerationInProgress : Boolean;
		private var _harmonicRhythmDuration : Object;
		private var _climaxUsesHighRankHarmony:Boolean;
		private var _climaxPosition:Number;
		private var _initialSopranoDirectionIsUp:Boolean;
		private var _sopranoDirectionalityWeight:Number;
		private var _harmonicRhythmDurationSrc:Array;
		private var _harmonicRanks:Array;
		private var _harmonicRanksSrc:Array;
		private var _durations:Array;
		private var _consolidateAdjacentSamePitchNotes:Boolean;
		private var _lowestPermittedNote:int;
		private var _highestPermittedNote:int;
		private var _useRests:Boolean;
		private var _notesToRestsRatio:Number;
		private var _likelinessOfNonSynchronousRhythms:Number;
		private var _analysisWindow:int;
		private var _deterministicsStrength:Number;
		private var _useSeededRandomness:Boolean;
		private var _seedNumber:int;
		
		private var _targetDuration : String;
		
		/**
		 * @constructor
		 * TODO: provide description for this class
		 */
		public function AtonalHarmony () {
			
			// Set default values to be used by the generator, in case no prior configuration is made
			_climaxUsesHighRankHarmony = false;
			_climaxPosition = 0.618;
			_initialSopranoDirectionIsUp = true;
			_sopranoDirectionalityWeight = 0.75;
			_consolidateAdjacentSamePitchNotes = true;
			_lowestPermittedNote = (PartRanges.CHOIR[0] as int);
			_highestPermittedNote = (PartRanges.CHOIR[1] as int);
			_useRests = true;
			_notesToRestsRatio = 0.75;
			_likelinessOfNonSynchronousRhythms = 0.125;
			_analysisWindow = 5;
			_deterministicsStrength = 0.65;
			_useSeededRandomness = false;
			_seedNumber = 1;
			
			_harmonicRhythmDuration = DURATIONS_TABLE[2];
			_harmonicRanks = [
				AVAILABLE_HARMONIC_RANKS[3]['body'][7], // 3m & 6M => +50
				AVAILABLE_HARMONIC_RANKS[0]['body'][6], // *p => +10
				AVAILABLE_HARMONIC_RANKS[2]['body'][4], // 2M, 7m & 4+ => +1
				AVAILABLE_HARMONIC_RANKS[1]['body'][0], // 2m & 7M => -50
			];
			_durations = [
				AVAILABLE_DURATIONS[1]['body'][7], // 1/2 => +50
				AVAILABLE_DURATIONS[2]['body'][6], // 1/4 => +10
				AVAILABLE_DURATIONS[3]['body'][5], // 1/8 => +5
				AVAILABLE_DURATIONS[0]['body'][4], // 1/1 => +1
			];
		}
		
		
		// --- UI BLUEPRINT START ---
		
//		[Index(value = "1")]
//		[Description(value = "TODO: add description here")]
//		public function get climaxUsesHighRankHarmony () : Boolean {
//			return _climaxUsesHighRankHarmony;
//		}
//		
//		public function set climaxUsesHighRankHarmony (value : Boolean) : void {
//			_climaxUsesHighRankHarmony = value;
//		}
		
//		[Index(value = "2")]
//		[Minimum(value = "0")]
//		[Maximum(value = "1")]
//		[Description(value = "TODO: add description here")]
//		public function get climaxPosition () : Number {
//			return _climaxPosition;
//		}
//		
//		public function set climaxPosition (value : Number) : void {
//			_climaxPosition = value;
//		}
		
//		[Index(value = "3")]
//		[Description(value = "TODO: add description here")]
//		public function get initialSopranoDirectionIsUp () : Boolean {
//			return _initialSopranoDirectionIsUp;
//		}
//		
//		public function set initialSopranoDirectionIsUp (value : Boolean) : void {
//			_initialSopranoDirectionIsUp = value;
//		}
		
//		[Index(value = "4")]
//		[Minimum(value = "0")]
//		[Maximum(value = "1")]
//		[Description(value = "TODO: add description here")]
//		public function get sopranoDirectionalityWeight () : Number {
//			return _sopranoDirectionalityWeight;
//		}
		
//		public function set sopranoDirectionalityWeight (value : Number) : void {
//			_sopranoDirectionalityWeight = value;
//		}
		
//		[Index(value = "5")]
//		[UniqueSelection(value="true")]
//		[Description(value = "TODO: add description here")]
//		public function get harmonicRhythmDuration () : Object {
//			return _harmonicRhythmDuration;
//		}
		
//		public function set harmonicRhythmDuration (value : Object) : void {
//			_harmonicRhythmDuration = value;
//		}
//		
//		public function get harmonicRhythmDurationSrc () : Array {
//			return (_harmonicRhythmDurationSrc || (_harmonicRhythmDurationSrc = DURATIONS_TABLE.slice (0, 3)));
//		}
		
		[Index(value = "6")]
		[ListFontSize(value = 10)]
		[EditorFontSize(value = 13)]
		[Description(value = "A \"harmonic rank\" is a group of semantically related harmonic intervals. Available flavors range from most consonant (thirds and sixths) to most dissonant (seconds and sevenths). Weigh out the harmonic ranks you want the program to consider using. Note that perfect octaves (doubling) will be employed automatically, whenever they seem fit.")]
		public function get harmonicRanks () : Array {
			return _harmonicRanks;
		}
		
		public function get harmonicRanksSrc () : Array {
			return AVAILABLE_HARMONIC_RANKS;
		}
		
		public function set harmonicRanks (value : Array) : void {
			_harmonicRanks = value;
		}
		
		[Index(value = "7")]
		[ListFontSize(value = 10)]
		[EditorFontSize(value = 20)]
		[Description(value = "Provide the rhythmic durations you want the program to consider using, along with their weights.")]
		public function get durations () : Array {
			return _durations;
		}
		
		public function get durationsSrc () : Array {
			return AVAILABLE_DURATIONS;
		}
		
		public function set durations (value : Array) : void {
			_durations = value;
		}
		
//		[Index(value = "8")]
//		[Description(value = "TODO: add description here")]
//		public function get consolidateAdjacentSamePitchNotes () : Boolean {
//			return _consolidateAdjacentSamePitchNotes;
//		}
//		
//		public function set consolidateAdjacentSamePitchNotes (value : Boolean) : void {
//			_consolidateAdjacentSamePitchNotes = value;
//		}

		[Index(value = "9")]
		[Minimum(value = "24")]
		[Maximum(value = "67")]
		[Description(value = "Provide the lowest pitched note that should ever be allowed in the resulting choral, as a MIDI note number. \"Middle C\" is 60 in MIDI.")]
		public function get lowestPermittedNote () : int {
			return _lowestPermittedNote;
		}
		
		public function set lowestPermittedNote (value : int) : void {
			_lowestPermittedNote = value;
		}
		
		[Index(value = "10")]
		[Minimum(value = "68")]
		[Maximum(value = "96")]
		[Description(value = "Provide the highest pitched note that should ever be allowed in the resulting choral, as a MIDI note number. \"Middle C\" is 60 in MIDI.")]
		public function get highestPermittedNote () : int {
			return _highestPermittedNote;
		}
		
		public function set highestPermittedNote (value : int) : void {
			_highestPermittedNote = value;
		}
		
//		[Index(value = "11")]
//		[Description(value = "TODO: add description here")]
//		public function get useRests () : Boolean {
//			return _useRests;
//		}
//		
//		public function set useRests (value : Boolean) : void {
//			_useRests = value;
//		}
		
//		[Index(value = "12")]
//		[DependsOn(value="11")]
//		[Minimum(value = "0.1")]
//		[Maximum(value = "1")]
//		[Description(value = "TODO: add description here")]
//		public function get notesToRestsRatio () : Number {
//			return _notesToRestsRatio;
//		}
//		
//		public function set notesToRestsRatio (value : Number) : void {
//			_notesToRestsRatio = value;
//		}
		
//		[Index(value = "13")]
//		[Minimum(value = "0")]
//		[Maximum(value = "0.95")]
//		[Description(value = "TODO: add description here")]
//		public function get likelinessOfNonSynchronousRhythms () : Number {
//			return _likelinessOfNonSynchronousRhythms;
//		}
//		
//		public function set likelinessOfNonSynchronousRhythms (value : Number) : void {
//			_likelinessOfNonSynchronousRhythms = value;
//		}
		
		[Index(value = "14")]
		[Minimum(value = "1")]
		[Maximum(value = "10")]
		[Description(value = "Chord progressions are carried out considering (among others) already existing material. This controls how many chords to observe prior the current one.")]
		public function get analysisWindow () : int {
			return _analysisWindow;
		}
		
		public function set analysisWindow (value : int) : void {
			_analysisWindow = value;
		}
		
		[Index(value = "15")]
		[Minimum(value = "0.1")]
		[Maximum(value = "0.9")]
		[Description(value = "Controls \"how important\" rules are in any decision-making where randomness is also a factor.")]
		public function get deterministicsStrength () : Number {
			return _deterministicsStrength;
		}
		
		public function set deterministicsStrength (value : Number) : void {
			_deterministicsStrength = value;
		}
		
		[Index(value = "16")]
		[Description(value = "Whether to use a species of pseudo-randomness that produces consequential results (based on a given value, referred to as a \"seed\"). Useful for testing.")]
		public function get useSeededRandomness () : Boolean {
			return _useSeededRandomness;
		}
		
		public function set useSeededRandomness (value : Boolean) : void {
			_useSeededRandomness = value;
		}
		
		[Index(value = "17")]
		[Minimum(value = "1")]
		[Maximum(value = "65536")]
		[DependsOn(value="16")]
		[Description(value = "The value to base seeded randomness on (if employed).")]
		public function get seedNumber () : int {
			return _seedNumber;
		}
		
		public function set seedNumber (value : int) : void {
			_seedNumber = value;
		}
		
		// --- UI BLUEPRINT END ---
		
		/**
		 * @see GeneratorBase.$generate
		 */
		override public function $generate ():void {
			$callAPI ('core_showMessage', [BANNER_MESSAGE]);
			Time.delay (1, _doExecute);
		}
		
		/**
		 * @see GeneratorBase.$getOutput
		 */
		override public function $getOutput():Object {
			return {"out": _output};
		}
		
		private function _compileAvailableHarmRanks() : Array {
			
			// @see ro.ciacob.maidens.generators.GeneratorBase.createCombinations()
			return createCombinations (
				_intervalLabels || (_intervalLabels = getTableCol (INTERVALS_CLASSES_TABLE, 'label')), // "labels A"
				_weightsLabels || (_weightsLabels = Strings.stamp (STAR_SYMBOL, WEIGHTS_LIST, _reverseConcat)), // "labels B"
				_intervalValues || (_intervalValues = getTableCol (INTERVALS_CLASSES_TABLE, 'value')), // "values A"
				WEIGHTS_LIST // "values B"
			);
		}
		
		private function _compileAvailableDurations() : Array {
			
			// @see ro.ciacob.maidens.generators.GeneratorBase.createCombinations()
			return createCombinations (
				_durationsLabels || (_durationsLabels = getTableCol (DURATIONS_TABLE, 'label')), // "labels A"
				_weightsLabels || (_weightsLabels = Strings.stamp (STAR_SYMBOL, WEIGHTS_LIST, _reverseConcat)),  // "labels B"
				_durationsValues || (_durationsValues = getTableCol(DURATIONS_TABLE, 'value')),  // "values A"
				WEIGHTS_LIST // "values B"
			);
		}
		
		private function _reverseConcat (a : String, b: String) : String {
			return b.concat (a);
		}
		
		private function _doExecute (... args):void {

			var on_duration_ready : Function = function (apiName : String, duration : String) : void {
				_targetDuration = duration;
				var delegate : AhgDelegate = new AhgDelegate (_retrieveCurrentConfig ());
				_output = _parseDelegateOutput (delegate.generate ());
				$notifyGenerationComplete();
			}
			
			_computeTargetDuration (on_duration_ready);			
		}
		
		private function _retrieveCurrentConfig () : Object {
			var ret : Object = {};
			
			var ep : Array = ($uiEndpoints as Array);
			for each (var endPoint : Object in ep) {
				ret[endPoint.endPointName] = endPoint.endPointDefault;
			}
			
			// Add expected duration of generated material
			ret.targetDuration = _targetDuration;
			return ret;
		}
		
		private function _parseDelegateOutput (rawOutput: Object) : Object {
			// For the time being, we only generate into the top-most part of the connected
			// section(s). Also for the time being, we will distribute harmonic layers to
			// available voices, top to bottom.
			
			var ret : Object = {};
			var currentPart : Array = [];
			ret[GeneratorBaseKeys.NOTE_STREAMS] = currentPart;
			var voices : Array = [];
			currentPart.push (voices);
			var gmUnits : Vector.<GmUnit> = rawOutput as Vector.<GmUnit>;
			var numGmUnits : uint = gmUnits.length;
			var i : uint = 0;
			var j : int = 0;
			var unit : GmUnit = null;
			var numUnitLayers : uint = 0;
			var unitLayer : GmUnitLayer = null;
			var translatedEntry : MusicEntry = null;
			var reversedIndex : int = 0;
			for (i; i < numGmUnits; i++) {
				unit = gmUnits[i];
				numUnitLayers = unit.numLayers;
				for (j = 0; j < numUnitLayers; j ++) {
					
					reversedIndex = (numUnitLayers - 1 - j);
					if (voices[reversedIndex] === undefined) {
						voices[reversedIndex] = [];
					}
					
					unitLayer = unit.getLayerAt (j);
					translatedEntry = unitLayer? 
						new MusicEntry (unitLayer.pitch, unitLayer.duration, unitLayer.tieNext):
						new MusicEntry (0, unit.getMaxTimeSpan());
					(voices[reversedIndex] as Array).push (translatedEntry);
				}
			}
			return ret;
		}
		
		private function _computeTargetDuration (callback : Function) : void {
			var sectionNames : Array = [];
			for (var i:int = 0; i < $targetsInfo.length; i++) {
				var targetInfo : Object = ($targetsInfo[i] as Object);
				if (targetInfo["dataType"] == "section") {
					var name : String = targetInfo["uniqueSectionName"];	
					sectionNames.push(name);
				}
			}
			$callAPI ('core_getGreatestDurationOf', [sectionNames], callback);
		}
	}
}
