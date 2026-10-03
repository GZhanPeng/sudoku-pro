import 'logical_solver.dart';

class PracticePuzzle {
  const PracticePuzzle({
    required this.technique,
    required this.puzzle,
    required this.summary,
  });

  final LogicalTechnique technique;
  final String puzzle;
  final String summary;
}

const practicePuzzles = <PracticePuzzle>[
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
];
