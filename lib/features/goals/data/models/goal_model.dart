class GoalModel {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final int iconCode;
  final int colorValue;
  final String category;
  final String userEmail;
  final String priority; // 'High', 'Medium', 'Low'
  final String status; // 'Active', 'Paused', 'Completed'
  final String? productUrl;
  final double autoDepositAmount;
  final int autoDepositDay;

  GoalModel({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.iconCode,
    required this.colorValue,
    this.category = 'General',
    required this.userEmail,
    this.priority = 'Medium',
    this.status = 'Active',
    this.productUrl,
    this.autoDepositAmount = 0.0,
    this.autoDepositDay = 1,
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get progressPercent100 => (progressPercentage * 100).toInt();

  double get remainingAmount =>
      targetAmount > currentAmount ? targetAmount - currentAmount : 0.0;

  bool get isCompleted => currentAmount >= targetAmount || status == 'Completed';

  bool get isPaused => status == 'Paused';

  int get priorityWeight {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 2;
    }
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return deadline.difference(today).inDays;
  }

  double get monthlyPace {
    if (isCompleted || isPaused || remainingAmount <= 0) return 0.0;
    final days = daysRemaining;
    if (days <= 0) return remainingAmount;
    final months = (days / 30.44).ceil();
    return (remainingAmount / (months > 0 ? months : 1)).clamp(0.0, remainingAmount);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'iconCode': iconCode,
      'colorValue': colorValue,
      'category': category,
      'userEmail': userEmail,
      'priority': priority,
      'status': status,
      'productUrl': productUrl,
      'autoDepositAmount': autoDepositAmount,
      'autoDepositDay': autoDepositDay,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(map['targetDate'] as String),
      iconCode: map['iconCode'] as int,
      colorValue: map['colorValue'] as int,
      category: map['category'] as String? ?? 'General',
      userEmail: map['userEmail'] as String,
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Active',
      productUrl: map['productUrl'] as String?,
      autoDepositAmount: (map['autoDepositAmount'] as num?)?.toDouble() ?? 0.0,
      autoDepositDay: (map['autoDepositDay'] as int?) ?? 1,
    );
  }

  GoalModel copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    int? iconCode,
    int? colorValue,
    String? category,
    String? userEmail,
    String? priority,
    String? status,
    String? productUrl,
    double? autoDepositAmount,
    int? autoDepositDay,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      userEmail: userEmail ?? this.userEmail,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      productUrl: productUrl ?? this.productUrl,
      autoDepositAmount: autoDepositAmount ?? this.autoDepositAmount,
      autoDepositDay: autoDepositDay ?? this.autoDepositDay,
    );
  }
}
