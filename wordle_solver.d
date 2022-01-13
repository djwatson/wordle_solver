import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.traits;

enum Color { Black, Yellow, Green }

struct filter_t {
  Color color;
  int position;
  char letter;
}

string[] applyFilters(string[] words, filter_t[] filters) {
  string[] res = words;
  foreach(f; filters) {
    final switch(f.color) {
    case Color.Black:
      res = res.filter!(a => -1 == indexOf(a, f.letter)).array;
      break;
    case Color.Yellow:
      res = res.filter!(a => -1 != indexOf(a, f.letter)).array;
      break;
    case Color.Green:
      res = res.filter!(a => f.letter == a[f.position]).array;
      break;
    }
  }
  return res;
}

void calculateP(ref string word, ref ulong[] ps, string[] wordlist, int depth) {
  foreach(c; EnumMembers!Color) {
    string[] new_words;
    
    filter_t f = {c, depth, word[depth]};
    new_words = applyFilters(wordlist, [f]);

    if (new_words.length == 0) {
      continue;
    }
    if (depth == 4) {
      ps ~= new_words.length;
    }  else {
      calculateP(word, ps, new_words, depth + 1);
    }
  }
}

float calcWordScore(string word, string[] wordlist) {
  //writeln("Calc word score: ", word);
  ulong[] wordcnts;
  calculateP(word, wordcnts, wordlist, 0);
  float tot = 0;
  foreach(wordcnt; wordcnts) {
    double p = double(wordcnt) / double(wordlist.length);
    if (p > tot) {
      tot = p;
    }
  }
  //writeln("Score: ", tot);
  return tot;
}

void main()
{
  string[] wordlist;
  foreach(line; File("wordlist.txt").byLine) {
    wordlist ~= to!string(line);
  }
  auto allwords = wordlist.dup;

  while(wordlist.length > 1) {
    // Output remaining
    writeln("Remaining: ", wordlist.length);
    if (wordlist.length < 10) {
      writeln(wordlist);
    }

    // Calculate guess
    float minScore;
    string[] minWord;
    foreach(word; allwords) {
      auto score = calcWordScore(word, wordlist);
      if (score < minScore || minWord.length == 0) {
	minWord = [];
	minWord ~= word;
	minScore = score;
      } else if (score == minScore) {
	minWord ~= word;
      }
    }
    writeln("Best guess: ", minWord, " p: ", minScore);

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    filter_t[] filters;
    for(int i = 0; i < 5; i++) {
      filter_t f;
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
  if (wordlist.length == 1) {
    writeln("Found it: ", wordlist[0]);
  } else {
    writeln("No words remaining");
  }
}
