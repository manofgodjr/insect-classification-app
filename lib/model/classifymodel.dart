import 'classifiermodel.dart';

class ClassifyModel {
  List<String> labels;
  ClassifierModel model;

  ClassifyModel({required this.labels, required this.model});
}

class ClassifierCategory {
  final String label;
  final double score;

  ClassifierCategory(this.label, this.score);

  @override
  String toString() {
    return 'Category{label: $label, score: $score}';
  }
}
