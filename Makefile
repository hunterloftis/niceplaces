all: data/us.json data/cities.csv

clean:
	rm -rf data/build/*
	mkdir -p data/build

.PHONY: all clean

data/us.json: data/build/states.json
	node_modules/.bin/topojson-merge \
		-o $@ \
		--in-object=states \
		--out-object=nation \
		-- $<

data/cities.csv: data/build/cities-merged.csv
	cp data/build/cities-merged.csv $@

data/build/stations.txt:
	curl -o $@ 'ftp://ftp.ncdc.noaa.gov/pub/data/noaa/isd-history.txt'

data/build/gsod_2015.tar:
	curl -o $@ 'ftp://ftp.ncdc.noaa.gov/pub/data/gsod/2015/gsod_2015.tar'

data/build/gsod_2015: data/build/gsod_2015.tar
	mkdir -p data/build/gsod_2015
	tar -C data/build/gsod_2015 -xvf data/build/gsod_2015.tar
	gunzip -rf data/build/gsod_2015
	find data/build/gsod_2015 -name "*.op" -size -45k -delete

data/build/cities-pop-loc-stat.csv: data/build/stations.csv data/build/cities-pop-loc.csv
	bin/match-stations 'data/build/cities-pop-loc.csv' 'data/build/stations.csv' > data/build/cities-pop-loc-stat.csv

data/build/stations.csv: data/build/stations.txt data/build/gsod_2015
	bin/filter-stations data/build/stations.txt data/build/gsod_2015 > $@

data/build/cities-pop-loc.csv: data/build/cities-population.csv data/build/cities-latlong.csv
	bin/merge-pop-loc 'data/build/cities-population.csv' 'data/build/cities-latlong.csv' > $@

data/build/cities-population.csv:
	curl -o $@ 'http://www.census.gov/popest/data/cities/totals/2015/files/SUB-EST2015_ALL.csv'

data/build/cities-latlong.zip:
	curl -o $@ 'http://www.opengeocode.org/download/statecity.zip'

data/build/cities-latlong.csv: data/build/cities-latlong.zip
	unzip -od $(dir $@) $<
	mv "$(dir $@)/statecity.csv" $@
	touch $@

data/build/gz_2010_us_050_00_20m.zip:
	mkdir -p $(dir $@)
	curl -o $@ 'http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_us_050_00_20m.zip'

data/build/gz_2010_us_050_00_20m.shp: data/build/gz_2010_us_050_00_20m.zip
	unzip -od $(dir $@) $<
	touch $@

data/build/counties.json: data/build/gz_2010_us_050_00_20m.shp data/manual/ACS_12_5YR_B01003_with_ann.csv
	node_modules/.bin/topojson \
		-o $@ \
		--id-property='STATE+COUNTY,Id2' \
		--external-properties='data/manual/ACS_12_5YR_B01003_with_ann.csv' \
		--properties='name=Geography,population=+d.properties["Estimate; Total"]' \
		--projection='width = 960, height = 600, d3.geo.albersUsa() \
			.scale(1280) \
			.translate([width / 2, height / 2])' \
		--simplify=.5 \
		--filter=none \
		-- counties=$<

data/build/states.json: data/build/counties.json
	node_modules/.bin/topojson-merge \
		-o $@ \
		--in-object=counties \
		--out-object=states \
		--key='d.id.substring(0, 2)' \
		-- $<
