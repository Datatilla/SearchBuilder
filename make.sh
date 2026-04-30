#!/bin/sh

DT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.."
if [ "$1" = "debug" ]; then
    DEBUG="debug"
else
    OUT_DIR=$1
    DEBUG=$2
fi

# If not run from DataTables build script, redirect to there
if [ -z "$DT_BUILD" ]; then
    cd $DT_DIR/build
    ./make.sh extension SearchBuilder $DEBUG
    cd -
    exit
fi

# Change into script's own dir
cd $(dirname $0)

DT_SRC=$(dirname $(dirname $(pwd)))
DT_BUILT="${DT_SRC}/built/DataTables"
. $DT_SRC/build/include.sh

if [ ! -d "node_modules" ]; then
    npm install
fi

if [ ! -d "node_modules/@rollup" ]; then
    npm install
fi

# Create OUT_DIR
if [ ! -d $OUT_DIR ]; then
	mkdir $OUT_DIR
fi

# Copy CSS
if [ -d $OUT_DIR/css ]; then
	rm -r $OUT_DIR/css
fi
cp -r css $OUT_DIR
cp -r node_modules/datatables.net-datetime/css $OUT_DIR
css_frameworks searchBuilder $OUT_DIR/css

node_modules/typescript/bin/tsc

# node_modules/typescript/bin/tsc src/searchBuilder.ts --module ES6 --moduleResolution Node
# node_modules/typescript/bin/tsc src/index.ts --module ES6 --moduleResolution Node
# node_modules/typescript/bin/tsc src/criteria.ts --module ES6 --moduleResolution Node
# node_modules/typescript/bin/tsc src/group.ts --module ES6 --moduleResolution Node

# Copy JS
HEADER="$(head -n 3 src/index.ts)"

if [ -d $OUT_DIR/js ]; then
	rm -r $OUT_DIR/js
fi
mkdir $OUT_DIR/js
cp src/*.js $OUT_DIR/js/

js_frameworks searchBuilder $OUT_DIR/js "jquery datatables.net-FW datatables.net-searchbuilder"

OUT=$OUT_DIR ./node_modules/rollup/dist/bin/rollup \
    --banner "$HEADER" \
    --config rollup.config.js

rm \
    $OUT_DIR/js/index.js \
    $OUT_DIR/js/searchBuilder.js \
    $OUT_DIR/js/criteria.js \
    $OUT_DIR/js/group.js \
    ./src/*.js \

rm ./src/*.d.ts

js_wrap $OUT_DIR/js/dataTables.searchBuilder.js "jquery datatables.net"

# Copy Types
if [ -d $OUT_DIR/types ]; then
	rm -r $OUT_DIR/types
fi
mkdir $OUT_DIR/types

if [ -d types/ ]; then
	cp types/* $OUT_DIR/types
else
	if [ -f types.d.ts ]; then
		cp types.d.ts $OUT_DIR/types
	fi
fi

# Copy and build examples
if [ -d $OUT_DIR/examples ]; then
	rm -r $OUT_DIR/examples		
fi
cp -r examples $OUT_DIR
examples_process $OUT_DIR/examples

# Readme and license
cp Readme.md $OUT_DIR
cp License.txt $OUT_DIR

