#!/bin/bash
set -euo pipefail

# This script generates the ontology files from the LinkML sources in ontology/
# and prepares them for publishing.
#
# You need the following tools in your PATH for this script to work:
#   - linkml-scala   (RDFS generation)  https://github.com/NeverBlink-OSS/linkml-scala
#   - jelly-cli      (format conversion) https://github.com/Jelly-RDF/cli
#
# You can also pass a directory of already-generated RDFS Turtle files (named
# "<schema>.rdfs.ttl") as the first argument, in which case linkml-scala is not
# needed. CI does this, using the output of linkml-scala-action.
#
# Run this script from the root of the repository.

formats=(
  "jsonld"
  "nt"
  "rdf"
)

rdfs_dir="${1:-}"

# Start from an empty output directory. jelly-cli's --to opens the output file in
# append mode, so re-running the script would otherwise concatenate onto the
# previous run's files instead of replacing them.
rm -rf publish
mkdir -p publish

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

if [[ -z "$rdfs_dir" ]]; then
    rdfs_dir="$tmpdir"
    for file in ontology/*.yaml; do
        # Generate RDFS as Turtle, so that namespace prefixes are preserved.
        linkml-scala generate rdfs --format ttl \
            --to "$rdfs_dir/$(basename "$file" .yaml).rdfs.ttl" "$file"
    done
fi

for file in "$rdfs_dir"/*.rdfs.ttl; do
    base_name=$(basename "$file" .rdfs.ttl)
    # Publish the Turtle as-is.
    cp "$file" publish/"$base_name".ttl
    # Round-trip through Jelly to produce the remaining serializations consistently.
    jelly-cli rdf to-jelly --enable-namespace-declarations "$file" > publish/"$base_name".jelly
    for format in "${formats[@]}"; do
        jelly-cli rdf from-jelly publish/"$base_name".jelly --to publish/"$base_name"."$format"
    done
done
