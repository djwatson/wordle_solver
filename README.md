# Wordle Sover in D

[Wordle](https://www.powerlanguage.co.uk/wordle/) is a fun little
mastermind like game.

Tom Neil wrote up a great [Wordle
Solver](https://notfunatparties.substack.com/p/wordle-solver), so I
just had to have a go at it. Has options to test against the whole
dictionary `--tester`, hard mode `--hard`.  Runs in the console.

Unlike Tom's, this takes in to account multiple letters.  This seems
to solve a bit faster in some cases. For example, if the solution is
'geeky':

```
Remaining: 2315
Best guesses: ["arise", "raise"]
Input a guess: 
raise
Input colors:
bbbby
Remaining: 121
Best guesses: ["towel"]
Input a guess: 
towel
Input colors:
bbbyb
Remaining: 10
Best guesses: ["bench", "hedge", "fence"]
Input a guess: 
bench
Input colors:
bgbbb
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
be simpler.  Also, try 'Agree', which is solved in 2 guesses, while
Tom's takes 3.
