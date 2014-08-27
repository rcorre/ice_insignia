DC = dmd
DFLAGS = -w
TEST_FLAGS = -unittest
DBG_FLAGS = -gc -debug
REL_FLAGS = -O -release
IMPORT = ext/dallegro5
LIB = ext/dallegro5
SRC_DIR = src
MODULES = geometry graphics tilemap model state util gui ai
OBJ_DIR = obj
TARGET = bin/run
SRC_FILES := $(foreach sdir,src $(addprefix src/,$(MODULES)),$(wildcard $(sdir)/*.d))
EVERYTHING = -I$(IMPORT) -I$(SRC_DIR) -L-L$(LIB) -of$(TARGET) $(SRC_FILES)

all: debug

debug: $(SRC_FILES)
	$(DC) $(DBG_FLAGS) $(EVERYTHING)

release: $(SRC_FILES)
	$(DC) $(REL_FLAGS) $(EVERYTHING)

run: $(SRC_FILES)
	rdmd $(DBG_FLAGS) -I$(IMPORT) -I$(SRC_DIR) -L-L$(LIB) src/main.d

test: $(SRC_FILES)
	$(DC) $(TEST_FLAGS) $(EVERYTHING)

doc: $(SRC_FILES)
	doc/generate

clean:
	rm bin/* obj/*
