import 'logical_solver.dart';

enum PracticeCategory {
  foundations('基础候选'),
  structures('鱼与翼'),
  chains('链与闭环'),
  als('几乎锁定集');

  const PracticeCategory(this.label);
  final String label;
}

class PracticePuzzle {
  const PracticePuzzle({
    required this.technique,
    required this.puzzle,
    required this.summary,
    this.initialEliminations = const [],
  });

  final LogicalTechnique technique;
  final String puzzle;
  final String summary;
  final List<CandidateRef> initialEliminations;
  String get id => technique.name;
  PracticeCategory get category => switch (technique) {
    LogicalTechnique.nakedSingle ||
    LogicalTechnique.hiddenSingle ||
    LogicalTechnique.lockedPointing ||
    LogicalTechnique.lockedClaiming ||
    LogicalTechnique.nakedPair ||
    LogicalTechnique.hiddenPair => PracticeCategory.foundations,
    LogicalTechnique.alsXZ ||
    LogicalTechnique.doublyLinkedAlsXZ => PracticeCategory.als,
    LogicalTechnique.xChain ||
    LogicalTechnique.xyChain ||
    LogicalTechnique.remotePair ||
    LogicalTechnique.aic ||
    LogicalTechnique.aicType2 ||
    LogicalTechnique.groupedAic ||
    LogicalTechnique.groupedAicType2 ||
    LogicalTechnique.xCycle ||
    LogicalTechnique.discontinuousNiceLoop ||
    LogicalTechnique.continuousNiceLoop ||
    LogicalTechnique.groupedDiscontinuousNiceLoop ||
    LogicalTechnique.groupedContinuousNiceLoop => PracticeCategory.chains,
    _ => PracticeCategory.structures,
  };
}

const practicePuzzles = <PracticePuzzle>[
  PracticePuzzle(
    technique: LogicalTechnique.nakedSingle,
    puzzle: '530070000600195000098000060800060003400803001700020006060000280000419005000080079',
    summary: '找到只剩一个合法候选的格子，先解释为什么其他数字都不能填。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.hiddenSingle,
    puzzle: '700060009000900500000050040090200006075000300004003020060010000007004000300020064',
    summary: '在一行、一列或一宫中，找到某个数字唯一能够出现的位置。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.lockedPointing,
    puzzle: '700060009000900500000050040090200006075000300004003020060010000007004000300020064',
    summary: '宫内同一数字只落在一条线上，排除这条线在宫外的同数候选。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.nakedPair,
    puzzle: '019000000005300190000900000080003400700000805001800020000032000072001500000060300',
    summary: '在一个单元中找到两个只含相同两数的格子，锁定这两个数字。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.xWing,
    puzzle: '210006083000000000064090000600000100040018020009000004000040835000000000850100062',
    summary: '观察两行或两列中同一候选数形成的矩形。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.skyscraper,
    puzzle: '302000000700000406000071230000004000190000360000800050071540000005000027000000003',
    summary: '寻找两条强链共用一端、另一端错开的“屋顶”。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.twoStringKite,
    puzzle: '700003100010005206000000000108504060000020000060908405000000000603800050005600019',
    summary: '用一个宫连接一条行强链和一条列强链。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.emptyRectangle,
    puzzle: '090000020058007900700609000010200600400000008069008070000105007007900810000000060',
    summary: '观察宫内候选组成的行列交叉与宫外强链。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.wWing,
    puzzle: '302000000700000406000071230000004000190000360000800050071540000005000027000000003',
    summary: '寻找两个相同的双值格，并用外部强链连接。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.xyWing,
    puzzle: '000600020900040100800000035043100009000504000600009350790000008006070000030006000',
    summary: '从一个双值枢纽，观察两个双值翼的共同候选。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.swordfish,
    puzzle: '025003400600040050000200000000470900004950300002031000030004000080000006009300870',
    summary: '寻找同一候选在三条基准线与三条覆盖线之间形成的鱼形结构。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.finnedXWing,
    puzzle: '025003400600040050000200000000470900004950300002031000030004000080000006009300870',
    summary: '先识别矩形和额外的鳍，只排除同时看见鳍的宫内候选。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.uniqueRectangleType1,
    puzzle: '019000000005300190000900000080003400700000805001800020000032000072001500000060300',
    summary: '在已验证唯一解的题目中，避免四个角形成可以交换的致命数对。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.xChain,
    puzzle: '3.4.2..8...6.......5..7.3.....68..2.....34....6.15.7...1.........9....6...8217..5',
    summary: '围绕一个数字交替连接强链与弱链，检查能同时看见两端的格子。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.xyChain,
    puzzle: '700060009000900500000050040090200006075000300004003020060010000007004000300020064',
    summary: '沿双值格交替推理，从链头到链尾追踪同一个候选数。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.aic,
    puzzle: '095020008030109000000804010700400500080000020001002004060308000000006080800090760',
    summary: '交替连接格内与单元内的强弱关系，观察两端共同推出的结论。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.discontinuousNiceLoop,
    puzzle: '3.74651..2157984364..2........68..43..4.2...1..3.4.2....1.....7.....2...53.87.91.',
    summary: '沿闭环追踪到起点，检查两条同强度连接造成的断点结论。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.groupedAic,
    puzzle: '345128900976000281281000345000000010100600030402081509704000128819040653023810794',
    summary: '把宫线交叉区域中的多个候选视为一个组节点，再跟随交替链推理。',
  ),
  PracticePuzzle(
    technique: LogicalTechnique.groupedAicType2,
    puzzle: '2...5376.765.....3..3786.2...43..2.6326.9.14....624...6.2.3..5...7.6...2839...6..',
    summary: '观察组节点交替链两端的交叉候选，区分 Type 2 的排除方式。',
    initialEliminations: [
      CandidateRef(8, 8),
      CandidateRef(27, 1),
      CandidateRef(28, 1),
      CandidateRef(32, 7),
      CandidateRef(53, 7),
      CandidateRef(66, 5),
      CandidateRef(68, 5),
      CandidateRef(75, 1),
      CandidateRef(75, 4),
      CandidateRef(77, 1),
      CandidateRef(77, 7),
      CandidateRef(80, 7),
    ],
  ),
  PracticePuzzle(
    technique: LogicalTechnique.alsXZ,
    puzzle: '.934.7.6.4....59...276...41........591.5...8.2..78....6..25.4...4..........1....3',
    summary: '找到两组比格子数多一个候选的几乎锁定集，辨认受限公共候选 X 与可删数字 Z。',
    initialEliminations: [
      CandidateRef(13, 3),
      CandidateRef(31, 1),
      CandidateRef(31, 2),
      CandidateRef(33, 7),
      CandidateRef(34, 7),
      CandidateRef(40, 2),
      CandidateRef(63, 5),
      CandidateRef(69, 5),
      CandidateRef(72, 5),
      CandidateRef(78, 5),
    ],
  ),
  PracticePuzzle(
    technique: LogicalTechnique.doublyLinkedAlsXZ,
    puzzle: '.........2.....3495...3926..9.........41..98....598..4..182...6......7....3..6...',
    summary: '两个几乎锁定集通过两个受限公共候选连接，观察哪些数字被锁定。',
    initialEliminations: [CandidateRef(4, 5), CandidateRef(5, 5)],
  ),
];
