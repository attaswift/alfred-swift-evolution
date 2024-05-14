OUTPUT = alfred-swift-evolution.alfredworkflow
OUTPUT_DEV = alfred-swift-evolution-dev.alfredworkflow
FILES = Info.plist se-lookup.swift icon.png

all: $(OUTPUT)

# Build a development version of the workflow with a different bundle ID.
# Useful for testing changes in Alfred without replacing the production version.
dev: $(OUTPUT_DEV)

clean:
	-rm $(OUTPUT) $(OUTPUT_DEV)

$(OUTPUT): $(FILES)
	zip $@ $^

$(OUTPUT_DEV): $(FILES)
	-mkdir build-dev
	cp $^ build-dev/
	plutil -replace bundleid -string "hu.lorentey.alfred.swift-evolution.dev" build-dev/Info.plist
	plutil -replace name -string "Swift Evolution Proposals (development)" build-dev/Info.plist
	zip --junk-paths $@ build-dev/*
	rm build-dev/*
	rmdir build-dev

