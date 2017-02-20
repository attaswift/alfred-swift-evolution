OUTPUT = alfred-swift-evolution.alfredworkflow
FILES = Info.plist se-lookup.swift icon.png

all: $(OUTPUT)

clean:
	-rm $(OUTPUT)

$(OUTPUT): $(FILES)
	zip $@ $(FILES)
