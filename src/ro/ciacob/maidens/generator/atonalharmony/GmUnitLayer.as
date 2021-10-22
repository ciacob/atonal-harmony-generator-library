package ro.ciacob.maidens.generator.atonalharmony {
	import ro.ciacob.math.Fraction;

	public class GmUnitLayer {
		public function GmUnitLayer (
			duration : Fraction,
			pitch : uint = 0,
			tieNext : Boolean = false,
			startTime : Fraction = null,
			dynamic : uint = 64
		) {
			_duration = (duration || Fraction.ZERO);
			_pitch = pitch;
			_tieNext = tieNext;
			_startTime = (startTime || Fraction.ZERO);
			_dynamic = dynamic;
		}
		
		/**
		 * MIDI number for the pitch of this layer, e.g., `60` is "middle C". The special value of
		 * `0` is reserved for denoting explicit rests.
		 */
		private var _pitch : uint;
		
		/**
		 * Audible amplitude.
		 * 
		 * NOTE:
		 * This is still a field that requires research. There is no working implementation for the 
		 * time being.
		 */
		private var _dynamic : uint;
		
		/**
		 * Duration of held note in current layer, in standard musical duration notation, e.g.,
		 * 1/4 for a quarter.
		 */
		private var _duration : Fraction;
		
		/**
		 * Offset of note attack in current layer, considered from layer start. Also in standard
		 * musical duration notation, e.g., 1/8 means that the note atack is delayed by an "eight".
		 * 
		 * NOTE:
		 * When merging GmUnit objects together, offsets will be either filled by overlapping the
		 * current unit over the previous, or converted to implicit rests. defaults to `0` whn not
		 * given.
		 */
		private var _startTime : Fraction;
		
		/**
		 * Whether the note on this layer should tie to the same-pitched note in the next unit, 
		 * providing there is no intervening space between them. This is merely an indication,
		 * and will be honoured by best effort.
		 */
		private var _tieNext : Boolean;
		
		public function get duration () : Fraction {
			return _duration;
		}
		
		public function get pitch () : uint {
			return _pitch;
		}
		
		public function get tieNext () : Boolean {
			return _tieNext;
		}
		
		public function get startTime () : Fraction {
			return _startTime;
		}
		
		public function get dynamic () : uint {
			return _dynamic;
		}
		
		public function get timeSpan () : Fraction {
			return _startTime.add (_duration) as Fraction;
		}

			
			
			




	}
}