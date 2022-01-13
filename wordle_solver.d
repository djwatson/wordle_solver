import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.traits;

enum Color {
  Black = 'b',
  Yellow = 'y',
  Green = 'g'
}

auto applyFilter(string[] words, Color color, int position, char letter, ulong cnt) {
  final switch (color) {
  case Color.Black:
    return words.filter!(a => a.count(letter) <= cnt).array;
  case Color.Yellow:
    return words.filter!(a => a.count(letter) >= cnt).array;
  case Color.Green:
    return words.filter!(a => letter == a[position]).array;
  }
}

ulong calculateScore(ref string word, string[] wordlist, ref ulong cur_max, ref Color[5] used, int depth = 0) {
  if (depth <= 4) {
    foreach (c; EnumMembers!Color) {
      used[depth] = c;
      // Optimize for no yellows after blacks
      bool found_black = false;
      if (c == Color.Yellow) {
	for(int i = 0; i < depth; i++) {
	  if (used[i] == Color.Black && used[i] == word[depth]) {
	    found_black = true;
	  }
	}
	if (found_black) continue;
      }
      // End opt

      // Optimize for greens/yellows immediately
      auto newlist = wordlist;
      if (c == Color.Green) {
	newlist = wordlist.applyFilter(c, depth, word[depth], 0);
      }
      if (c == Color.Yellow) {
	newlist = wordlist.applyFilter(c, depth, word[depth], 1);
      }
      // End opt
      if (newlist.length > cur_max) {
	cur_max = max(cur_max, calculateScore(word, newlist, cur_max, used, depth + 1));
      }
    }
    return cur_max;
  }
    

  for (int i = 0; i < 5; i++) {
    int cnt = 0;
    for(int j = 0; j < 5; j++) {
      if (word[j] == word[i] && (used[j] == Color.Green || used[j] == Color.Yellow)) {
	cnt++;
      }
    }
    wordlist = wordlist.applyFilter(to!Color(used[i]), i, word[i], cnt);
    if (wordlist.length <= cur_max) {
      return cur_max;
    }
  }
  return wordlist.length;
}

void main() {
  auto wordlist = File("wordlist.txt").byLine.map!(to!string).array;
  auto allwords = wordlist;

  while (wordlist.length > 1) {
    // Output remaining
    writeln("Remaining: ", wordlist.length);
    if (wordlist.length < 10) {
      writeln(wordlist.sort);
    }

    // Calculate guess
    ulong minScore;
    string[] minWord;
    foreach (word; allwords) {
      ulong cur_min = 0;
      Color[5] used;
      auto score = calculateScore(word, wordlist, cur_min, used);
      if (score < minScore || minWord.length == 0) {
        minWord = [];
        minScore = score;
      }
      if (score == minScore) {
        minWord ~= word;
      }
    }
    writeln("Best guess: ", minWord.take(10), " p: ", minScore);

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    for (int i = 0; i < 5; i++) {
      int cnt = 0;
      for(int j = 0; j < 5; j++) {
	if (guess[j] == guess[i] && (colors[j] == Color.Green || colors[j] == Color.Yellow)) {
	  cnt++;
	}
      }
      wordlist = wordlist.applyFilter(to!Color(colors[i]), i, guess[i], cnt);
    }
  }
  if (wordlist.length == 1) {
    writeln("Found it: ", wordlist[0]);
  } else {
    writeln("No words remaining");
  }
}
