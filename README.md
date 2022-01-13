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

