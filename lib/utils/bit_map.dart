extension BitMap on int {
  bool getBit(int pos) {
    final x = this >> pos;
    return x & 1 == 1;
  }

  int setBit(int pos, bool bit) {
    final x = 1 << pos;
    if (bit) {
      return this | x;
    }

    return getBit(pos) ? this ^ x : this;
  }
}
