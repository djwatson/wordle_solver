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

struct wordlist_t {
  char[5][] words;
  ubyte[26][] letter_counts;
  ulong filter_cnt;

  ushort[][] filters;
  ushort[] filter_lengths;

  this(string[] wordlist) {
    ushort[] new_filter;
    foreach(word; wordlist) {
      char[5] newword;
      filter_lengths ~= 0;
      newword = word;
      words ~= newword;
      new_filter ~= filter_lengths[0]++;
      ubyte[26] new_counts;
      foreach(letter; 0 .. 26) {
	new_counts[letter] = cast(ubyte)word.count(letter + 'a');
      }
      letter_counts ~= new_counts;
    }
    filters ~= new_filter;
  }

  string[] get_wordlist() {
    string[] res;
    foreach(wordpos; filters[filter_cnt]) {
      res ~= to!string(words[wordpos]);
    }
    return res;
  }

  void popFilter() {
    assert(filter_cnt > 0);
    --filter_cnt;
  }

  ulong length() {
    return filter_lengths[filter_cnt];
  }

  void applyFilter(Color color, int position, char letter, ulong cnt) {
    auto last_filter = filter_cnt;
    auto filter = ++filter_cnt;
    if (filters.length <= filter_cnt) {
      ushort[] new_filter;
      new_filter.length = words.length;
      filters ~= new_filter;
      filter_lengths ~= 0;
    }
    filter_lengths[filter] = 0;
    final switch (color) {
    case Color.Black:
      foreach(i; 0 .. filter_lengths[last_filter]) {
	auto wordpos = filters[last_filter][i];
	char[5] word = words[wordpos];
	if (letter != word[position]) {
	  if (letter_counts[wordpos][letter - 'a'] <= cnt) {
	    filters[filter][filter_lengths[filter]++] = wordpos;
	  }
	}
      }
      break;
      //return words.filter!(a => (a.count(letter) <= cnt) && letter != a[position]).array;
    case Color.Yellow:
      foreach(i; 0 .. filter_lengths[last_filter]) {
	auto wordpos = filters[last_filter][i];
	char[5] word = words[wordpos];
	if (letter != word[position]) {
	  if (letter_counts[wordpos][letter - 'a'] >= cnt) {
	    filters[filter][filter_lengths[filter]++] = wordpos;
	  }
	}
      }
      break;
      //return words.filter!(a => (a.count(letter) >= cnt) && letter != a[position]).array;
    case Color.Green:
      foreach(i; 0 .. filter_lengths[last_filter]) {
	auto wordpos = filters[last_filter][i];
	char[5] word = words[wordpos];
	if (letter == word[position]) {
	  filters[filter][filter_lengths[filter]++] = wordpos;
	}
      }
      break;
      //return words.filter!(a => letter == a[position]).array;
    }
  }
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
ulong cur_depth;
bool calculateScore(ref string word, ref ulong cur_max,
		    ref Color[5] used, int depth = 0, ulong beta = ulong.max) {

  // Permutations, with an optimization for greens and yellows that
  // can be applied immediately.
  if (depth <= 4) {
    foreach (c; EnumMembers!Color) {
      used[depth] = c;

      // Optimize for greens/yellows immediately. Blacks must wait for full count.
      if (c == Color.Green) {
        cur_list.applyFilter(c, depth, word[depth], 0);
      }
      if (c == Color.Yellow) {
        cur_list.applyFilter(c, depth, word[depth], 1);
      }
      // End opt
      auto fast_out = calculateScore(word, cur_max, used, depth + 1, beta);
      if (c == Color.Green || c == Color.Yellow) {
	cur_list.popFilter();
      }
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
    cur_list.applyFilter(to!Color(used[i]), i, word[i], cnt);
  }
  if (cur_depth > 0) {
    cur_depth--;
    auto list = hard_mode ? cur_list.get_wordlist() : allwords;
    ulong cur_min = ulong.max;
    
    foreach(word2; list) {
      auto guess = make_guess(word2, cur_min);
      if (guess.score <= cur_max) {
	cur_min = cur_max;
	break;
      }
      if (guess.score < cur_min ) {
	cur_min = guess.score;
      }
    }
    if (cur_min != ulong.max) {
      cur_max = max(cur_max, cur_min);
    }
    cur_depth++;
  } else {
    cur_max = max(cur_max, cur_list.length);
  }
  foreach(i; 0..5) {
    cur_list.popFilter();
  }

  if (cur_max > beta) {
    return true;
  }
  return false;
}

// For the tester: Return colors based on a word and guess.
// char[5] apply_guess(string guess, string word) {
//   char[5] res;
//   foreach (i; 0 .. 5) {
//     if (guess[i] == word[i]) {
//       res[i] = Color.Green;
//     } else {
//       auto yellowcnt = iota(i).count!(j => res[j] == 'y' && guess[j] == guess[i]);
//       auto totyel = iota(5).count!(j => word[j] == guess[i] && word[j] != guess[j]);
//       if (totyel > yellowcnt) {
//         res[i] = Color.Yellow;
//       } else {
//         res[i] = Color.Black;
//       }
//     }
//   }

//   return res;
// }

bool hard_mode = false;

struct guess_result {
  string[] word;
  ulong score;
}

guess_result make_guess(string word, ulong beta) {
  ulong cur_max = 0;
  Color[5] used;
  calculateScore(word, cur_max, used, 0, beta);
  return guess_result([word], cur_max);
}

wordlist_t cur_list;

ulong total_test = 0;
guess_result guess_reducer(guess_result a, guess_result b) {
  assert(b.word.length == 1);
  writeln("Testing ", b.word[0], " ", total_test++);
  b.score = make_guess(b.word[0], a.score).score;
  if (a.score < b.score) {
    return a;
  } else if (b.score < a.score) {
    //if (cur_depth == 1) {
    writeln("New best guess: ", b);
      //}
    return b;
  } else {
    //if (cur_depth == 1) {
    //writeln("New best guess: ", b);
    
      //}
      a.word ~= b.word;
    writeln("New best guess: ", a);
    return a;
  }
}

// Return optimal guesses based on the remaining wordlist
string[] make_guesses(string[] allwords, string[] wordlist) {
  cur_depth = 0;
  auto list = hard_mode ? wordlist : allwords;
  cur_list = wordlist_t(wordlist);
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
string[] allwords;
// void run_test(string[] wordlist, string[] wordlist2) {
//   auto allwords = wordlist2;
//   auto all_solutions = wordlist;

//   foreach (word; all_solutions) {
//     wordlist = all_solutions;

//     string guess = "raise";
//     int iters = 0;
//     //writeln("Current word: ", word);
//     while (true) {
//       iters++;
//       auto colors = apply_guess(guess, word);
//       wordlist = apply_colors(guess, to!string(colors), wordlist);
//       //writeln("  guess ", iters, ": ", guess, " colors: ", colors, " size: ", wordlist.length);

//       assert(wordlist.length != 0);
//       if (wordlist.length <= 1) {
//         break;
//       }

//       //writeln("GUesses: ", minWord);
//       guess = make_guesses(allwords, wordlist)[0];
//     }
//     writeln(word, " took iters ", iters);
//   }
// }

// Just a command-line UI to the solver.
void run_solver(string[] wordlist, string[] wordlist2) {
  allwords = wordlist2;

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
    //run_test(wordlist, wordlist2);
  } else {
    run_solver(wordlist, wordlist2);
  }

}
