/// Cermin enum Postgres `goal_status`.
enum GoalStatus {
  pending('pending', 'Belum mulai'),
  inProgress('in_progress', 'Berjalan'),
  completed('completed', 'Selesai');

  final String value;
  final String label;

  const GoalStatus(this.value, this.label);

  static GoalStatus fromValue(String? value) {
    for (final s in GoalStatus.values) {
      if (s.value == value) return s;
    }
    return GoalStatus.pending;
  }
}
