package ro.ciacob.maidens.generator.atonalharmony {
	
	public class GmUnitParam {
		
		private var _name : String;
		private var _value : Object;
		private var _type : uint;
		
		public function GmUnitParam (name : String, value : Object, type : uint) {
			_name = name;
			_value = value;
			_type = type;
		}
		
		public function get name () : String {
			return _name;
		}
		
		public function get value () : Object {
			return _value;
		}
		
		public function get type () : uint {
			return _type;
		}
	}
}