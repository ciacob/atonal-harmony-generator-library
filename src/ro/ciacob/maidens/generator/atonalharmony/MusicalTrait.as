package ro.ciacob.maidens.generator.atonalharmony {
	import ro.ciacob.maidens.generators.constants.MusicTypes;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.constants.Types;
	
	public class MusicalTrait {
		
		// PITCH RELATED
		
		/**
		 * Expressed as an uint (MIDI number) for a single-layer unit, or as a Vector of uints for a multi-layer unit.
		 * The MIDI value of `0` is reserved to denote a rest (no pitch).
		 */
		public static const PITCH : String = 'pitch';
		
		/**
		 * Expressed as an uint (MIDI number of the highest layer available) for multi-layer units. Equal to PITCH for
		 * single-layer units.
		 */
		public static const DESCANT : String = 'descant';
		
		/**
		 * Expressed as an uint (MIDI number of the lowest layer available) for multi-layer units. Equal to PITCH for
		 * single-layer units.
		 */
		public static const BASS : String = 'bass';
		
		/**
		 * Expressed as a non-zero uint (semitones between the bass and descant) for multi-layer units. Always 0 for 
		 * single-layer units.
		 */
		public static const DIAPASON : String = 'diapason';
		
		
		// DURATION RELATED
		
		/**
		 * Expressed as a Fraction for a single-layer unit, or as a Vector of Fractions for a multi-layer unit. The minimum
		 * duration used shall be the 1/128.
		 */
		public static const DURATION : String = "duration";
		
		/**
		 * Expressed as a Vector of Fractions for a multi-layer unit (the delay from the start of the unit for 
		 * each layer). Always the ZERO Fraction for single layered units. 
		 */
		public static const START_TIME : String = "startTime";
		
		/**
		 * Expressed as a Fraction (longest value of START_TIME + DURATION, in all layers). Equals to START_TIME +
		 * DURATION for single-layer units.
		 */
		public static const TIME_SPAN : String = "timeSpan";
		
		/**
		 * Expressed as a non-zero uint (degree of restlessness within the current unit, as determined by the individual
		 * start times, durations, and alternation between rests and pitched notes inside the consisting layers; the higher,
		 * the more chaotic). Not applicable (or `0`) for single-layer units.
		 */
		public static const ENTROPY_RANK : String = "entropyRank";
		
		/**
		 * Expressed as a Boolean (whether or not to tie to the next note of same pitch) for single-layer units; expressed
		 * as a Vector of Booleans for multi-layer units. This is an indication only, and shall be discarded wherever the
		 * request of having two adjacent notes of same pitch cannot be fulfilled.
		 */
		public static const TIE_NEXT : String = 'tieNext';
		
		
		// HARMONY RELATED
		
		/**
		 * Expressed as a non-zero uint (harmonic rank of unit, as computed by a dedicated algorithm, the higher, the
		 * more valuable). Not applicable (or `0`) for single-layer units.
		 */
		public static const HARMONIC_RANK : String = 'harmonicRank';
		
		/**
		 * Expressed as a non-zero uint (voice distribution rank of unit, as computed by a dedicated algorithm, the higher,
		 * the more fit). Not applicable (or `0`) for single-layer units.
		 */
		public static const DISTRIBUTION_RANK : String = 'distributionRank';
		
		/**
		 * Expressed as a non-zero uint (the degree of "closeness" of the harmonic "voices" within the current unit, as 
		 * computed by a dedicated algorithm; the higher, the more "congested"). Not applicable (or `0`) for single-layer
		 * units.
		 */
		public static const CONGESTION_RANK : String = "congestionRank";
		
		
		// DYNAMICS RELATED
		
		/**
		 * Expressed as a uint between 1 and 127 (MIDI velocity for first-attack pitches, MIDI volume for held pitches: the
		 * degree of audible amplitude a certain pitch should exert) for single-layer units; expressed as a Vector of uints
		 * for multi-layer units. 
		 */
		public static const DYNAMIC : String = 'dynamic';


		// MISC.
		
		/**
		 * Expressed as a non-zero uint (number of distinct layers that make up a given unit -- e.g., a C major triad will
		 * have three layers; a triad with doubled bass will have four layers; a C note will have one layer). Each layer
		 * will define a single DURATION, START_TIME, PITCH and TIE_NEXT. Not applicable (or `1`) for single-layer units.
		 */
		public static const LAYERS_NUMBER : String = 'layersNumber';
		
		
		private var _name : String;
		
		private var _isMultiLayerOnly : Boolean = false;
		private var _singleLayerDataType : uint;
		private var _multiLayerDataType : uint;
		
		private var _min : Object;
		private var _max : Object;
		private var _na : Object;
		
		
		public function MusicalTrait (name : String) {
			_name = name;
			
			switch (_name) {
				case PITCH:
				case DYNAMIC:
					_singleLayerDataType = Types.UINT;
					_multiLayerDataType = Types.UINTS_VECTOR;
					_min = 1;
					_max = 127;
					_na = 0;	
					break;
				
				case DESCANT:
				case BASS:
				case DIAPASON:
					_isMultiLayerOnly = true;
					_multiLayerDataType = Types.UINT;
					_min = 1;
					_max = 127;
					_na = 0;	
					break;
				
				case DURATION:
					_singleLayerDataType = MusicTypes.FRACTION;
					_multiLayerDataType = MusicTypes.FRACTIONS_VECTOR;
					_min = new Fraction (1, 128);
					_max = Fraction.WHOLE;
					break;
				
				case START_TIME:
				case TIME_SPAN:
					_singleLayerDataType = MusicTypes.FRACTION;
					_multiLayerDataType = MusicTypes.FRACTIONS_VECTOR;
					_min = Fraction.ZERO;
					_max = Fraction.WHOLE;
					break;
				
				case TIE_NEXT:
					_singleLayerDataType = Types.BOOLEAN;
					_multiLayerDataType = Types.BOOLEANS_VECTOR;
					break;

				case ENTROPY_RANK:
				case HARMONIC_RANK:
				case DISTRIBUTION_RANK:
				case CONGESTION_RANK:
					_isMultiLayerOnly = true;
					_multiLayerDataType = Types.UINT;
					_min = 1;
					_na = 0;
					break;
				
				case LAYERS_NUMBER:
					_singleLayerDataType = Types.UINT;
					_multiLayerDataType = Types.UINT;
					_min = 1;
					_na = 1;
					break;
			}
		}
		
		public function get name () : String {
			return _name;
		}
		
		public function get isMultiLayerOnly () : Boolean {
			return _isMultiLayerOnly;
		}
		
		public function get singleLayerDataType () : uint {
			return _singleLayerDataType;
		}
		
		public function get multiLayerDataType () : uint {
			return _multiLayerDataType;
		}
		
		public function get min () : Object {
			return _min;
		}
		
		public function get max () : Object {
			return _max;
		}
		
		public function get notApplicableValue () : Object {
			return _na;
		}
	}
}