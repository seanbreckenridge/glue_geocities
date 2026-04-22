OUTFILE=./assets/bundle.css

dist: build
	@echo "Copying files..."
	mkdir -p ./dist/assets/images
	cp ./index.html ./dist/index.html
	cp ./assets/stars.js ./dist/assets/stars.js
	cp ./elm/elm_port.js ./dist/assets/elm_port.js
	cp ./assets/bundle.css ./dist/assets/bundle.css
	cp ./assets/images/* ./dist/assets/images/
	@echo "Done, check ./dist"

font: ./dist/assets/vt323.woff
./dist/assets/vt323.woff: vt323.woff
	mkdir -p ./dist/assets
	cp ./vt323.woff ./dist/assets/vt323.woff

vt323.woff:
	wget https://fonts.gstatic.com/s/vt323/v18/pxiKyp0ihIEF2isfFJU.woff2 -O vt323.woff

build: $(OUTFILE) ./assets/stars.js font

./assets/stars.js: elm/src/Stars.elm
	@echo "Compiling Elm..."
	cd ./elm; elm make src/Stars.elm --optimize --output=./../assets/stars.js

$(OUTFILE): $(wildcard ./assets/css/*.css)
	# blazingly fast CSS bundler
	@echo "Bundling CSS..."
	cat ./assets/css/skeleton.css \
    ./assets/css/normalize.css \
    ./assets/css/star_keyframes.css \
    ./assets/css/dos_buttons.css \
    ./assets/css/index.css > $(OUTFILE)

clean:
	rm -rf dist
	rm -f ./assets/stars.js
	rm -f ./assets/bundle.css
