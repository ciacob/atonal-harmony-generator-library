package ro.ciacob.maidens.generator.atonalharmony {
	import flash.utils.Dictionary;

	public class TraitRemarks {
		public function TraitRemarks() {
		}
		
		public var trait : MusicalTrait;
		public var traitImportance : Number;
		public var slice : GmSlice;
		public var params : Dictionary;
		public var idealCurveContinuation : IdealParamCurve;
		public var simPsychoAcousticAmmendmends : Vector.<Ammendment>;
		public var idealCurveStreams : Dictionary;
		public var heuristicAmmendmentStreams : Dictionary;
		public var simPsychoAcousticAmmendmendStreams : Dictionary;
		public var complianceRankStreams : Dictionary;
		public var efficiencyRankStreams : Dictionary;
		public var nextGmUnitAmmendments : Vector.<Ammendment>;
	}
}