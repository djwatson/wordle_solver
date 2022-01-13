import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.traits;

enum Color { Black, Yellow, Green }

struct filter {
  Color color;
  int position;
  char letter;
}

bool[string] applyFilters(bool[string] words, filter[] filters) {
  bool[string] res = words.dup;
  foreach(f; filters) {
    final switch(f.color) {
    case Color.Black:
      foreach(word; res.keys) {
	if (-1 != indexOf(word, f.letter)) {
	  res.remove(word);
	}
      }
      break;
    case Color.Yellow:
      foreach(word; res.keys) {
	if (-1 == indexOf(word, f.letter)) {
	  res.remove(word);
	}
      }
      break;
    case Color.Green:
      foreach(word; res.keys) {
	if (word[f.position] != f.letter) {
	  res.remove(word);
	}
      }
      break;
    }
  }
  return res;
}

void calculateP(ref string word, ref float[] ps, bool[string] wordlist, float p, int depth) {
  foreach(c; EnumMembers!Color) {
    bool[string] new_words;
    
    filter f;
    f.position = depth;
    f.color = c;
    f.letter = word[depth];
    new_words = applyFilters(wordlist, [f]);

    float new_p = p * (float(new_words.length) / float(wordlist.length)) ;
    if (depth == 4) {
      ps ~= new_p;
    }  else {
      calculateP(word, ps, new_words, new_p, depth + 1);
    }
  }
}

float calcWordScore(string word, bool[string] wordlist) {
  float[] pValues;
  calculateP(word, pValues, wordlist, 1, 0);
  float tot = 0;
  foreach(p; pValues) {
    tot += p*p;
  }
  return tot;
}

void main()
{
  bool[string] wordlist;
  foreach(line; File("wordlist.txt").byLine) {
    wordlist[to!string(line)] = true;
  }
  auto allwords = wordlist;

  while(wordlist.length) {
    // Output remaining
    writeln("Remaining: ", wordlist.length);
    if (wordlist.length < 10) {
      writeln(wordlist.byKey);
    }

    // Calculate guess
    float minScore = 1;
    string minWord;
    foreach(word; allwords.byKey) {
      auto score = calcWordScore(word, wordlist);
      if (score < minScore) {
	minWord = word;
	minScore = score;
      }
    }
    if (minScore < 1) {
      writeln("Best guess: ", minWord, " p: ", minScore);
    }

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    filter[] filters;
    for(int i = 0; i < 5; i++) {
      filter f;
      f.position = i;
      final switch(colors[i]) {
      case 'b':
	f.color = Color.Black;
	break;
      case 'g':
	f.color = Color.Green;
	break;
      case 'y':
	f.color = Color.Yellow;
	break;
      }
      f.letter = guess[i];
      filters ~= f;
    }
    wordlist = applyFilters(wordlist, filters);
  }
  writeln("No words remaining");
}
