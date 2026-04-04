class TeamMemberModel {
  const TeamMemberModel({
    required this.id,
    required this.name,
    required this.position,
    this.shirtNumber = 0,
    this.age = 22,
    this.rating = 7.0,
    this.stamina = 80,
    this.isStarting = true,
    this.goals = 0,
    this.assists = 0,
  });

  final String id;
  final String name;
  final String position;
  final int shirtNumber;
  final int age;
  final double rating;
  final int stamina;
  final bool isStarting;
  final int goals;
  final int assists;
}
