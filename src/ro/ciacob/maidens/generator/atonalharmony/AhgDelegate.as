package ro.ciacob.maidens.generator.atonalharmony {
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ro.ciacob.stochastic.random.WeightedRandomPicker;
	import ro.ciacob.maidens.generators.constants.BiasTables;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.stochastic.random.WRPickerConfig;
	import ro.ciacob.utils.NumberUtil;
	import ro.ciacob.utils.Objects;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.Random.SeededRandom;
	import ro.ciacob.utils.constants.Types;
	
	/**
	 * NOTE: everywhere in fields' names, "GM" (in any case) stands for "Generated Material".
	 */
	public class AhgDelegate extends Sprite {
		
		private static const NUM_LAYERS_PER_UNIT : uint = 4;
		private static const DETERMINISTICS_STRENGTH_MAX_FACTOR : uint = 10;
		
		private var _config : Object;
		private var _outputQueue :  Vector.<GmUnit>;
		private var _pickers : Dictionary;
		private var _seededRandom : SeededRandom;
		
		public function AhgDelegate (config : Object) {
			_config = config;
			_outputQueue = new  Vector.<GmUnit>;
			_pickers = new Dictionary;
		}
		
		public function generate () : Vector.<GmUnit> {
			// Reset
			_outputQueue.length = 0;
			_resetSeededRandomIfAny();
			
			// Generate
			var unit : GmUnit = null;
			while (_getCurrentPointInTime().lessThan (Fraction.WHOLE)) {
				var analysisSlice : GmSlice = cutSlice (_outputQueue, _getAnalysisWindowSpan());
				unit = _generateUnit (analysisSlice);
				if (!unit) {
					break;
				}
				_enqueueGmUnit (_outputQueue, unit);
			}
			return _outputQueue;
		}
		
		private function _computeGmSpan () : Fraction {
			if (!_outputQueue.length) {
				return Fraction.ZERO;
			}
			var totalSpan : Fraction = Fraction.ZERO;
			var i : int = 0;
			var qLength : int = _outputQueue.length;
			var unit : GmUnit = null;
			var unitSpan : Fraction = null;
			for (i; i < qLength; i++) {
				unit = _outputQueue[i];
				unitSpan = unit.getMaxTimeSpan();
				totalSpan = totalSpan.add (unitSpan) as Fraction;
			}
			return totalSpan;
		}
		
		private function _getTargetSpan () : Fraction {
			_assertConfigItem ("targetDuration");
			return Fraction.fromString (_config.targetDuration);
		}
		
		private function _enqueueGmUnit (queue :  Vector.<GmUnit>, unit : GmUnit) : void {
			// TODO
			queue.push (unit);
		}
		
		private function cutSlice (queue :  Vector.<GmUnit>, numLastItems : uint) : GmSlice {
			var ret : GmSlice = new GmSlice;
			var qLen : uint = queue.length;
			if (qLen == 0) {
				return ret;
			}
			var numCopies : uint = Math.min (queue.length, numLastItems);
			while (numCopies > 0) {
				ret.add (queue[qLen - numCopies]);
				numCopies--;
			}
			return ret;
		}
		
		private function _generateUnit (analysisSlice : GmSlice) : GmUnit {
			var traitsData : Dictionary = new Dictionary;
			var uniqueDrawsSetting : Boolean = false;
			var availableOptions : Vector.<PickableOption> = null;
			var selectedOptions : Vector.<PickableOption> = null;
			var startingPoint : TraitRemarks = null;
			var numDrawsPerUnit : uint = 0;
			var customRandFunct : Function = null;
			
			for (var i : uint = 0; i < GmUnit.MUSICAL_TRAITS.length; i++) {
				var trait : MusicalTrait = GmUnit.MUSICAL_TRAITS[i];
				var picker : WeightedRandomPicker = _getPickerForTrait (trait);
				if (!picker) {
					continue;
				}
				uniqueDrawsSetting = _getUniqueDrawsSettingFor (trait);
				startingPoint = _findStartingPointFor (analysisSlice, trait);
				numDrawsPerUnit = _getNumDrawsPerUnitFor (trait, uniqueDrawsSetting, _getDeterministicsStrength());
				availableOptions = _producePickableOptionsBasedOn (startingPoint);
				customRandFunct = _getCustomRandomFunc (_getSeededPRNGSetting ());
				_configurePicker (picker, uniqueDrawsSetting, numDrawsPerUnit, availableOptions, customRandFunct);
				selectedOptions = Vector.<PickableOption> (picker.pick());
				traitsData[trait] = new TraitData (selectedOptions, startingPoint);
			}
			if (!Objects.isEmpty (traitsData)) {
				var possibleUnits : Vector.<GmUnit> = _makeUnitsFromTraitsData (traitsData);
				return _findMostAppropriateNextUnit (possibleUnits, _getDeterministicsStrength());
			}
			return null;
		}
		
		private function _getPickerForTrait (trait : MusicalTrait) : WeightedRandomPicker {
			
			var picker : WeightedRandomPicker = null;
			var tn : String = trait.name;
			
			switch (tn) {
				case MusicalTrait.PITCH:
				case MusicalTrait.DURATION:
					picker = (_pickers[tn] || (_pickers[tn] = new WeightedRandomPicker));
					break;
					
				// These are disabled for now; we'll start small, and only add layers of complexity once
				// generating basic units works.
				case MusicalTrait.START_TIME:
				case MusicalTrait.DESCANT:
				case MusicalTrait.BASS:
				case MusicalTrait.DIAPASON:
				case MusicalTrait.TIME_SPAN:
				case MusicalTrait.ENTROPY_RANK:
				case MusicalTrait.TIE_NEXT:
				case MusicalTrait.HARMONIC_RANK:
				case MusicalTrait.DISTRIBUTION_RANK:
				case MusicalTrait.CONGESTION_RANK:
				case MusicalTrait.LAYERS_NUMBER:
				case MusicalTrait.DYNAMIC:
				default:
					break;
			}

			return picker;
		}
		
		private function _configurePicker (
			picker : WeightedRandomPicker,
			dontPickDupplicates : Boolean,
			howManytoPick : uint,
			optionsToPickFrom : Vector.<PickableOption>,
			customRandomFunc : Function = null
		) : void {
			
			var cfg : WRPickerConfig = WRPickerConfig
				.$create()
				.$setExhaustible (dontPickDupplicates)
				.$setNumPicks(howManytoPick);
			
			if (customRandomFunc != null) {
				cfg.$setRandomIntegerFunction (_makeRandomIntFunctionUsing (customRandomFunc));
			}
			
			var i:int = 0;
			var numPickables : uint = optionsToPickFrom.length;
			var option : PickableOption = null;
			for (i = 0; i < numPickables; i++) {
				option = optionsToPickFrom[i];
				cfg.$add (option, option.weight);
			}
			
			picker.configure (cfg);
		}
		
		private function _getCustomRandomFunc (forSeed : uint) : Function {
			if (forSeed == 0) {
				if (_seededRandom != null) {
					_seededRandom.reset();
				}
				_seededRandom = null;
			} else {
				_seededRandom = (_seededRandom || (_seededRandom = SeededRandom.instance));
				if (_seededRandom.$seed != forSeed) {
					_seededRandom.$seed = forSeed;
					_seededRandom.reset();
				}
			}
			return (_seededRandom? _seededRandom.random : null);
		}
		
		private function _resetSeededRandomIfAny () : void {
			if (_seededRandom != null) {
				_seededRandom.reset();
			}
		}
		
		private function _makeRandomIntFunctionUsing (genericRandFunc : Function) : Function {
			return (function (lo : uint, hi : uint) : uint {
				return NumberUtil.getRandomInteger (lo, hi, genericRandFunc);
			});
		}
		
		/**
		 * @return Returns value `0` for disabled, any other positive integer for an actual seed value.
		 */
		private function _getSeededPRNGSetting () : uint {
			_assertConfigItem ("useSeededRandomness");
			_assertConfigItem ("seedNumber");
			if (_config.useSeededRandomness) {
				return uint (_config.seedNumber);
			}
			return 0;
		}
		
		private function _getUniqueDrawsSettingFor (trait : MusicalTrait) : Boolean {
			
			var useUniqueDraws : Boolean = false;
			
			var tn : String = trait.name;
			switch (tn) {
				case MusicalTrait.PITCH:
				case MusicalTrait.DURATION:
					useUniqueDraws = false;
					break;
				
				// More to comme
			}
			
			return useUniqueDraws;
		}
		
		private function _getNumDrawsPerUnitFor (trait : MusicalTrait,
												 drawsMustBeUnique : Boolean,
												 deterministicsStrength : Number) : uint {
			
			var tn : String = trait.name;
			var numDraws : uint = 0;
			var numRequiredValuesPerUnit : uint = 0;
			var numAvailableValues : uint = 0;
			
			switch (tn) {
				case MusicalTrait.PITCH:
					numRequiredValuesPerUnit = NUM_LAYERS_PER_UNIT;
					numAvailableValues = _getAvailablePitchesAt (_getCurrentPointInTime()).length;
					break;
				case MusicalTrait.DURATION:
					numRequiredValuesPerUnit = 1;
					numAvailableValues = _getAvailableDurationsAt (_getCurrentPointInTime()).length;
					break;
				
				// More traits to be defined here.
			}
			
			if (numAvailableValues > 0) {
				numDraws = numRequiredValuesPerUnit * Math.max (1, (deterministicsStrength * DETERMINISTICS_STRENGTH_MAX_FACTOR));
				if (drawsMustBeUnique) {
					numDraws = Math.min (numAvailableValues, numDraws); 
				}
				return numDraws;
			}
			return 0;
		}
		
		private function _getDeterministicsStrength () : Number {
			return (_config.deterministicsStrength as Number)	
		}
		
		private function _getAvailablePitchesAt (time : Fraction) : Vector.<uint> {
			var ret : Vector.<uint> = new Vector.<uint>;
			
			// TODO
			// FIXME
			// For now, we always return all possible pitches, regardless of the current point in time.
			// For now, we do not cache these results.
			var highestPitch : uint = (_config.highestPermittedNote	as uint);
			var lowestPitch : uint = (_config.lowestPermittedNote as uint);
			for (var pitch : uint = lowestPitch; pitch <= highestPitch; pitch++) {
				ret.push (pitch);
			}
			
			return ret;
		}
		
		private function _getAvailableDurationsAt (time : Fraction) : Vector.<Fraction> {
			_assertConfigItem ("durations");
			
			var ret : Vector.<Fraction> = new Vector.<Fraction>;
			
			// TODO
			// FIXME
			// For now, we always return all possible durations, regardless of the current point in time.
			// For now, we do not cache these results.
			var durations : Array = (_config.durations as Array);
			
			var numerator : uint = 0;
			var denominator : uint = 1;
			var i : uint = 0;
			var numDurations : uint = durations.length;
			var duration : Object = null;
			var fDefinition : Array = null;
			var values : Array = null;
			for (i = 0; i < numDurations; i++) {
				duration = (durations[i] as Object);
				values = (duration.values as Array);
				fDefinition = (values[0] as Array);
				numerator = (fDefinition[0] as uint) || 0;
				denominator = (fDefinition[1] as uint) || 1;
				ret.push (new Fraction (numerator, denominator));
			}	
			
			return ret;
		}
		
		private function _producePickableOptionsBasedOn (traitEvolution : TraitRemarks) : Vector.<PickableOption> {
			
			var options : Vector.<PickableOption> = new Vector.<PickableOption>;
			var trait : MusicalTrait = traitEvolution.trait;
			var params : Dictionary = traitEvolution.params;
			var tn : String = trait.name;
			
			var values : Array = null;
			var weight : uint = 0;
			var configItem : Object = null;
			var i:uint = 0;
			var j : uint = 0;
			var numerator : uint = 0;
			var denominator : uint = 0;
							
			switch (tn) {
				case MusicalTrait.PITCH:
					
					// Yelds pickable MIDI pitches to (possibly) use. They are based on:
					// 1) user's favorite harmonic intervals (declared by means of the "harmonic
					//    ranks" configuration setting);
					// 2) previous bass pitch (<prev_bass_pitch> + <interval>);
					if (params) {

						var bassParam : GmUnitParam = params [
							ParamNames.STARTING_BASS_PITCH] as GmUnitParam;
						
						if (bassParam) {
							
							var harmRanks : Array = (_config.harmonicRanks as Array);
							var numHarmRanks : uint = harmRanks.length;
							var intervals : Array = null;
							var numIntervals : uint = 0;
							var interval : uint = 0;
							var prevPitch : uint = 0;
							var option : PickableOption = null;
							var possiblePitch : uint = 0;
							
							// Loop through user's "harmonic rank" definitions
							for (i = 0; i < numHarmRanks; i++) {
								configItem = (harmRanks[i] as Object);
								values = (configItem.values as Array);
								weight = (values[1] as uint);
								intervals = (values[0] as Array);
								numIntervals = intervals.length;
								
								// Loop through all the harmonic intervals we have definitions 
								// for
								for (j = 0; j < numIntervals; j++) {
									interval = (intervals[j] as uint);
									if (bassParam) {
										option = new PickableOption (
											(bassParam.value as uint) + interval, weight);
										options.push (option);
									}
								}
							}
							
						}
					}
					break;
				
				case MusicalTrait.DURATION:
					
					// Create pickable options directly from user's favorite durations. We
					// don't use the trait's "paramsStreams" (at least not yet).
					//
					// TODO: REFINE THIS LOGIC AS WE PROGRESS.
					
					var durations : Array = (_config.durations as Array);
					var numDurations : uint = durations.length;
					for (i = 0; i < durations.length; i++) {
						configItem = (durations[i] as Object);
						values = (configItem.values as Array);
						weight = (values[1] as uint);
						numerator = ((values[0][0] as uint) || 0);
						denominator = ((values[0][1] as uint) || 1);
						option = new PickableOption (new Fraction (numerator, denominator), weight);
						options.push (option);
					}
					break;
				
					// TODO: more to come
			}
			
			return options;
		}
		
//		private function _doTraitAnalysis (
//			gmSlice : GmSlice,
//			primordialTrait : MusicalTrait,
//			primordialTraitImportance : Number
//		) : TraitEvolutionObservation {
			
			// TODO
			// FIXME 
			// make the rest of code return the needed parameter streams, so we can create picker options
			// based on the previously generated material
//			if (gmSlice.isEmpty) {
//				return _getStartupAssumptions (primordialTrait);
//			}
			
//			var observation : TraitEvolutionObservation = new TraitEvolutionObservation;
//			observation.trait = primordialTrait;
//			observation.traitImportance = primordialTraitImportance;
//			observation.slice = gmSlice;
//			var paramsStreams : Dictionary = new Dictionary;
//			var appliedAmmendmentsStreams : Dictionary = new Dictionary;
//			for (var i : int = gmSlice.numUnits - 1; i >= 0; i--) {
//				var unit : GmUnit = gmSlice.getUnitAt (i);
//				var relatedParams : Vector.<GmUnitParam> = unit.getParamsRelatedTo (primordialTrait);
//				
//				for (var j:int = 0; j < relatedParams.length; j++) {
//					var relatedParam : GmUnitParam = relatedParams[j];
//					if (!(relatedParam.name in paramsStreams)) {
//						paramsStreams[relatedParam.name] = new Vector.<GmUnitParam>;
//					}
//					(paramsStreams[relatedParam.name] as Vector.<GmUnitParam>).push (relatedParam.value);
//
//					var appliedAmmendment : Ammendment = unit.getAmmendmentAppliedTo (relatedParam);
//					if (!(relatedParam.name in appliedAmmendmentsStreams)) {
//						appliedAmmendmentsStreams[relatedParam.name] = new Vector.<Ammendment>;
//					}
//					(appliedAmmendmentsStreams[relatedParam.name] as Vector.<Ammendment>).push (appliedAmmendment);
//				}
//			}
//			
//			observation.paramsStreams = paramsStreams;
////			observation.simPsychoAcousticAmmendmends = simPsychoAcousticAmmendmends; trebuie facut un "stream", la fel ca in cazul "paramsStreams", pentru ca se calculeaza pentru fiecare parametru in parte 
//			
//			observation.idealCurveStreams = new Dictionary;
//			observation.heuristicAmmendmentStreams = new Dictionary;
//			observation.simPsychoAcousticAmmendmendStreams = new Dictionary;
//			observation.complianceRankStreams = new Dictionary;
//			observation.efficiencyRankStreams = new Dictionary;
//			
//			for (var paramName : String in paramsStreams) {
//
//				var idealCurve : IdealParamCurve = _getIdealCurveFor (paramName, gmSlice);
//				var heuristicAmmendmends : Vector.<Ammendment> = _getHeuristicsAmmendmentsTo (paramName, gmSlice);
//				var simPsychoAcousticAmmendmends : Vector.<Ammendment> = _getSimmulatedPsychoAcousticsAmmendmentsTo (paramName, gmSlice);
//
//				var paramsValues : Vector.<GmUnitParam> = (paramsStreams[paramName] as Vector.<GmUnitParam>);
//				var paramsAmmendments : Vector.<Ammendment> = (appliedAmmendmentsStreams[paramName] as Vector.<Ammendment>);
//				
//				var complianceRanks : Vector.<ComplianceRank> = _computeComplianceRanks (
//					paramName, 
//					paramsValues, 
//					idealCurve,
//					heuristicAmmendmends,
//					simPsychoAcousticAmmendmends
//				);
//				
//				var efficiencyRanks : Vector.<EfficiencyRank> = _computeEfficiencyRanks (
//					paramName,
//					paramsValues,
//					paramsAmmendments,
//					complianceRanks
//				);
//				
//				observation.idealCurveStreams[paramName] = idealCurve;
//				observation.heuristicAmmendmentStreams[paramName] = heuristicAmmendmends;
//				observation.simPsychoAcousticAmmendmendStreams[paramName] = simPsychoAcousticAmmendmends;
//				observation.complianceRankStreams[paramName] = complianceRanks;
//				observation.efficiencyRankStreams[paramName] = efficiencyRanks;
//			}
//			
//			
//			observation.idealCurveContinuation = _extrapolateIdealCurveContinuation (observation);
//			observation.nextGmUnitAmmendments = _computenextGmUnitAmmendments (observation);
//
//			return observation;
//		}
		
		private function _computenextGmUnitAmmendments (observation : TraitRemarks) : Vector.<Ammendment> {
			// TODO
			return new Vector.<Ammendment>;
		}
		
		private function _extrapolateIdealCurveContinuation (observation : TraitRemarks) : IdealParamCurve {
			// TODO
			return new IdealParamCurve;
		}
		
		private function _computeEfficiencyRanks (
			paramName : String,
			paramsValues : Vector.<GmUnitParam>,
			paramsAmmendments : Vector.<Ammendment>,
			complianceRanks: Vector.<ComplianceRank>
		) : Vector.<EfficiencyRank> {
			// TODO
			return new Vector.<EfficiencyRank>;
		}
		
		private function _computeComplianceRanks (
			paramName : String, 
			paramsValues : Vector.<GmUnitParam>, 
			idealCurve : IdealParamCurve,
			heuristicAmmendmends : Vector.<Ammendment>,
			simPsychoAcousticAmmendmends : Vector.<Ammendment>
		) : Vector.<ComplianceRank> {
			// TODO
			return new Vector.<ComplianceRank>;
		}
		
		private function _getSimmulatedPsychoAcousticsAmmendmentsTo (paramName : String, gmSlice : GmSlice) : Vector.<Ammendment> {
			// TODO
			return new Vector.<Ammendment>;
		}
		
		private function _getHeuristicsAmmendmentsTo (paramName : String, gmSlice : GmSlice) : Vector.<Ammendment> {
			// TODO
			return new Vector.<Ammendment>;
		}
		
		private function _getIdealCurveFor (paramName : String, gmSlice : GmSlice) : IdealParamCurve {
			// TODO
			return new IdealParamCurve;
		}
		
		/**
		 * RO: Pentru inaltimi, produce basul si descantul (cea mai grava/acuta nota din acord).
		 * Se ia in consideratie acordul anterior (acolo unde exista), si se favorizeaza un
		 * mers al vocilor externe bazat pe (1) salturi mici, (2) merst treptat sau (3) nota 
		 * tinuta, in aceasta ordine. Salturile mari sunt defavorizate (cu cat mai mari, cu
		 * atat mai defavorizate).
		 * 
		 * Pentru durate nu face nimic: in clipa de fata imi face impresia ca duratele nu
		 * au nevoie de un "punct de pornire"; si nici nu reusesc sa trasez nicio analogie
		 * (in scopul generalizarii algoritmului).
		 */
		private function _findStartingPointFor ( analysisSlice : GmSlice,
			trait : MusicalTrait) : TraitRemarks {
			
			var remarks : TraitRemarks = new TraitRemarks;
			remarks.trait = trait;
			
			var params : Dictionary = new Dictionary;
			var tn : String = trait.name;
			switch (tn) {
				case MusicalTrait.PITCH:
					
					// RO: Sunetul din bas
					//
					// Acordurile posibile sunt create pornind de la un sunet din bas, peste
					// care (Sau sub care) se adauga intervale, in functie de preferintele
					// utilizatorului (exprimate in `configuration.harmonic_ranks).
					//
					// Aceste sunete sunt alese aleator, dintr-un interval ce reprezinta un
					// sfert din ambitusul total agreat de utilizator, pozitionat in grav.
					//
					// Daca acesta este primul acord pe care il generam (`analysisSlice`)
					// este gol, toate inaltimile eligibile au sanse egale de a fi selectate.
					// In caz contrar, inaltimile din vecinatatea basului fostului acord 
					// (respectand ambitusul) sunt favorizate in detrimentul celorlalte.
					// Favorizarea urmaza o curba predefinita (in `BASS_DESCANT_BIAS_TABLE`).

					var allPitches : Vector.<uint> = _getAvailablePitchesAt (
						_getCurrentPointInTime());
					var numPitches : uint = allPitches.length;
					var aQuarter : uint = Math.ceil (numPitches * 0.25);
					var lowest : uint = allPitches[0];
					var lowQuarterMax : uint = (lowest + aQuarter);
					var randFn : Function = _getCustomRandomFunc (_getSeededPRNGSetting ());
					var bassPitch : uint = 0;
					
					// RO: Consideram intai cazul in care avem acorduri generate anterior (pentru
					// ca, in caz că in niciunul din acordurile anterioare nu putem gasi o
					// inaltime la bass -- sa zicem ca am avut pauze -- sa procedam ca si cum am
					// fi la primul acord).
					//
					// O nota despre `isInCurrentRange`, folosit mai jos: ma astept ca la un
					// moment dat sa vreau sa limitez ambitusul disponibil, in functie de 
					// punctul in timp al generarii de material muzical. Daca de la ultimul 
					// acord generat, ambitusul disponibil a fost modificat drastic, e posibil
					// ca, ultima nota generata in bas sa cada in afara noului ambitus,
					// caz in care ea trebuie ignorata.
					if (!analysisSlice.isEmpty) {
						
						var picker : WeightedRandomPicker = null;
						var pickerCfg : WRPickerConfig = null;
						var prevUnit : GmUnit = null;
						var i : int = 0;
						var isInCurrentRange : Boolean = false;
						var possiblePitch : uint = 0;
						var possiblePitchWeight : uint = 0;
						var pitchDelta : uint = 0;

						// Bas
						var prevBassPitch : uint = 0;
						i = (analysisSlice.numUnits - 1);
						while (i >= 0 && prevBassPitch == 0) {
							prevUnit = analysisSlice.getUnitAt (i);
							prevBassPitch = prevUnit.bassLayer.pitch;
							i--;
						}
						if (prevBassPitch) {
							isInCurrentRange = (prevBassPitch >= lowest && 
								prevBassPitch <= lowQuarterMax);
							if (isInCurrentRange) {
								pickerCfg = WRPickerConfig.$create().$setNumPicks(1)
									.$setRandomIntegerFunction (
										_makeRandomIntFunctionUsing (randFn));
								for (possiblePitch = lowest; 
									possiblePitch <= lowQuarterMax; possiblePitch++) {
									pitchDelta = Math.abs (possiblePitch - prevBassPitch);
									pickerCfg.$add (possiblePitch, 
										BiasTables.EXTERNAL_VOICES_MELODIC_BIAS[pitchDelta] || 0);
								}
								picker = new WeightedRandomPicker;
								picker.configure (pickerCfg);
								bassPitch = (picker.pick()[0] as uint);
							}
						}
					}
					
					// RO: daca suntem la primul acord, sau din orice motiv nu ne putem folosi
					// de inaltimea basului generata anterior, alegem aleator o inaltime pentru
					// primul bas (fara sa ponderam alegerea in niciun fel).
					if (!bassPitch) {
						bassPitch = NumberUtil.getRandomInteger (lowest, lowQuarterMax, randFn);
					}

					// Export
					params[ParamNames.STARTING_BASS_PITCH] = new GmUnitParam (
						ParamNames.STARTING_BASS_PITCH, bassPitch, Types.UINT);
					break;
				
				// TODO: add traits as needed				
			}
			
			remarks.params = params;
			return remarks;
		}
		
		/**
		 * Computes the harmonical "bias" (here, degree of musical acceptability) of two
		 * chords, by observing the melodic relationship each note from the first chord
		 * makes with its counterpart from the second chord. The goal is to favor those
		 * chord succession where "voices" move in step motion (or small skips).
		 */
		private function _computeHarmonicSuccessionBias (unitA : GmUnit, unitB : GmUnit) : uint {
			// Can only compute bias for chords having the same number of pitches;
			// also, saving that initial number of pitches.
			var iNumPitchesA : uint = unitA.numLayers;
			var iNumPitchesB : uint = unitB.numLayers;
			if (iNumPitchesA != iNumPitchesB) {
				return BiasTables.BASELINE;
			}
			
			// Extract the pitches, so that we can work non-destructively
			var pitchesA : Array = [];
			var i : int;
			for (i = 0; i < iNumPitchesA; i++) {
				pitchesA.push (unitA.getLayerAt(i).pitch);
			}
			var pitchesB : Array = [];
			for (i = 0; i < iNumPitchesB; i++) {
				pitchesB.push (unitB.getLayerAt(i).pitch);
			}
			
			// In homophonic music, pitches in a chord (improperly aka "voices") are
			// hierarchically organized in "external voices" (e.g., the bass and the 
			// soprano in a SATB choir) and "internal voices" (e.g., the alto and the
			// tenor). External voices are, harmonically, more important than internal
			// voices, and lower-pitched voices are more important than higer-pitched
			// voices.
			//
			// Therefore, given two chords with `n` "voices" each, we traverse both of
			// them in 0, n, 0 + 1, n - 1, etc. order, and, while doing so, we multiply
			// the observed bias by a decreasing factor.
			//
			// The "bias" is stored in pre-calculated tables (see class `BiasTables` for
			// an explanation). 
			var pitchA : uint;
			var pitchB : uint;
			var melodicInterval : uint;
			var biasTable : Array;
			var localBias : uint;
			var totalBias : uint = 0;
			var biasFactor : int = iNumPitchesA;
			while (pitchesA.length > 0) {
				biasTable = (pitchesA.length > iNumPitchesA - 2)? 
					BiasTables.EXTERNAL_VOICES_MELODIC_BIAS :
					BiasTables.INTERNAL_VOICES_MELODIC_BIAS;
				pitchA = pitchesA.shift();
				pitchB = pitchesB.shift();
				melodicInterval = Math.abs (pitchA - pitchB);
				localBias = ((biasTable[melodicInterval] as uint) * biasFactor)
				totalBias += localBias;
				pitchesA.reverse();
				pitchesB.reverse();
				biasFactor--; 
			}
			return totalBias;
		}

		
		private function _getAnalysisWindowSpan () : uint {
			_assertConfigItem ("analysisWindow");
			return (_config.analysisWindow as uint)
		}
		
		private function _getCurrentTraitImportance (trait : MusicalTrait) : Number {
			// TODO
			return 0;
		}
		
		private function _makeUnitsFromTraitsData (traitsLists : Dictionary) : Vector.<GmUnit> {
			
			var units : Vector.<GmUnit> = new Vector.<GmUnit>;
			
			// PITCH
			// We create blueprints for the possible chords by combining the given bass with as many
			// of the given pitches as possible. Our concerns are:
			// 1) not to place the same pitch twice in the same chord;
			// 2) to consume the queue (we remove the pitches that have been successfully assigned).
			var pitchData : TraitData = (traitsLists[GmUnit.getTraitByName(MusicalTrait.PITCH)] as TraitData);
			var possibleHigherPitches : Vector.<PickableOption> = pitchData.rawMaterial;
			var chordBassPitch : uint = ((pitchData.remarks.params[ParamNames.STARTING_BASS_PITCH] as GmUnitParam).value as uint);
			var numMissingPitches : uint = (NUM_LAYERS_PER_UNIT - 1);
			var pitchGroups : Array = [];
			var groupSignatures : Object = {};
			var currentPitchGroup : Array;
			var pitchExistsInGroup : Boolean;
			var i : int;
			var testPitch : uint;
			var groupSignature : String;
			outer:
			while (possibleHigherPitches.length >= numMissingPitches) {
				i = 0;
				currentPitchGroup = [chordBassPitch];
				inner:
				while (i < possibleHigherPitches.length) {
					if (currentPitchGroup.length == NUM_LAYERS_PER_UNIT) {
						i = 0;
						break inner;
					}
					testPitch = (possibleHigherPitches[i].content as uint);
					pitchExistsInGroup = (currentPitchGroup.indexOf (testPitch) >= 0);
					if (!pitchExistsInGroup) {
						currentPitchGroup.push (testPitch);
						possibleHigherPitches.splice (i, 1);
						i = 0;
						continue inner;
					}
					i++;
				}
				if (currentPitchGroup.length == NUM_LAYERS_PER_UNIT) {
					// We only collect unique chords
					currentPitchGroup.sort();
					groupSignature = currentPitchGroup.join('');
					if (!(groupSignature in groupSignatures)) {
						groupSignatures[groupSignature] = null;
						pitchGroups.push (currentPitchGroup);
					}
				} else {
					// The first group that fails to complete ends the procedure
					break outer;
				}
			}
			// If we could not make up even a single chord, we assume a general pause
			// (i.e., one chord, with all pitches set to `0`)
			if (pitchGroups.length == 0) {
				pitchGroups = [ [0, 0, 0, 0] ];
			}
			// A little cleanup
			pitchData = null;
			possibleHigherPitches = null;
			groupSignatures = null;
			currentPitchGroup = null;
			groupSignature = null;
			
			
			// DURATION
			// Nothing to do here. All returned possible pitches are usable.
			var durationData : TraitData = (traitsLists[GmUnit.getTraitByName(MusicalTrait.DURATION)] as TraitData);
			var possibleDurations : Vector.<PickableOption> = durationData.rawMaterial;
			var fractions : Array = [];
			var numPossibleDurations : uint = possibleDurations.length;
			for (i = 0; i < numPossibleDurations; i++) {
				fractions.push (possibleDurations[i].content as Fraction);
			}
			// A little cleanup
			durationData = null;
			possibleDurations = null;

			
			// COMBINE ALL
			// Combine all info we gathered so far
			var j : int;
			var k : int;
			var currentFraction : Fraction;
			var unit : GmUnit;
			var layer : GmUnitLayer;
			var layers : Vector.<GmUnitLayer>;
			var unitSignature : String;
			var unitSignatures : Object = {};
			var numPitchGroups : uint = pitchGroups.length;
			var numFractions : uint = fractions.length;
			for (i = 0; i < numPitchGroups; i++) {
				currentPitchGroup = (pitchGroups[i] as Array);
				for (j = 0; j < numFractions; j++) {
					currentFraction = (fractions[j] as Fraction);
					unitSignature = currentPitchGroup.join('').concat(currentFraction.toString());
					// Only consider unique combinations
					if (!(unitSignature in unitSignatures)) {
						layers = new Vector.<GmUnitLayer>;
						for (k = 0; k < NUM_LAYERS_PER_UNIT; k++) {
							layer = new GmUnitLayer (currentFraction, currentPitchGroup[k] as uint);
							layers.push (layer);
						}
						unit = new GmUnit (layers);
						units.push (unit);
						unitSignatures[unitSignature] = null;
					} 
				}
			}
			// A little cleanup
			currentFraction = null;
			unit = null;
			layer = null;
			layers = null;
			unitSignature = null;
			unitSignatures = null;
			return units;
		}
		
		private function _findMostAppropriateNextUnit (
			unitsToChooseFrom : Vector.<GmUnit>,
			deterministicsStrength : Number
		) : GmUnit {
			
			if (_outputQueue.length == 0) {
				return unitsToChooseFrom[0];
			}
			
			// Observe melodic progression of voices as we move from chord to chord, and favor chords
			// successions where voices use step motion rather than skip motion
			// TODO: add more refinments
			var i : int;
			var possibleUnit : GmUnit;
			var possibleUnitBias : uint;
			var numUnitsToChooseFrom : uint = unitsToChooseFrom.length;
			var previousUnit : GmUnit = _outputQueue[_outputQueue.length - 1];
			
			
			var unit : GmUnit;
			var highestBias : uint = 0;
			for (i = 0; i < numUnitsToChooseFrom; i++) {
				possibleUnit = unitsToChooseFrom[i];
				possibleUnitBias = _computeHarmonicSuccessionBias (previousUnit, possibleUnit);
				if (possibleUnitBias > highestBias) {
					highestBias = possibleUnitBias;
					unit = possibleUnit;
				}
			}			
			return unit;
		}
		
		private function _getCurrentPointInTime () : Fraction {
			return _computeGmSpan().getFractionOf(_getTargetSpan()) as Fraction;
		}
		
		private function _archivePickerSession (
			pointIntime : Fraction,
			trait : MusicalTrait,
			availableOptions : Vector.<PickableOption>,
			selectedOptions : Vector.<PickableOption>) :void {
			
			// TODO
		}
		
		private function _assertConfigItem (key : String) : void {
			var pass : Boolean = (_config && key && (key in _config) && (_config[key] !== undefined) && (_config[key] !== null));
			if (!pass) {
				throw (new ArgumentError (Strings.sprintf (
					'Failed to locate item `%s` in received configuration, or it was nil.',
					Strings.capitalize (Strings.deCamelize (key), true)
				)));
			}
		}
	}
}