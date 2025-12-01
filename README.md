# rdf-tensor
Specification for tensor literals in RDF &amp; SPARQL

**[See the website](https://w3id.org/rdf-tensor) for more information.**

This is an extension to RDF and SPARQL that introduces 2 new datatypes, dozens of SPARQL functions, and new aggregates to allow for processing of data tensors within RDF graphs. A data tensor is a multi-dimensional array of values, which can be numeric or boolean, commonly used for example in machine learning embeddings.

## Features

- **New datatypes:**
  - `tensor:NumericDataTensor` – represents tensors containing numeric values.
  - `tensor:BooleanDataTensor` – represents tensors containing boolean values.
- **New SPARQL functions:**
  - Tensor manipulations (addition, multiplication, reshaping, etc.)
  - Algebraic computations
- **New aggregates:**
  - Generalized aggregation functions for numerical tensors
  - Sum, average, variance, and standard deviation computations

## Implemented datatypes, functions, aggregates, ontology files

**[See the website](https://w3id.org/rdf-tensor) for more details.**

## Editing the documentation

1. Clone the repository: `git clone git@github.com:NeverBlink-OSS/rdf-tensor.git`
2. Create a new Python virtual environment using your favorite tool (e.g., [`venv`](https://docs.python.org/3/library/venv.html)).
3. Install the dependencies: `pip install -r requirements.txt`
4. Compile the docs and host them locally for testing: `mkdocs serve`
5. Whenever you make changes to the documentation pages (they reside in the `docs` directory), the docs will be automatically recompiled.

## Authors, licensing

The original SPARQL extension and implementation for Jena were done by **[Piotr Marciniak](https://github.com/cinekele)** – see the [original repository](https://github.com/RDF-tensor/jena-datatensor).

The work is continued in this repository under the stewardship of [NeverBlink](https://neverblink.eu). The current maintainer is **[Piotr Sowiński (Ostrzyciel)](https://github.com/Ostrzyciel)**

This repository is licensed under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
