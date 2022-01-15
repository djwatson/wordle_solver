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

class wordlist_t {
  char[5][] words;
  ubyte[26][] letter_counts;
  ulong filter_cnt;

  ushort[][] filters;
  ushort[] filter_lengths;

  this(string[] wordlist) {
    filters ~= iota(wordlist.length).map!(a => cast(ushort)a).array;
    filter_lengths ~= cast(ushort)wordlist.length;
    foreach (word; wordlist) {
      char[5] newword = word;
      words ~= newword;
      letter_counts ~= iota(26).map!(letter => cast(ubyte)word.count(letter + 'a')).staticArray!26;
    }
  }

  void popFilter() {
    assert(filter_cnt > 0);
    --filter_cnt;
  }

  struct iter {
    wordlist_t wordlist;
    ulong filter_cnt;
    ulong pos;
    string front() { return to!string(wordlist.words[wordlist.filters[filter_cnt][pos]]);}
    bool empty() { return pos >= wordlist.filter_lengths[filter_cnt] ;}
    void popFront() { pos++;}
  }

  iter opSlice() {
    return iter(this, this.filter_cnt, 0);
  }

  ulong length() {
    return filter_lengths[filter_cnt];
  }

  // Apply a filter based on color to the wordlist, returning a new wordlist.
  // Black and Yellow filters must take in to account the number of letters already used
  // for that particular type, since this indicates how many of each letter there are
  // if there are multiples.
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
      foreach (i; 0 .. filter_lengths[last_filter]) {
        auto wordpos = filters[last_filter][i];
	if (letter_counts[wordpos][letter - 'a'] <= cnt) {
	  filters[filter][filter_lengths[filter]++] = wordpos;
	}
      }
      break;
      //return words.filter!(a => (a.count(letter) <= cnt) && letter != a[position]).array;
    case Color.Yellow:
      foreach (i; 0 .. filter_lengths[last_filter]) {
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
      foreach (i; 0 .. filter_lengths[last_filter]) {
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

// Return the largest partition that can be made based on this word guess.
// The largest partition represents the worst-case number of words left to filter.
bool calculateScore(string[] allwords, wordlist_t cur_list, ref string word, ref Color[5] used, int depth, ref ulong alpha, 
		    ulong beta, ulong ab_depth) {
  // Permutations, with an optimization for greens and yellows that
  // can be applied immediately.
  if (depth <= 4) {
    foreach (c; EnumMembers!Color) {
      used[depth] = c;

      // Optimize for greens/yellows immediately. Blacks must wait for full count.
      if (c == Color.Green || c == Color.Yellow) {
        cur_list.applyFilter(c, depth, word[depth], 1);
      }
      // End opt
      auto fast_out = calculateScore(allwords, cur_list, word, used, depth + 1, alpha, beta, ab_depth);
      if (c == Color.Green || c == Color.Yellow) {
        cur_list.popFilter();
      }
      if (fast_out) {
        return fast_out;
      }
    }
    return false;
  }

  // Perumtation fully calculated: Now filter the wordlist.
  // We can end early if we're smaller than the current max list.
  auto filters_applied = apply_colors!false(word, used, cur_list);
  ulong score;
  if (ab_depth > 0) {
    score = make_guesses!false(allwords, cur_list, alpha, beta, ab_depth-1).score;
  } else {
    score = cur_list.length;
  }
  if (score >= beta) {
    alpha = beta;
    foreach (i; 0 .. filters_applied) {
      cur_list.popFilter();
    }
    return true;
  }
  if (score > alpha) {
    alpha = score;
  }

  foreach (i; 0 .. filters_applied) {
    cur_list.popFilter();
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

// Return optimal guesses based on the remaining wordlist
struct guess_result {
  string word;
  ulong score = 0;
}


guess_result make_guesses(bool need_results)(string[] allwords, wordlist_t wordlist, ulong alpha, ulong beta, ulong ab_depth) {
  guess_result result;
  if (wordlist.length == 0) {
    return result;
  }
  bool test_result(string word) {
    if (alpha_beta_depth) {
      static ulong total_test = 0;
      static if (need_results) {
	writeln("Testing ", word, " ", total_test++);
      }
    }
    ulong score = alpha;
    Color[5] used;
    calculateScore(allwords, wordlist, word, used, 0, score, beta, ab_depth);
    if (score <= alpha) {
      result.score = alpha;
      return true;
    }
    if (score <= beta) {
      if (score < beta) {
	beta = score;
	static if (need_results) {
	  result.word = word;
	}
      }
      static if (need_results) {
	if (alpha_beta_depth) {
	  writeln("New best guess: ", beta, " ", result.word);
	}
      }
    }
    return false;
  }
  if (hard_mode) {
    foreach(word; wordlist) {
      if (test_result(word)) {
	return result;
      }
    }
  } else {
    foreach(word; allwords) {
      if (test_result(word)) {
	return result;
      }
    }
  }
  result.score = beta;
  return result;
}

// Apply the given colors to the wordlist via filtering, returns new smaller wordlist.
ulong apply_colors(bool dogreen = true)(string guess, Color[5] colors, wordlist_t wordlist) {
  ulong applied;
  foreach (i; 0 .. 5) {
    auto cnt = iota(5).count!(j => (guess[j] == guess[i]
        && (colors[j] == Color.Green || colors[j] == Color.Yellow)));
    if (!dogreen || colors[i] != Color.Green) {
      wordlist.applyFilter(to!Color(colors[i]), i, guess[i], cnt);
      applied++;
    }
  }
  return applied;
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
ulong alpha_beta_depth = 0;
void run_solver(string[] wordlist, string[] wordlist2) {
  allwords = wordlist2;
  wordlist_t wl = new wordlist_t(wordlist);

  while (wl.length > 1) {
    // Output remaining
    writeln("Remaining: ", wl.length);
    if (wl.length < 10) {
      writeln(wl[]);
    }

    // Calculate guess
    auto minword = make_guesses!true(allwords, wl, ulong.min, ulong.max, alpha_beta_depth).word;
    writeln("Best guesses: ", minword);

    // User input
    writeln("Input a guess: ");
    auto guess = readln();
    writeln("Input colors:");
    auto colors = readln();
    apply_colors(guess, colors.map!(a => to!Color(a)).staticArray!5, wl);
  }
  if (wl.length == 1) {
    writeln("Found it: ", wl[].front);
  } else {
    writeln("No words remaining");
  }
}

void main(string[] args) {
  auto help = getopt(args, "hard", "Hard mode, must use hint information", &hard_mode, "tester",
      "Run the solver on all words", &test_runner, "depth",
      "Alpha-beta depth", &alpha_beta_depth);
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
