# RDF-tensor

Specification for tensor literals in RDF &amp; SPARQL

**[See the website](https://w3id.org/rdf-tensor) for more information.**

This is an extension to RDF and SPARQL that introduces 2 new datatypes, dozens of SPARQL functions, and new aggregates to allow for processing of data tensors within RDF graphs. A data tensor is a multi-dimensional array of values, which can be numeric or boolean, commonly used for example in machine learning embeddings.

## Features

- **New datatypes:**
  - `tensor:DataTensor` – represents tensors containing numeric or boolean values
  - `tensor:Range` – represents the range of numbers, either concrete (e.g., 0 to 1) or fully open (e.g., all numbers)
- **New SPARQL functions:**
  - Tensor manipulations (addition, multiplication, reshaping, etc.)
  - Algebraic computations
- **New aggregates:**
  - Generalized aggregation functions for numerical tensors
  - Sum, average, variance, and standard deviation computations

## Implemented datatypes, functions, aggregates, ontology files

**[See the website](https://w3id.org/rdf-tensor) for more details.**

## Editing the ontology

The vocabulary (datatypes, functions, aggregates) is authored in [LinkML](https://linkml.io/) YAML files in the `ontology/` directory. The published RDF artifacts (RDFS in Turtle, N-Triples, JSON-LD, RDF/XML, and [Jelly](https://w3id.org/jelly)) are generated from these sources.

To regenerate the published files locally you need two tools in your `PATH`:

- [`linkml-scala`](https://github.com/NeverBlink-OSS/linkml-scala) – generates RDFS from the LinkML sources.
- [`jelly-cli`](https://github.com/Jelly-RDF/cli) – converts between RDF serializations.

Then run, from the root of the repository:

```bash
bin/build_ontology.sh
```

The generated files are written to the `publish/` directory. CI runs the same script, except that it generates the RDFS with [`linkml-scala-action`](https://github.com/NeverBlink-OSS/linkml-scala-action) and passes the result to the script, so it only needs `jelly-cli`.

## Editing the documentation

1. Clone the repository: `git clone git@github.com:NeverBlink-OSS/rdf-tensor.git`
2. Create a new Python virtual environment using your favorite tool (e.g., [`venv`](https://docs.python.org/3/library/venv.html)).
3. Install the dependencies: `pip install -r requirements.txt`
4. Generate the ontology files so the docs can embed them: `bin/build_ontology.sh` (see above).
5. Compile the docs and host them locally for testing: `mkdocs serve`
6. Whenever you make changes to the documentation pages (they reside in the `docs` directory), the docs will be automatically recompiled.

## Authors, licensing

This repository is maintained and developed by **[NeverBlink](https://neverblink.eu)**.

The original SPARQL extension and implementation for Jena were done by **[Piotr Marciniak](https://github.com/cinekele)** – see the [original repository](https://github.com/RDF-tensor/jena-datatensor).

This repository is licensed under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Citation

If you use this work in an academic context, please cite it as follows:

> Marciniak, P., Sowiński, P., & Ganzha, M. (2025). Representing and Querying Data Tensors in RDF and SPARQL [Conference paper]. Curry, E., et al. The Semantic Web: ESWC 2025 Satellite Events. ESWC 2025. Lecture Notes in Computer Science, 15832. https://doi.org/10.1007/978-3-031-99554-5_12

```bibtex
@inproceedings{rdftensor_2025,
  author = {Marciniak, Piotr and Sowiński, Piotr and Ganzha, Maria},
  booktitle = {Curry, E., et al. The Semantic Web: ESWC 2025 Satellite Events. ESWC 2025. Lecture Notes in Computer Science},
  publisher = {Springer, Cham},
  title = {{Representing and Querying Data Tensors in RDF and SPARQL}},
  url = {https://doi.org/10.1007/978-3-031-99554-5_12},
  year = {2025}
}
```
