wordle_solver: wordle_solver.d
	ldc2 -g -O5 --frame-pointer=all -release wordle_solver.d
