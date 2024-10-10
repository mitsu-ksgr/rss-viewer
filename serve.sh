#!/usr/bin/env bash
#
# Sample RSS feed server for dev.
#
readonly WORK_DIR="./.sample-rss-server"
readonly FILE_RSS1="rss1.rdf"
readonly FILE_RSS2="rss2.xml"
readonly FILE_ATOM="atom.xml"


#
# Sample RSS feed URI
#
readonly RSS1_URI="https://www.metro.tokyo.lg.jp/rss/index.rdf"
readonly RSS2_URI="https://www.metro.tokyo.lg.jp/rss/rss_sm.xml"
readonly ATOM_URI="https://www.meti.go.jp/ml_index_release_atom.xml"


# move to script dir.
cd "$(dirname "$0")"

# Make dir for server.
if [ ! -d $WORK_DIR ]; then
    mkdir -p $WORK_DIR
fi

# Download sample rss files.
if [ ! -f "${WORK_DIR}/${FILE_RSS1}" ]; then
    curl -L "${RSS1_URI}" -o "${WORK_DIR}/${FILE_RSS1}"
fi
if [ ! -f "${WORK_DIR}/${FILE_RSS2}" ]; then
    curl -L "${RSS2_URI}" -o "${WORK_DIR}/${FILE_RSS2}"
fi
if [ ! -f "${WORK_DIR}/${FILE_ATOM}" ]; then
    curl -L "${ATOM_URI}" -o "${WORK_DIR}/${FILE_ATOM}"
fi


#
# Run rss server.
#
cd $WORK_DIR
echo "*** RSS Sample Server ***"
echo ""
for f in *.{xml,rdf}; do
    echo "- http://localhost:8000/${f}"
done
echo ""
echo "-------------------------"
python3 -m http.server

