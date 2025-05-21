class ProofAttribute {
  final String name;

  ProofAttribute({this.name = ''});

  Map<String, dynamic> toMap() {
    return {"name": name};
  }

  @override
  String toString() {
    return 'ProofAttribute{name: "$name"}';
  }
}
