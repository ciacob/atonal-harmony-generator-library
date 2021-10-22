package ro.ciacob.maidens.generator.atonalharmony {
	public class GmSlice {
		
		private var _units : Vector.<GmUnit>;
		
		public function GmSlice () {
			_units = new Vector.<GmUnit>;
		}
		
		public function add (unit : GmUnit) : void {
			_assertNotDiscarded ();
			_units[_units.length] = unit;
		}
		
		public function get numUnits () : uint {
			_assertNotDiscarded ();
			return _units.length;
		}
		
		public function get isEmpty () : Boolean {
			_assertNotDiscarded ();
			return (_units.length == 0);
		}
		
		public function getUnitAt (unitIndex : uint) : GmUnit {
			_assertNotDiscarded ();
			return ((_units.length > unitIndex)? _units[unitIndex] : null)
		}
		
		public function _discard() : void {
			_assertNotDiscarded ();
			_units.length = 0;
			_units = null;
		}
		
		private function _assertNotDiscarded () : void {
			if (!_units) {
				throw (new Error ('GmSlice:: instance discarded'));
			}
		}
	}
}