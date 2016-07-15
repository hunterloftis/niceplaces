all: data/us.json

clean:
	rm -rf data/build/*
	mkdir -p data/build

.PHONY: all clean

data/us.json: data/build/cities.json
	cp data/build/cities.json $@

data/build/cities.json: data/build/cities-population.csv data/build/cities-latlong.csv
	bin/merge-pop-loc 'data/build/cities-population.csv' 'data/build/cities-latlong.csv' > $@

data/build/cities-population.csv:
	curl -o $@ 'http://www.census.gov/popest/data/cities/totals/2015/files/SUB-EST2015_ALL.csv'

data/build/cities-latlong.zip:
	curl -o $@ 'http://www.opengeocode.org/download/statecity.zip'

data/build/cities-latlong.csv: data/build/cities-latlong.zip
	unzip -od $(dir $@) $<
	mv "$(dir $@)/statecity.csv" $@
	touch $@
