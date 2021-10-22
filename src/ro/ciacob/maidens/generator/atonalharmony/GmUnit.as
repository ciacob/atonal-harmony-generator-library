package ro.ciacob.maidens.generator.atonalharmony {
	import flash.utils.Dictionary;
	
	import ro.ciacob.math.Fraction;
	
	public class GmUnit {

		private static var _mTraits : Vector.<MusicalTrait>;
		private static var _mTraitsIndex : Dictionary = new Dictionary;
		
		public static function get MUSICAL_TRAITS () : Vector.<MusicalTrait> {
			return (_mTraits || (_mTraits = _listTraits()));
		}
		
		public static function getTraitByName (name : String) :MusicalTrait {
			return (_mTraitsIndex[name] || null);
		}
		
		private static function _listTraits () : Vector.<MusicalTrait> {
			return new <MusicalTrait>[
				(_mTraitsIndex[MusicalTrait.PITCH] = new MusicalTrait (MusicalTrait.PITCH)),
				(_mTraitsIndex[MusicalTrait.DYNAMIC] = new MusicalTrait (MusicalTrait.DYNAMIC)),
				(_mTraitsIndex[MusicalTrait.DESCANT] = new MusicalTrait (MusicalTrait.DESCANT)),
				(_mTraitsIndex[MusicalTrait.BASS] = new MusicalTrait (MusicalTrait.BASS)),
				(_mTraitsIndex[MusicalTrait.DIAPASON] = new MusicalTrait (MusicalTrait.DIAPASON)),
				(_mTraitsIndex[MusicalTrait.DURATION] = new MusicalTrait (MusicalTrait.DURATION)),
				(_mTraitsIndex[MusicalTrait.START_TIME] = new MusicalTrait (MusicalTrait.START_TIME)),
				(_mTraitsIndex[MusicalTrait.TIME_SPAN] = new MusicalTrait (MusicalTrait.TIME_SPAN)),
				(_mTraitsIndex[MusicalTrait.TIE_NEXT] = new MusicalTrait (MusicalTrait.TIE_NEXT)),
				(_mTraitsIndex[MusicalTrait.ENTROPY_RANK] = new MusicalTrait (MusicalTrait.ENTROPY_RANK)),
				(_mTraitsIndex[MusicalTrait.HARMONIC_RANK] = new MusicalTrait (MusicalTrait.HARMONIC_RANK)),
				(_mTraitsIndex[MusicalTrait.DISTRIBUTION_RANK] = new MusicalTrait (MusicalTrait.DISTRIBUTION_RANK)),
				(_mTraitsIndex[MusicalTrait.CONGESTION_RANK] = new MusicalTrait (MusicalTrait.CONGESTION_RANK)),
				(_mTraitsIndex[MusicalTrait.LAYERS_NUMBER] = new MusicalTrait (MusicalTrait.LAYERS_NUMBER))
			];
		}

		private var _layers : Vector.<GmUnitLayer>;
		
		public function GmUnit (layers : Vector.<GmUnitLayer>) {
			_layers = layers.concat();
			_layers.sort (_byPitchAscending);
		}
		
		/**
		 * A parameter is the tangible technicality that concures to pragmatically describing or implementing a
		 * musical trait.
		 * 
		 * TODO: clarify whether we actually need this two-tier approach.
		 */
		public function getParamsRelatedTo (trait : MusicalTrait) : Vector.<GmUnitParam> {
			// TODO
			return new Vector.<GmUnitParam>;
		}
		
		public function getAmmendmentAppliedTo (param : GmUnitParam) : Ammendment {
			// TODO
			return new Ammendment;
		}
		
		/**
		 * Returns the longest time span across all voices/layers involved, e.g., in a polyphonic conduct, it will usually
		 * return the bass' time span, since (usually) the bass plays in longer values than the descant.
		 */
		public function getMaxTimeSpan () : Fraction {
			var ret : Fraction = Fraction.ZERO;
			var i : int = 0;
			var numLayers : uint = _layers.length;
			var layer : GmUnitLayer = null;
			var layerSpan : Fraction = null;
			for (i = 0; i < numLayers; i++) {
				layer = _layers[i];
				if (layer != null) {
					layerSpan = layer.timeSpan;
					if (layerSpan.greaterThan(ret)) {
						ret = layerSpan;
					}
				}
			}
			return ret;
		}
		
		public function get numLayers () : uint {
			return _layers.length;
		}
		
		/**
		 * Layers are laid out by their pitch, in ascending order, i.e., the layer at index`0` is the bass layer
		 * and the layer at `numLayers - 1` is the descant layer.
		 * 
		 * NOTES:
		 * For values of `index` outside the range of `0`-> `numLayers-1`, `null` will be returned. Also, remember
		 * that the value of `null` is a valid value for a layer.
		 */
		public function getLayerAt (index : uint) : GmUnitLayer {
			if (index < _layers.length) {
				return _layers[index];
			}
			return null;
		}
		
		/**
		 * Returns the bottom-most layer, whether it is playing (non `null` and `pitch` > 0) or not (`null`, or
		 * non `null` and `pitch` == 0).
		 */
		public function get bassLayer () : GmUnitLayer {
			return getLayerAt (0);
		}
		
		/**
		 * Returns the top-most layer, whether it is playing (non `null` and `pitch` > 0) or not (`null`, or
		 * non `null` and `pitch` == 0).
		 */
		public function get descantLayer () : GmUnitLayer {
			return getLayerAt (numLayers - 1);
		}
		
		/**
		 * Returns the lowest playing pitch. Will return `0` if there is none.
		 */
		public function get bassPitch () : uint {
			var i:int = 0;
			var nl : uint = _layers.length;
			var layer : GmUnitLayer = null;
			for (i = 0; i < nl; i++) {
				layer = _layers[i];
				if (layer != null) {
					if (layer.pitch > 0) {
						return layer.pitch;
					}
				}
			}
			return 0;
		}
		
		/**
		 * Returns the highest playing pitch. Will return `0` if there is none.
		 */
		public function get descantPitch () : uint {
			var i:int = 0;
			var nl : uint = _layers.length;
			var layer : GmUnitLayer = null;
			for (i = nl-1; i >= 0; i--) {
				layer = _layers[i];
				if (layer != null) {
					if (layer.pitch > 0) {
						return layer.pitch;
					}
				}
			}
			return 0;
		}
		
		/**
		 * Returns the semitones number between the descant pitch and the bass pitch
		 */
		public function get diapason () : uint {
			var d : uint = descantPitch;
			var b : uint = bassPitch;
			if (d && b) {
				return (d - b);
			}
			return 0;
		}
		
		/**
		 * TODO
		 */
		public function get dynamic () : uint {
			return 64;
		}
		
		/**
		 * TODO
		 */
		public function get entropyRank () : uint {
			return 0;
		}
		
		/**
		 * TODO
		 */
		public function get harmonicRank () : uint {
			return 0;
		}
		
		/**
		 * TODO
		 */
		public function get distributionRank () : uint {
			return 0;
		}
		
		/**
		 * TODO
		 */
		public function get congestionRank () : uint {
			return 0;
		}
		
		private function _byPitchAscending (layerA : GmUnitLayer, layerB : GmUnitLayer) : int {
			// `null` stands for "this voice is missing"
			if (layerA == null || layerB == null) {
				return 0;
			}
				
			// `0` stands for "rest", or "silence", and we don't want to sort these.
			if (layerA.pitch == 0 || layerB.pitch == 0) {
				return 0;
			}
			
			return (layerA.pitch - layerB.pitch);
		}
	}
}