# Wordle Sover in D

[Wordle](https://www.powerlanguage.co.uk/wordle/) is a fun little
mastermind like game.

Tom Neil wrote up a great [Wordle
Solver](https://notfunatparties.substack.com/p/wordle-solver), so I
just had to have a go at it. Has options to test against the whole
dictionary `--tester`, hard mode `--hard`.  Runs in the console.

Uses a alpha-beta (currently only depth 2, our guess and their
pessimistic response), which greatly helps in pruning the state
space.  We can also optimistically prune some branches we know aren't
the adverserial response (see various optimizations in
calculateScore).  Currently, using wordle's 2k answer and 12k guess
word lists, calculating the best guess on my machine takes ~3 seconds,
single-threaded.  The utility function is just the maximum adverserial
set size, *not* the average set size.

If you're just looking for the best guess, it is one of:

* arise

* reais

* raise

* aesir

* serai

Unlike Tom's, this takes in to account multiple letters.  This seems
to solve a bit faster in some cases. For example, if the solution is
'geeky':

```
Remaining: 2315
Best guesses: ["arise", "reais", "aesir", "raise", "serai"]
Input a guess: 
raise
Input colors:
bbbby
Remaining: 121
Best guesses: ["denet"]
Input a guess: 
denet
Input colors:
bgbyb
Remaining: 4
["beech", "beefy", "geeky", "leech"]
Best guesses: ["blash", "busky", "loggy", "pubic", "tubby", "kahal", "bully", "heben", "kylin", "oflag"]
Input a guess: 
blash
Input colors:
bbbbb
Found it: geeky
```

And in Tom's:
```
RAISE
121 words left
OLDEN
12 words left
DEPTH
2 words left
BEEFY
1 word left
geeky

```

Although overall these doesn't seem to matter much and the code would
be simpler.  

# alpha-beta min-max

Hacky alpha-beta solver results in:

Best guesses at level 2:
tolar aloes

hard mode:
stole

depth 20 hard mode: laden (trump), focal, model
At level 3, almost any reasonable combination of 3 guesses results in
worst-case of 3 words or less.  

laden, riots, gimpy, chuck
rebut, flick, mason
