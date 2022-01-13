import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.traits;

enum Color { Black = 'b', Yellow = 'y', Green = 'g' }

auto applyFilter(string[] words, Color color, int position, char letter) {
  final switch(color) {
  case Color.Black:
    return words.filter!(a => -1 == indexOf(a, letter)).array;
  case Color.Yellow:
    return words.filter!(a => -1 != indexOf(a, letter)).array;
  case Color.Green:
    return words.filter!(a => letter == a[position]).array;
  }
}

ulong calculateScore(ref string word, string[] wordlist, int depth = 0) {
  ulong res = 0;
  string[] new_words;
  static foreach(c; EnumMembers!Color) {
    new_words = wordlist.applyFilter(c, depth, word[depth]);

    if (new_words.length != 0) {
      if (depth == 4) {
	res = max(res, new_words.length);
      }  else {
	res = max(res, calculateScore(word, new_words, depth + 1));
      }
    }
  }
  return res;
}

void main()
{
  auto wordlist = File("wordlist.txt").byLine.map!(to!string).array;
  auto allwords = wordlist;

  while(wordlist.length > 1) {
    // Output remaining
    writeln("Remaining: ", wordlist.length);
    if (wordlist.length < 10) {
      writeln(wordlist);
    }

    // Calculate guess
    ulong minScore;
    string[] minWord;
    foreach(word; allwords) {
      auto score = calculateScore(word, wordlist);
      if (score < minScore || minWord.length == 0) {
	minWord = [];
	minScore = score;
      }
      if (score == minScore) {
	minWord ~= word;
      }
    }
    writeln("Best guess: ", minWord, " p: ", minScore);

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    for(int i = 0; i < 5; i++) {
      wordlist = wordlist.applyFilter(to!Color(colors[i]), i, guess[i]);
    }
  }
  if (wordlist.length == 1) {
    writeln("Found it: ", wordlist[0]);
  } else {
    writeln("No words remaining");
  }
}
