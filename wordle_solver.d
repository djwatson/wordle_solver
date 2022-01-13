import std.stdio;
import std.algorithm;
import std.range;
import std.conv;

void main()
{
  bool[string] wordlist;
  foreach(line; File("wordlist.txt").byLine) {
    wordlist[to!string(line)] = true;
  }

    writeln(wordlist);
}
