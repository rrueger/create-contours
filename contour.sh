#!/bin/bash

set -e

################################################################################
# Configuration
################################################################################

PROJECT_ROOT=

# Location to create contour of, e.g. N47E008
LOCATION=
# (Linear contour lines) Difference in elevation between contour lines, e.g. 100
ELEV=
# (Exponential contour lines) The exponential base to use for drawing contour
# lines at expoential intervals, e.g. 1.1
BASE=
# Offset from sea-level to use when drawing contour lines, e.g. 400
OFFSET=

# Colours given in RGB or RGBA hex values, e.g. red, #f00, or #00000000
FG_COLOUR=
BG_COLOUR=
# Given in float, e.g. 0.12
LINE_THICKNESS=

# Used for downloading the data from NASA
EARTHDATA_USERNAME=
EARTHDATA_PASS=
################################################################################

cd "$PROJECT_ROOT"

if [[ ! -r "data/$LOCATION.SRTMGL1.hgt.zip" ]]
then
    cd data

    wget                             \
        --quiet                      \
        --show-progress              \
        --continue                   \
        --user="$EARTHDATA_USERNAME" \
        --password="$EARTHDATA_PASS" \
        "https://e4ftl01.cr.usgs.gov//DP133/SRTM/SRTMGL1.003/2000.02.11/$LOCATION.SRTMGL1.hgt.zip"

    cd ..
fi

if [[ ! -r "data/$LOCATION.hgt" ]]
then
    cd data
    unzip "$LOCATION.SRTMGL1.hgt.zip"
    cd ..
fi

SIGMA=50
KERNEL=100

ORIGINAL=$PROJECT_ROOT/data/$LOCATION.hgt
SMOOTHED=$PROJECT_ROOT/data/$LOCATION-s$SIGMA-r$KERNEL.sdat
CONTOUR_LIN=$PROJECT_ROOT/gdal_contours/linear-${ELEV}m-$LOCATION-s$SIGMA-r$KERNEL.gpkg
CONTOUR_EXP=$PROJECT_ROOT/gdal_contours/exp-$BASE-offset-$OFFSET-$LOCATION-s$SIGMA-r$KERNEL.gpkg

if ! [[ -r "$SMOOTHED" ]]
then
    saga_cmd grid_filter "Gaussian Filter"                            \
                                             -INPUT "$ORIGINAL"       \
                                             -SIGMA "$SIGMA"          \
                                             -KERNEL_TYPE 0           \
                                             -KERNEL_RADIUS "$KERNEL" \
                                             -RESULT "$SMOOTHED"
fi

if ! [[ -r "$CONTOUR_LIN" ]]
then
    gdal_contour -a ELEV -i "$ELEV" -f "GPKG" "$SMOOTHED" "$CONTOUR_LIN"
fi

if ! [[ -r "$CONTOUR_EXP" ]]
then
    gdal_contour -e ELEV -off "$OFFSET" -e "$BASE" -f "GPKG" "$SMOOTHED" "$CONTOUR_EXP"
fi

python3 contour.py "$CONTOUR_EXP" "${CONTOUR_EXP/%gpkg/png}" "$FG_COLOUR" "$BG_COLOUR" "$LINE_THICKNESS"
python3 contour.py "$CONTOUR_LIN" "${CONTOUR_LIN/%gpkg/png}" "$FG_COLOUR" "$BG_COLOUR" "$LINE_THICKNESS"
