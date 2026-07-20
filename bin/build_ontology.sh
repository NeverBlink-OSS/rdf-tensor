#!/bin/bash
set -euo pipefail

# This script generates the ontology files from the LinkML sources in ontology/
# and prepares them for publishing.
#
# You need the following tools in your PATH for this script to work:
#   - linkml-scala   (RDFS generation)  https://github.com/NeverBlink-OSS/linkml-scala
#   - jelly-cli      (format conversion) https://github.com/Jelly-RDF/cli
#
# Run this script from the root of the repository.

formats=(
  "ttl"
  "jsonld"
  "nt"
  "rdf"
)

mkdir -p publish
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for file in ontology/*.yaml; do
    base_name=$(basename "$file" .yaml)
    # Generate RDFS (Turtle, so namespace prefixes are preserved) into an intermediate file.
    linkml-scala generate rdfs --format ttl --to "$tmpdir/$base_name.ttl" "$file"
    # Round-trip through Jelly to produce all published serializations consistently.
    jelly-cli rdf to-jelly --enable-namespace-declarations "$tmpdir/$base_name.ttl" > publish/"$base_name".jelly
    for format in "${formats[@]}"; do
        jelly-cli rdf from-jelly publish/"$base_name".jelly --to publish/"$base_name"."$format"
    done
done
