import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.traits;
import std.random;
import std.getopt;

enum Color {
  Black = 'b',
  Yellow = 'y',
  Green = 'g'
}

// Apply a filter based on color to the wordlist, returning a new wordlist.
// Black and Yellow filters must take in to account the number of letters already used
// for that particular type, since this indicates how many of each letter there are
// if there are multiples.
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

// Return the largest partition that can be made based on this word guess.
// The largest partition represents the worst-case number of words left to filter.
bool calculateScore(ref string word, string[] wordlist, ref ulong cur_max,
		    ref Color[5] used, int depth = 0, ulong beta = ulong.max) {

  // Permutations, with an optimization for greens and yellows that
  // can be applied immediately.
  if (depth <= 4) {
    foreach (c; EnumMembers!Color) {
      used[depth] = c;

      // Optimize for greens/yellows immediately. Blacks must wait for full count.
      auto newlist = wordlist;
      if (c == Color.Green) {
        newlist = wordlist.applyFilter(c, depth, word[depth], 0);
      }
      if (c == Color.Yellow) {
        newlist = wordlist.applyFilter(c, depth, word[depth], 1);
      }
      // End opt
      auto fast_out = calculateScore(word, newlist, cur_max, used, depth + 1, beta);
      if (fast_out) {
	return fast_out;
      }
    }
    if (cur_max > beta) {
      return true;
    }
    return false;
  }

  // Perumtation fully calculated: Now filter the wordlist.
  // We can end early if we're smaller than the current max list.
  foreach (i; 0 .. 5) {
    auto cnt = iota(5).count!(j => (word[j] == word[i] && (used[j] == Color.Green
        || used[j] == Color.Yellow)));
    wordlist = wordlist.applyFilter(to!Color(used[i]), i, word[i], cnt);
  }
  cur_max = max(cur_max, wordlist.length);
  if (cur_max > beta) {
    return true;
  }
  return false;
}

// For the tester: Return colors based on a word and guess.
char[5] apply_guess(string guess, string word) {
  char[5] res;
  foreach (i; 0 .. 5) {
    if (guess[i] == word[i]) {
      res[i] = 'g';
    } else {
      auto yellowcnt = iota(i).count!(j => res[j] == 'y' && guess[j] == guess[i]);
      auto totyel = iota(5).count!(j => word[j] == guess[i] && word[j] != guess[j]);
      if (totyel > yellowcnt) {
        res[i] = 'y';
      } else {
        res[i] = 'b';
      }
    }
  }

  return res;
}

bool hard_mode = false;

struct guess_result {
  string[] word;
  ulong score;
}

guess_result make_guess(string word, string[] wordlist, ulong beta = ulong.max) {
  ulong cur_max = 0;
  Color[5] used;
  calculateScore(word, wordlist, cur_max, used, 0, beta);
  return guess_result([word], cur_max);
}

string[] cur_list;
guess_result guess_reducer(guess_result a, guess_result b) {
  assert(b.word.length == 1);
  b.score = make_guess(b.word[0], cur_list, a.score).score;
  if (a.score < b.score) {
    return a;
  } else if (b.score < a.score) {
    return b;
  } else {
    a.word ~= b.word;
    return a;
  }
}

// Return optimal guesses based on the remaining wordlist
string[] make_guesses(string[] allwords, string[] wordlist) {
  auto list = hard_mode ? wordlist : allwords;
  cur_list = wordlist;
  guess_result seed;
  seed.score = ulong.max;
  auto results = list.map!(a => guess_result([a], 0)).fold!guess_reducer(seed);
  return results.word;
}

// Apply the given colors to the wordlist via filtering, returns new smaller wordlist.
string[] apply_colors(string guess, string colors, string[] wordlist) {
  foreach (i; 0 .. 5) {
    auto cnt = iota(5).count!(j => (guess[j] == guess[i]
        && (colors[j] == Color.Green || colors[j] == Color.Yellow)));
    wordlist = wordlist.applyFilter(to!Color(colors[i]), i, guess[i], cnt);
  }
  return wordlist;
}

bool test_runner = false;

// Run the solver on each dictionary word.
void run_test(string[] wordlist, string[] wordlist2) {
  auto allwords = wordlist2;
  auto all_solutions = wordlist;

  foreach (word; all_solutions) {
    wordlist = all_solutions;

    string guess = "raise";
    int iters = 0;
    //writeln("Current word: ", word);
    while (true) {
      iters++;
      auto colors = apply_guess(guess, word);
      wordlist = apply_colors(guess, to!string(colors), wordlist);
      //writeln("  guess ", iters, ": ", guess, " colors: ", colors, " size: ", wordlist.length);

      assert(wordlist.length != 0);
      if (wordlist.length <= 1) {
        break;
      }

      //writeln("GUesses: ", minWord);
      guess = make_guesses(allwords, wordlist)[0];
    }
    writeln(word, " took iters ", iters);
  }
}

// Just a command-line UI to the solver.
void run_solver(string[] wordlist, string[] wordlist2) {
  auto allwords = wordlist2;

  while (wordlist.length > 1) {
    // Output remaining
    writeln("Remaining: ", wordlist.length);
    if (wordlist.length < 10) {
      writeln(wordlist.sort);
    }

    // Calculate guess
    string[] minWord = make_guesses(allwords, wordlist);
    writeln("Best guesses: ", minWord.randomShuffle().take(10));

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    wordlist = apply_colors(guess, colors, wordlist);
  }
  if (wordlist.length == 1) {
    writeln("Found it: ", wordlist[0]);
  } else {
    writeln("No words remaining");
  }
}

void main(string[] args) {
  auto help = getopt(args, "hard", "Hard mode, must use hint information",
      &hard_mode, "tester", "Run the solver on all words", &test_runner);
  if (help.helpWanted) {
    defaultGetoptPrinter("Some information about the program.", help.options);
    return;
  }

  auto wordlist = File("wordlist.txt").byLine.map!(to!string).array;
  auto wordlist2 = File("wordlist3_out.txt").byLine.map!(to!string).array;

  if (test_runner) {
    run_test(wordlist, wordlist2);
  } else {
    run_solver(wordlist, wordlist2);
  }

}
