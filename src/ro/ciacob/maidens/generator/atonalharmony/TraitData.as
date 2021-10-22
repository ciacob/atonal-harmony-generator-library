package ro.ciacob.maidens.generator.atonalharmony {
	
	public class TraitData {
		
		private var _rawMaterial : Vector.<PickableOption>;
		private var _remarks : TraitRemarks
		
		public function TraitData (rawMaterial : Vector.<PickableOption>, remarks : TraitRemarks) {
			_rawMaterial = rawMaterial;
			_remarks = remarks;
		}
		
		public function get rawMaterial () : Vector.<PickableOption> {
			return _rawMaterial;
		}
		
		public function get remarks () : TraitRemarks {
			return _remarks;
		}
	}
}