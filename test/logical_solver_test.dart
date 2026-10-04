import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/puzzle_generator.dart';
import 'package:sudoku_helper/src/logic/sudoku_engine.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';

const easyBySingles =
    '530070000'
    '600195000'
    '098000060'
    '800060003'
    '400803001'
    '700020006'
    '060000280'
    '000419005'
    '000080079';

const realXYChainPuzzle =
    '700060009'
    '000900500'
    '000050040'
    '090200006'
    '075000300'
    '004003020'
    '060010000'
    '007004000'
    '300020064';

const realAICPuzzle =
    '095020008'
    '030109000'
    '000804010'
    '700400500'
    '080000020'
    '001002004'
    '060308000'
    '000006080'
    '800090760';

const realUniqueRectanglePuzzle =
    '019000000'
    '005300190'
    '000900000'
    '080003400'
    '700000805'
    '001800020'
    '000032000'
    '072001500'
    '000060300';

const realBugPlusOnePuzzle =
    '025003400'
    '600040050'
    '000200000'
    '000470900'
    '004950300'
    '002031000'
    '030004000'
    '080000006'
    '009300870';

const realAicType2Puzzle =
    '014000090'
    '097104200'
    '060009400'
    '000410000'
    '002000300'
    '000560000'
    '000700030'
    '009001060'
    '030006980';

const hodokuXChainPuzzle =
    '3.4.2..8.'
    '..6......'
    '.5..7.3..'
    '...68..2.'
    '....34...'
    '.6.15.7..'
    '.1.......'
    '..9....6.'
    '..8217..5';

const hodokuRemotePairPuzzle =
    '..845...6'
    '..3..1...'
    '......87.'
    '.......48'
    '.2.1.37..'
    '.6..9....'
    '9...14.3.'
    '1.7.2..5.'
    '2........';

const hodokuUniqueRectangleType3Puzzle =
    '.8..3.1..'
    '.....23..'
    '..64...75'
    '3.9.2....'
    '.2.5.1.8.'
    '..7.4...2'
    '7..6.....'
    '......8..'
    '54......7';

const hodokuDiscontinuousNiceLoopState =
    '3.74651..'
    '215798436'
    '4..2.....'
    '...68..43'
    '..4.2...1'
    '..3.4.2..'
    '..1.....7'
    '.....2...'
    '53.87.91.';

const hodokuContinuousNiceLoopState =
    '.4..6.1.2'
    '.275..496'
    '.....43.8'
    '41...7985'
    '....5.2.1'
    '......6.7'
    '..4....13'
    '.619...24'
    '.3...1.69';

void main() {
  const logicalSolver = LogicalSolver();
  const engine = SudokuEngine();
  const generator = PuzzleGenerator();

  test('legacy difficulty indexes stay compatible with saved games', () {
    expect(PuzzleDifficulty.beginner.index, 0);
    expect(PuzzleDifficulty.easy.index, 1);
    expect(PuzzleDifficulty.medium.index, 2);
    expect(PuzzleDifficulty.hard.index, 3);
    expect(PuzzleDifficulty.expert.index, 4);
    expect(PuzzleDifficulty.master.index, 5);
  });

  test('logical solver completes an entry puzzle using only singles', () {
    final result = logicalSolver.solve(SudokuBoard.parse(easyBySingles).values);

    expect(result.solved, isTrue);
    expect(result.hardestDifficulty, PuzzleDifficulty.beginner);
    expect(result.steps, hasLength(51));
    expect(
      result.steps.every(
        (step) =>
            step.technique == LogicalTechnique.nakedSingle ||
            step.technique == LogicalTechnique.hiddenSingle,
      ),
      isTrue,
    );
  });

  test('generator returns unique puzzles at all requested ratings', () {
    for (final difficulty in PuzzleDifficulty.values) {
      final generated = generator.generate(
        difficulty,
        seed: 20260929 + difficulty.index,
      );
      final uniqueness = engine.analyzeSolutions(generated.puzzle.values);
      final logicalResult = logicalSolver.solve(generated.puzzle.values);

      expect(uniqueness.hasUniqueSolution, isTrue, reason: difficulty.label);
      expect(logicalResult.solved, isTrue, reason: difficulty.label);
      expect(
        logicalResult.hardestDifficulty,
        difficulty,
        reason: difficulty.label,
      );
    }
  });

  for (final difficulty in PuzzleDifficulty.values) {
    test('${difficulty.label} keeps an exact-rated fallback puzzle', () {
      final generated = generator.generate(
        difficulty,
        seed: 20261004 + difficulty.index,
        maxAttempts: 0,
      );
      final result = logicalSolver.solve(generated.puzzle.values);

      expect(result.solved, isTrue, reason: difficulty.label);
      expect(result.hardestDifficulty, difficulty, reason: difficulty.label);
      _expectSolutionSafeTrace(
        generated.puzzle.values,
        solver: logicalSolver,
        engine: engine,
        reason: '${difficulty.label} fallback',
      );
    });
  }

  test('advanced real-puzzle corpus keeps every inference solution-safe', () {
    for (final encoded in [
      realXYChainPuzzle,
      realAICPuzzle,
      realUniqueRectanglePuzzle,
      realBugPlusOnePuzzle,
      realAicType2Puzzle,
      hodokuXChainPuzzle,
      hodokuRemotePairPuzzle,
      hodokuUniqueRectangleType3Puzzle,
      hodokuDiscontinuousNiceLoopState,
      hodokuContinuousNiceLoopState,
    ]) {
      _expectSolutionSafeTrace(
        SudokuBoard.parse(encoded).values,
        solver: logicalSolver,
        engine: engine,
        reason: encoded.substring(0, 9),
      );
    }
  });

  test('published HoDoKu examples reach their named techniques', () {
    for (final example in [
      (hodokuXChainPuzzle, LogicalTechnique.xChain),
      (hodokuUniqueRectangleType3Puzzle, LogicalTechnique.uniqueRectangleType3),
    ]) {
      final result = logicalSolver.solve(SudokuBoard.parse(example.$1).values);
      expect(result.solved, isTrue, reason: example.$2.label);
      expect(
        result.steps.any((step) => step.technique == example.$2),
        isTrue,
        reason: example.$2.label,
      );
    }
  });

  test('published HoDoKu Remote Pairs state removes its documented 5', () {
    final state = _hodokuRemotePairState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.remotePair,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.remotePair);
    expect(step.chainCells, hasLength(4));
    expect(step.eliminations, contains(const CandidateRef(51, 5)));
  });

  test('hard puzzle includes an explainable advanced structure', () {
    final generated = generator.generate(PuzzleDifficulty.hard, seed: 20260932);
    final result = logicalSolver.solve(generated.puzzle.values);

    expect(result.solved, isTrue);
    expect(
      result.steps.any((step) => step.difficulty == PuzzleDifficulty.hard),
      isTrue,
    );
  });

  test('naked quad removes its four digits from the rest of a unit', () {
    final state = _nakedQuadState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.nakedQuad,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.nakedQuad);
    expect(step.eliminations, contains(const CandidateRef(4, 1)));
  });

  test('hidden quad removes other candidates from its four cells', () {
    final state = _hiddenQuadState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.hiddenQuad,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.hiddenQuad);
    expect(step.eliminations, contains(const CandidateRef(0, 5)));
  });

  test('Swordfish uses three base and cover lines', () {
    final state = _fishState(
      digit: 9,
      pattern: const {
        0: {0, 3},
        3: {3, 6},
        6: {0, 6},
      },
      target: 9,
    );
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.swordfish,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.swordfish);
    expect(step.pattern.map((candidate) => candidate.index).toSet(), {
      0,
      3,
      30,
      33,
      54,
      60,
    });
    expect(step.eliminations, contains(const CandidateRef(9, 9)));
  });

  test('Jellyfish uses four base and cover lines', () {
    final state = _fishState(
      digit: 8,
      pattern: const {
        0: {0, 2},
        2: {2, 4},
        4: {4, 6},
        6: {0, 6},
      },
      target: 9,
    );
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.jellyfish,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.jellyfish);
    expect(step.pattern, hasLength(8));
    expect(step.eliminations, contains(const CandidateRef(9, 8)));
  });

  test('Finned X-Wing keeps only eliminations inside the fin box', () {
    final state = _finnedXWingState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.finnedXWing,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.finnedXWing);
    expect(step.eliminations, contains(const CandidateRef(31, 9)));
    expect(step.eliminations.every((item) => item.index == 31), isTrue);
  });

  test('unique rectangle type 1 removes the deadly pair from one corner', () {
    final state = _uniqueRectangleState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.uniqueRectangleType1,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.uniqueRectangleType1);
    expect(step.eliminations, {
      const CandidateRef(28, 1),
      const CandidateRef(28, 2),
    });
  });

  test('unique rectangle type 2 removes the shared roof candidate', () {
    final state = _uniqueRectangleType2State();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.uniqueRectangleType2,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.uniqueRectangleType2);
    expect(step.eliminations, contains(const CandidateRef(10, 3)));
  });

  test('unique rectangle type 3 combines its roof extras with a subset', () {
    final state = _uniqueRectangleType3State();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.uniqueRectangleType3,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.uniqueRectangleType3);
    expect(step.eliminations, contains(const CandidateRef(13, 4)));
    expect(step.eliminations, contains(const CandidateRef(13, 6)));
    expect(step.eliminations, contains(const CandidateRef(13, 9)));
  });

  test('unique rectangle type 4 uses the roof strong link', () {
    final state = _uniqueRectangleType4State();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.uniqueRectangleType4,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.uniqueRectangleType4);
    expect(step.eliminations, {
      const CandidateRef(9, 2),
      const CandidateRef(12, 2),
    });
    expect(step.links.single.strength, LogicalLinkStrength.strong);
  });

  test('BUG+1 places the only additional candidate', () {
    final state = _bugPlusOneState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.bugPlusOne,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.bugPlusOne);
    expect(step.placementIndex, 0);
    expect(step.placementDigit, 3);
  });

  test('XYZ-Wing eliminates the shared candidate seen by all three cells', () {
    final state = _xyzWingState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.xyzWing,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.xyzWing);
    expect(step.pattern.map((candidate) => candidate.index).toSet(), {
      12,
      21,
      24,
    });
    expect(step.eliminations, contains(const CandidateRef(22, 3)));
  });

  test('simple coloring trap removes a candidate seeing both colors', () {
    final state = _simpleColoringTrapState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.simpleColoringTrap,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.simpleColoringTrap);
    expect(step.eliminations, contains(const CandidateRef(3, 9)));
    expect(step.links, hasLength(3));
    expect(step.candidateColors.length, 4);
    expect(step.candidateColors.values.toSet(), {0, 1});
  });

  test(
    'simple coloring wrap removes every candidate of a conflicting color',
    () {
      final state = _simpleColoringWrapState();
      final step = logicalSolver.findTechnique(
        values: state.values,
        excludedMasks: state.excludedMasks,
        technique: LogicalTechnique.simpleColoringWrap,
      );

      expect(step, isNotNull);
      expect(step!.technique, LogicalTechnique.simpleColoringWrap);
      expect(step.eliminations.map((item) => item.index).toSet(), {0, 10, 30});
      expect(step.links, hasLength(4));
    },
  );

  test('X-Chain starts and ends with strong links on one digit', () {
    final state = _xChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.xChain,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.xChain);
    expect(step.eliminations, contains(const CandidateRef(3, 9)));
    expect(step.chainNodes, hasLength(step.links.length + 1));
    expect(step.links.length, greaterThanOrEqualTo(5));
    expect(step.links.first.strength, LogicalLinkStrength.strong);
    expect(step.links.last.strength, LogicalLinkStrength.strong);
    expect(step.chainNodes.map((node) => node.digit).toSet(), {9});
  });

  test('Remote Pairs removes both digits seen from opposite endpoints', () {
    final state = _remotePairState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.remotePair,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.remotePair);
    expect(step.chainCells, hasLength(4));
    expect(step.eliminations, contains(const CandidateRef(5, 1)));
    expect(step.eliminations, contains(const CandidateRef(5, 2)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('skyscraper exposes a strong-weak-strong chain', () {
    final state = _syntheticChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.skyscraper,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.skyscraper);
    expect(step.eliminations, contains(const CandidateRef(14, 9)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('two-string kite exposes a strong-weak-strong chain', () {
    final state = _syntheticChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.twoStringKite,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.twoStringKite);
    expect(step.eliminations, contains(const CandidateRef(36, 9)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('empty rectangle exposes grouped inference and one elimination', () {
    final state = _emptyRectangleState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.emptyRectangle,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.emptyRectangle);
    expect(step.eliminations, contains(const CandidateRef(37, 9)));
    expect(step.links, hasLength(1));
    expect(step.groupLinks.map((link) => link.strength), [
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('W-Wing exposes the complete five-link chain', () {
    final state = _wWingState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.wWing,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.wWing);
    expect(step.eliminations, contains(const CandidateRef(4, 2)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('XY-Chain finds an ordered four-cell alternating chain', () {
    final state = _xyChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.xyChain,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.xyChain);
    expect(step.chainCells, hasLength(4));
    expect(step.chainNodes, hasLength(step.links.length + 1));
    expect(step.chainNodes.first.digit, step.chainNodes.last.digit);
    expect(step.chainCells.toSet(), {0, 3, 27, 30});
    expect(step.eliminations, contains(const CandidateRef(9, 1)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('XY-Chain is used while solving a real unique puzzle', () {
    final board = SudokuBoard.parse(realXYChainPuzzle);
    final result = logicalSolver.solve(board.values);
    final step = result.steps.firstWhere(
      (step) => step.technique == LogicalTechnique.xyChain,
    );

    expect(engine.analyzeSolutions(board.values).hasUniqueSolution, isTrue);
    expect(result.solved, isTrue);
    expect(step.chainCells.length, inInclusiveRange(4, 8));
    expect(step.links, hasLength(step.chainCells.length * 2 - 1));
    expect(step.eliminations, isNotEmpty);
  });

  test('AIC combines cell and unit links in alternating order', () {
    final state = _aicState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.aic,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.aic);
    expect(step.eliminations, contains(const CandidateRef(6, 1)));
    expect(step.links.length, greaterThanOrEqualTo(5));
    expect(step.links.length, lessThanOrEqualTo(11));
    expect(step.links.first.strength, LogicalLinkStrength.strong);
    expect(step.links.last.strength, LogicalLinkStrength.strong);
    for (var index = 1; index < step.links.length; index++) {
      expect(step.links[index].strength, isNot(step.links[index - 1].strength));
    }
    expect(step.links.every((link) => link.reason != null), isTrue);
    expect(step.chainNodes, hasLength(step.links.length + 1));
    expect(step.chainNodes.first.digit, step.chainNodes.last.digit);
  });

  test('AIC Type 2 removes crossed endpoint candidates', () {
    final state = _aicType2State();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.aicType2,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.aicType2);
    expect(step.eliminations, contains(const CandidateRef(0, 4)));
    expect(step.eliminations, contains(const CandidateRef(27, 1)));
    expect(step.links.length, inInclusiveRange(5, 11));
    expect(step.chainNodes.first.digit, isNot(step.chainNodes.last.digit));
    for (var index = 1; index < step.links.length; index++) {
      expect(step.links[index].strength, isNot(step.links[index - 1].strength));
    }
  });

  test('X-Cycle closes a one-digit alternating loop', () {
    final state = _xCycleState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.xCycle,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.xCycle);
    expect(step.isLoop, isTrue);
    expect(step.chainNodes.map((node) => node.digit).toSet(), {1});
    expect(step.links, hasLength(step.chainNodes.length));
    expect(step.isPlacement || step.eliminations.isNotEmpty, isTrue);
    _expectAlternatingLoop(step);
  });

  test('discontinuous Nice Loop resolves its strong-strong break', () {
    final state = _discontinuousNiceLoopState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.discontinuousNiceLoop,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.discontinuousNiceLoop);
    expect(step.isLoop, isTrue);
    expect(step.links, hasLength(step.chainNodes.length));
    expect(step.links.first.strength, step.links.last.strength);
    expect(step.isPlacement || step.eliminations.length == 1, isTrue);
    _expectAlternatingLoop(step);
  });

  test('continuous Nice Loop upgrades every weak link', () {
    final state = _continuousNiceLoopState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.continuousNiceLoop,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.continuousNiceLoop);
    expect(step.isLoop, isTrue);
    expect(step.links, hasLength(step.chainNodes.length));
    expect(step.links.first.strength, isNot(step.links.last.strength));
    expect(step.eliminations, isNotEmpty);
    _expectAlternatingLoop(step);
  });

  test('published HoDoKu Nice Loop states produce safe loop inferences', () {
    final discontinuousState = _hodokuDiscontinuousNiceLoopState();
    final discontinuous = logicalSolver.findTechnique(
      values: discontinuousState.values,
      excludedMasks: discontinuousState.excludedMasks,
      technique: LogicalTechnique.discontinuousNiceLoop,
    );
    final continuous = logicalSolver.findTechnique(
      values: SudokuBoard.parse(hodokuContinuousNiceLoopState).values,
      excludedMasks: List<int>.filled(SudokuBoard.cellCount, 0),
      technique: LogicalTechnique.continuousNiceLoop,
    );

    expect(discontinuous, isNotNull);
    expect(discontinuous!.isPlacement, isTrue);
    final discontinuousSolution = engine
        .analyzeSolutions(discontinuousState.values)
        .firstSolution!;
    expect(
      discontinuous.placementDigit,
      discontinuousSolution[discontinuous.placementIndex!],
    );
    expect(continuous, isNotNull);
    expect(continuous!.eliminations.toSet(), {
      const CandidateRef(13, 3),
      const CandidateRef(30, 2),
      const CandidateRef(48, 2),
      const CandidateRef(49, 2),
      const CandidateRef(49, 3),
      const CandidateRef(59, 6),
      const CandidateRef(59, 8),
      const CandidateRef(68, 8),
    });
  });

  test('level-five loop or AIC solves a real unique puzzle', () {
    final board = SudokuBoard.parse(realAICPuzzle);
    final result = logicalSolver.solve(board.values);
    final step = result.steps.firstWhere(
      (step) => step.difficulty == PuzzleDifficulty.master,
    );

    expect(engine.analyzeSolutions(board.values).hasUniqueSolution, isTrue);
    expect(result.solved, isTrue);
    expect(result.hardestDifficulty, PuzzleDifficulty.master);
    expect(step.links.length, inInclusiveRange(4, 12));
    expect(step.links.every((link) => link.reason != null), isTrue);
    expect(step.isPlacement || step.eliminations.isNotEmpty, isTrue);
  });
}

void _expectAlternatingLoop(LogicalStep step) {
  for (var index = 1; index < step.links.length; index++) {
    expect(step.links[index].strength, isNot(step.links[index - 1].strength));
  }
}

void _expectSolutionSafeTrace(
  List<int> puzzle, {
  required LogicalSolver solver,
  required SudokuEngine engine,
  required String reason,
}) {
  final analysis = engine.analyzeSolutions(puzzle);
  expect(analysis.hasUniqueSolution, isTrue, reason: reason);
  final solution = analysis.firstSolution!;
  final values = List<int>.of(puzzle);
  final excludedMasks = List<int>.filled(SudokuBoard.cellCount, 0);

  for (var count = 0; count < 600 && values.contains(0); count++) {
    final step = solver.findNext(values: values, excludedMasks: excludedMasks);
    expect(step, isNotNull, reason: '$reason stopped at step $count');
    final safeStep = step!;
    if (safeStep.placementIndex case final index?) {
      expect(
        safeStep.placementDigit,
        solution[index],
        reason: '$reason ${safeStep.technique.label} placed a wrong digit',
      );
    }
    for (final elimination in safeStep.eliminations) {
      expect(
        elimination.digit,
        isNot(solution[elimination.index]),
        reason:
            '$reason ${safeStep.technique.label} removed the solution candidate at r${elimination.index ~/ 9 + 1}c${elimination.index % 9 + 1}',
      );
    }
    solver.applyStep(
      values: values,
      excludedMasks: excludedMasks,
      step: safeStep,
    );
  }

  expect(values, solution, reason: '$reason did not reach the unique solution');
}

({List<int> values, List<int> excludedMasks}) _syntheticChainState() {
  const allowedNines = {0, 4, 14, 36, 41};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : SudokuEngine.bitFor(9),
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _nakedQuadState() {
  final excludedMasks = List<int>.filled(81, 0);
  final allowedMasks = <int>[
    SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2),
    SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3),
    SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4),
    SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4),
  ];
  for (var index = 0; index < allowedMasks.length; index++) {
    excludedMasks[index] = SudokuEngine.fullMask & ~allowedMasks[index];
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _hiddenQuadState() {
  final excludedMasks = List<int>.filled(81, 0);
  final quadMask =
      SudokuEngine.bitFor(1) |
      SudokuEngine.bitFor(2) |
      SudokuEngine.bitFor(3) |
      SudokuEngine.bitFor(4);
  for (var index = 4; index < 9; index++) {
    excludedMasks[index] |= quadMask;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _fishState({
  required int digit,
  required Map<int, Set<int>> pattern,
  required int target,
}) {
  final bit = SudokuEngine.bitFor(digit);
  final allowed = <int>{target};
  for (final entry in pattern.entries) {
    allowed.addAll(entry.value.map((column) => entry.key * 9 + column));
  }
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowed.contains(index) ? 0 : bit,
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _finnedXWingState() {
  final bit = SudokuEngine.bitFor(9);
  const allowed = {0, 4, 31, 36, 39, 40};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowed.contains(index) ? 0 : bit,
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _uniqueRectangleState() {
  final excludedMasks = List<int>.filled(81, 0);
  final pairMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  for (final index in [0, 1, 27]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~pairMask;
  }
  final extraMask = pairMask | SudokuEngine.bitFor(3);
  excludedMasks[28] = SudokuEngine.fullMask & ~extraMask;
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _uniqueRectangleType2State() {
  final excludedMasks = List<int>.filled(81, 0);
  final pairMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  for (final index in [0, 3]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~pairMask;
  }
  final roofMask = pairMask | SudokuEngine.bitFor(3);
  for (final index in [9, 12]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~roofMask;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _uniqueRectangleType3State() {
  final excludedMasks = List<int>.filled(81, 0);
  final pairMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  for (final index in [0, 3]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~pairMask;
  }
  final firstRoofMask =
      pairMask | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(6);
  final secondRoofMask =
      pairMask | SudokuEngine.bitFor(6) | SudokuEngine.bitFor(9);
  excludedMasks[9] = SudokuEngine.fullMask & ~firstRoofMask;
  excludedMasks[12] = SudokuEngine.fullMask & ~secondRoofMask;
  final firstCompanionMask = SudokuEngine.bitFor(4) | SudokuEngine.bitFor(6);
  final secondCompanionMask = SudokuEngine.bitFor(6) | SudokuEngine.bitFor(9);
  excludedMasks[10] = SudokuEngine.fullMask & ~firstCompanionMask;
  excludedMasks[11] = SudokuEngine.fullMask & ~secondCompanionMask;
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _uniqueRectangleType4State() {
  final excludedMasks = List<int>.filled(81, 0);
  final pairMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  for (final index in [0, 3]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~pairMask;
  }
  excludedMasks[9] =
      SudokuEngine.fullMask & ~(pairMask | SudokuEngine.bitFor(3));
  excludedMasks[12] =
      SudokuEngine.fullMask & ~(pairMask | SudokuEngine.bitFor(4));
  for (final index in SudokuEngine.rows[1]) {
    if (index != 9 && index != 12) {
      excludedMasks[index] |= SudokuEngine.bitFor(1);
    }
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _simpleColoringTrapState() {
  const allowedNines = {0, 1, 3, 28, 30, 66};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : SudokuEngine.bitFor(9),
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _simpleColoringWrapState() {
  const allowedNines = {0, 3, 10, 20, 28, 30};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : SudokuEngine.bitFor(9),
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _xChainState() {
  final bit = SudokuEngine.bitFor(9);
  const allowedNines = {0, 3, 6, 18, 20, 30, 47, 50, 66};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : bit,
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _xCycleState() {
  final allowedMasks = List<int>.filled(81, SudokuEngine.bitFor(8));
  for (final index in [0, 3, 9, 12, 27, 30]) {
    allowedMasks[index] |= SudokuEngine.bitFor(1);
  }
  return (
    values: List<int>.filled(81, 0),
    excludedMasks: [
      for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
    ],
  );
}

({List<int> values, List<int> excludedMasks}) _discontinuousNiceLoopState() {
  final allowedMasks = List<int>.filled(81, SudokuEngine.bitFor(9));
  allowedMasks[0] |= SudokuEngine.bitFor(1) | SudokuEngine.bitFor(8);
  allowedMasks[3] |= SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  allowedMasks[30] |= SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3);
  allowedMasks[27] |= SudokuEngine.bitFor(3) | SudokuEngine.bitFor(1);
  return (
    values: List<int>.filled(81, 0),
    excludedMasks: [
      for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
    ],
  );
}

({List<int> values, List<int> excludedMasks})
_hodokuDiscontinuousNiceLoopState() {
  final excludedMasks = List<int>.filled(SudokuBoard.cellCount, 0);
  for (final candidate in const [
    CandidateRef(39, 9),
    CandidateRef(48, 9),
    CandidateRef(57, 5),
    CandidateRef(59, 3),
    CandidateRef(59, 9),
    CandidateRef(66, 5),
  ]) {
    excludedMasks[candidate.index] |= SudokuEngine.bitFor(candidate.digit);
  }
  return (
    values: SudokuBoard.parse(hodokuDiscontinuousNiceLoopState).values.toList(),
    excludedMasks: excludedMasks,
  );
}

({List<int> values, List<int> excludedMasks}) _continuousNiceLoopState() {
  final allowedMasks = List<int>.filled(81, SudokuEngine.bitFor(9));
  allowedMasks[0] |= SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  allowedMasks[27] |= SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3);
  allowedMasks[30] |= SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4);
  allowedMasks[3] |= SudokuEngine.bitFor(4) | SudokuEngine.bitFor(1);
  return (
    values: List<int>.filled(81, 0),
    excludedMasks: [
      for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
    ],
  );
}

({List<int> values, List<int> excludedMasks}) _remotePairState() {
  final excludedMasks = List<int>.filled(81, 0);
  final pairMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  for (final index in [0, 3, 30, 32]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~pairMask;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _hodokuRemotePairState() {
  final values = SudokuBoard.parse(
    '798452316'
    '603781092'
    '012030870'
    '370265048'
    '820143760'
    '060897023'
    '980014237'
    '107028050'
    '200070081',
  ).values.toList();
  return (
    values: values,
    excludedMasks: List<int>.filled(SudokuBoard.cellCount, 0),
  );
}

({List<int> values, List<int> excludedMasks}) _bugPlusOneState() {
  final excludedMasks = List<int>.generate(81, (index) {
    final row = index ~/ 9;
    final column = index % 9;
    final firstDigit = (row * 3 + row ~/ 3 + column) % 9 + 1;
    final secondDigit = firstDigit % 9 + 1;
    var allowedMask =
        SudokuEngine.bitFor(firstDigit) | SudokuEngine.bitFor(secondDigit);
    if (index == 0) allowedMask |= SudokuEngine.bitFor(3);
    return SudokuEngine.fullMask & ~allowedMask;
  });
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _xyzWingState() {
  final excludedMasks = List<int>.filled(81, 0);
  final masks = <int, int>{
    21:
        SudokuEngine.bitFor(1) |
        SudokuEngine.bitFor(2) |
        SudokuEngine.bitFor(3),
    12: SudokuEngine.bitFor(1) | SudokuEngine.bitFor(3),
    24: SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3),
  };
  for (final entry in masks.entries) {
    excludedMasks[entry.key] = SudokuEngine.fullMask & ~entry.value;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _emptyRectangleState() {
  final excludedMasks = List<int>.filled(81, 0);
  final bit = SudokuEngine.bitFor(9);
  const boxCandidates = {1, 9, 11, 19};
  for (final index in SudokuEngine.boxes[0]) {
    if (!boxCandidates.contains(index)) excludedMasks[index] |= bit;
  }
  const conjugatePair = {13, 40};
  for (final index in SudokuEngine.columns[4]) {
    if (!conjugatePair.contains(index)) excludedMasks[index] |= bit;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _wWingState() {
  final excludedMasks = List<int>.filled(81, 0);
  final wingMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  excludedMasks[0] = SudokuEngine.fullMask & ~wingMask;
  excludedMasks[40] = SudokuEngine.fullMask & ~wingMask;
  final linkBit = SudokuEngine.bitFor(1);
  const conjugatePair = {18, 22};
  for (final index in SudokuEngine.rows[2]) {
    if (!conjugatePair.contains(index)) excludedMasks[index] |= linkBit;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _xyChainState() {
  final excludedMasks = List<int>.filled(81, 0);
  final masks = <int, int>{
    0: SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2),
    3: SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3),
    30: SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4),
    27: SudokuEngine.bitFor(4) | SudokuEngine.bitFor(1),
  };
  for (final entry in masks.entries) {
    excludedMasks[entry.key] = SudokuEngine.fullMask & ~entry.value;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _aicState() {
  final defaultMask =
      SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5) | SudokuEngine.bitFor(6);
  final allowedMasks = List<int>.filled(81, defaultMask);
  allowedMasks[0] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5);
  allowedMasks[1] = allowedMasks[0];
  allowedMasks[6] = allowedMasks[0];
  allowedMasks[15] = allowedMasks[0];
  allowedMasks[54] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2) | SudokuEngine.bitFor(7);
  allowedMasks[57] =
      SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3) | SudokuEngine.bitFor(8);
  allowedMasks[30] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(3) | SudokuEngine.bitFor(9);
  allowedMasks[33] = allowedMasks[0];
  final excludedMasks = [
    for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
  ];
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _aicType2State() {
  final defaultMask =
      SudokuEngine.bitFor(5) | SudokuEngine.bitFor(6) | SudokuEngine.bitFor(8);
  final allowedMasks = List<int>.filled(81, defaultMask);
  allowedMasks[0] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5);
  allowedMasks[3] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2) | SudokuEngine.bitFor(7);
  allowedMasks[30] =
      SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3) | SudokuEngine.bitFor(8);
  allowedMasks[33] =
      SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(9);
  allowedMasks[27] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5);
  final excludedMasks = [
    for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
  ];
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}
