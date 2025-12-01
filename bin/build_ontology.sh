#!/bin/bash

# This script prepares the ontology files for publishing.
# You need jelly-cli in your PATH for this script to work.
# See: https://github.com/Jelly-RDF/cli

# Run this script from the root of the repository.

formats=(
  "ttl"
  "jsonld"
  "nt"
  "rdf"
)

mkdir -p publish
for file in ontology/*.ttl; do
    base_name=$(basename "$file" .ttl)
    jelly-cli rdf to-jelly --enable-namespace-declarations "$file" > publish/"$base_name".jelly
    # For each format, convert the jelly file to the desired format
    for format in "${formats[@]}"; do
        jelly-cli rdf from-jelly publish/"$base_name".jelly --to publish/"$base_name"."$format"
    done
done
