package ro.ciacob.maidens.generator.atonalharmony {
	
	public class PickableOption {
		
		private var _content : Object;
		private var _weight : uint;
		
		public function PickableOption (content : Object, weight : uint) {
			_content = content;
			_weight = weight;
		}
		
		public function get content () : Object {
			return _content;
		}
		
		public function get weight () : uint {
			return _weight;
		}
	}
}