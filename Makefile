all: build/us.json

clean:
	rm -rf build

.PHONY: all clean

build/cities.json: data/cities-population.csv data/cities-latlong.csv
	scripts/merge-pop-loc 'data/cities-population.csv' 'data/cities-latlong.csv'
	
