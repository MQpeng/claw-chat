
void main() {
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  
  print('Alphabet: $alphabet');
  print('Length: ${alphabet.length}');
  print('Is 58? ${alphabet.length == 58}');
  
  // Check for duplicates
  final seen = <String>{};
  final duplicates = <String>[];
  for (int i = 0; i < alphabet.length; i++) {
    final c = alphabet[i];
    if (seen.contains(c)) {
      duplicates.add(c);
    } else {
      seen.add(c);
    }
  }
  
  print('Duplicates: $duplicates');
}
