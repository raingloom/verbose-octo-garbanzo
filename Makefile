GV= dot
out/classes.dot: src/umler.lua src/classes.lua src/style.css
	lua src/umler.lua src/classes.lua | tee out/classes.dot
out/classes.svg: out/classes.dot
	$(GV) -Tsvg out/classes.dot -o out/classes.svg
out/doc.pdf: src/doc.md
	pandoc --from=markdown --to=latex src/doc.md -o out/doc.pdf
out/packed.pdf: out/doc.pdf out/classes.svg
	src/gen_poly.py --header /dev/null --message /dev/null --out out/packed.pdf --in out/doc.pdf --zip *
clean:
	rm -vf out/*
