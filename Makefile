GV= dot
out/classes.dot: src/umler.lua src/classes.lua src/style.css
	cp src/style.css out/style.css
	lua src/umler.lua src/classes.lua | tee out/classes.dot
out/classes.svg: out/classes.dot
	$(GV) -Tsvg out/classes.dot -o out/classes.svg
out/classes.png: out/classes.svg
	convert -resize 2048 out/classes.svg out/classes.png
out/doc.pdf: src/doc.md src/img/packages.png src/img/help.png out/classes.png
	pandoc --standalone --from=markdown --to=latex src/doc.md -o out/doc.pdf
out/packed.pdf: out/doc.pdf out/classes.svg
	src/gen_poly.py --header /dev/null --message /dev/null --out out/packed.pdf --in out/doc.pdf --zip src out/classes.svg Makefile THANKS watch.sh
clean:
	rm -vf out/*
