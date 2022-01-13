import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.traits;
import std.random;

enum Color {
  Black = 'b',
  Yellow = 'y',
  Green = 'g'
}

auto applyFilter(string[] words, Color color, int position, char letter, ulong cnt) {
  final switch (color) {
  case Color.Black:
    return words.filter!(a => (a.count(letter) <= cnt) && letter != a[position]).array;
  case Color.Yellow:
    return words.filter!(a => (a.count(letter) >= cnt) && letter != a[position]).array;
  case Color.Green:
    return words.filter!(a => letter == a[position]).array;
  }
}

ulong calculateScore(ref string word, string[] wordlist, ref ulong cur_max, ref Color[5] used, int depth = 0) {
  if (depth <= 4) {
    foreach (c; EnumMembers!Color) {
      used[depth] = c;

      // Optimize for greens/yellows immediately. Blacks must wait for full count.
      // TODO: We could optimize greens separately from yellows.
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
    

  foreach (i; 0 .. 5) {
    auto cnt = iota(5).count!(j => (word[j] == word[i] && (used[j] == Color.Green || used[j] == Color.Yellow)));
    wordlist = wordlist.applyFilter(to!Color(used[i]), i, word[i], cnt);
    if (wordlist.length <= cur_max) {
      return cur_max;
    }
  }
  return wordlist.length;
}

char[5] apply_guess(string guess, string word){
  char[5] res;
  foreach(i; 0..5) {
    if (guess[i] == word[i]) {
      res[i] = 'g';
      
    } else {
      int yellowcnt = 0;
      foreach(j; 0..i) {
	if (res[j] == 'y' && guess[j] == guess[i]) {
	  yellowcnt++;
	}
      }
      //writeln("CHecking pos ", i, " letter ", guess[i], " cnt ", word.count(guess[i]), " yell ", yellowcnt);
      int totyel = 0;
      foreach(j; 0..5) {
	if (word[j] == guess[i] && word[j] != guess[j]) {
	  totyel++;
	}
      }
      if (totyel > yellowcnt) {
	res[i] = 'y';
      } else {
	res[i] = 'b';
      }
    }
  }
  
  return res;
}

void main() {
  auto wordlist = File("wordlist.txt").byLine.map!(to!string).array;
  auto allwords = wordlist;

  if (0) {
  foreach(word; allwords) {
    wordlist = allwords;

    string guess = "raise";
    int iters = 0;
    //writeln("Current word: ", word);
    while(true) {
      iters++;
      auto colors = apply_guess(guess, word);
      foreach (i; 0..5) {
	auto cnt = iota(5).count!(j => (guess[j] == guess[i] && (colors[j] == Color.Green || colors[j] == Color.Yellow)));
	wordlist = wordlist.applyFilter(to!Color(colors[i]), i, guess[i], cnt);
      }
      //writeln("  guess ", iters, ": ", guess, " colors: ", colors, " size: ", wordlist.length);

      assert(wordlist.length != 0);
      if (wordlist.length <= 1) {
	break;
      }
      
      ulong minScore;
      string[] minWord;
      foreach (curword; allwords) {
	ulong cur_min = 0;
	Color[5] used;
	auto score = calculateScore(curword, wordlist, cur_min, used);
	if (score < minScore || minWord.length == 0) {
	  minWord = [];
	  minScore = score;
	}
	if (score == minScore) {
	  minWord ~= curword;
	}
      }
      //writeln("GUesses: ", minWord);
      guess = minWord[0];
    }
    writeln(word, " took iters ", iters);
  }
  }

  while (wordlist.length > 1) {
    // Output remaining
    writeln("Remaining: ", wordlist.length);
    if (wordlist.length < 10) {
      writeln(wordlist.sort);
    }

    // Calculate guess
    ulong minScore;
    string[] minWord;
    foreach (word; wordlist) {
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
    writeln("Best guess: ", minWord.randomShuffle().take(10), " p: ", minScore);

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    foreach (i; 0..5) {
      auto cnt = iota(5).count!(j => (guess[j] == guess[i] && (colors[j] == Color.Green || colors[j] == Color.Yellow)));
      wordlist = wordlist.applyFilter(to!Color(colors[i]), i, guess[i], cnt);
    }
  }
  if (wordlist.length == 1) {
    writeln("Found it: ", wordlist[0]);
  } else {
    writeln("No words remaining");
  }
}
