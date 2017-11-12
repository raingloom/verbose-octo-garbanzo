out/classes.dot: src/umler.lua src/classes.lua
	lua src/umler.lua src/classes.lua | tee out/classes.dot
out/classes.svg: out/classes.dot
	dot -Tsvg out/classes.dot -o out/classes.svg
clean:
	rm -vf out/*
