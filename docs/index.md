# Data tensors in RDF

**Unofficial Draft**  
*Date: May 25, 2025*

**Editors:** <br> 
&nbsp;Piotr Marciniak<br>
&nbsp;[Piotr Sowiński](https://ostrzyciel.eu)

---

## Abstract

This specification defines an approach to represent data tensors (multi-dimensional arrays) as literals in RDF.
It introduces two new RDF datatypes – `dt:NumericDataTensor` and `dt:BooleanDataTensor`, along with an extension of the SPARQL language.
This extension includes 36 functions and 6 aggregates, enabling the efficient processing of tensor data within RDF frameworks.

**[See our paper for more information](https://arxiv.org/abs/2504.19224)**

## Status of This Document

This document is a draft and does not represent an official standard. It is intended for discussion and gathering feedback within the community.

## 1. Introduction

### 1.1 Document Conventions

*This section is non-normative.*

Examples in this document assume that the following prefixes have been declared to represent the IRIs shown with them here:

**Prefixes used:**

| Prefix | Namespace                                 |
|--------|-------------------------------------------|
| `ex`   | `http://example.org/data-tensor#`         |
| `dt`   | `https://w3id.org/rdf-tensor/datatypes#`  |
| `dtf`  | `https://w3id.org/rdf-tensor/functions#`  |
| `dta`  | `https://w3id.org/rdf-tensor/aggregates#` |
| `xsd`  | `http://www.w3.org/2001/XMLSchema#`       |


## 2. The `dt:NumericDataTensor` Datatype
### IRI

[`https://w3id.org/rdf-tensor/datatypes#NumericDataTensor`](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor)

### Definition

Represents a multi-dimensional array (tensor) of numeric values.

### Lexical Space

A valid JSON object **[[RFC-8259](#rfc-8259)]** with the following structure:

| Key     | Type                | Description                                                                                                  |
|---------|---------------------|--------------------------------------------------------------------------------------------------------------|
| `type`  | `string`            | Must be one of: `float16`, `float32`, `float64`, `int16`, `int32`, `int64`. Defines the type of numbers.     |
| `shape` | `array of integers` | Specifies the size of each dimension. The product of the integers must equal the length of the `data` array. |
| `data`  | `array of numbers`  | A flat array of numbers in row-major (C-style) order. Numbers must use decimal or exponential notation.      |

Other keys may be present in the JSON object, but they are ignored by the datatype.

### Value Space

An n-dimensional numeric tensor, where *n* is the length of shape array.

### Lexical-To-Value Mapping

The lexical representation is parsed as a JSON object. 
The `shape` key is used to determine the dimensions of the tensor, the `data` key contains the numeric values, 
the `type` key is used to efficiently choose the number of bytes for storing numbers and set precision. 
After parsing, the JSON object is converted into a tensor structure.

!!! example

    ```turtle
    "{\"type\": \"float32\", \"shape\": [3, 2], \"data\": [0.1, 1.2, 2.2, 3.2, 4.1, 5.4e2]}"^^dt:NumericDataTensor
    "{\"type\": \"int32\", \"shape\": [1, 2, 2, 2], \"data\": [1, 3, 4, 12, 22, 32, 41, 5]}"^^dt:NumericDataTensor
    ```

## 3. The `dt:BooleanDataTensor` Datatype

### IRI

[`https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor`](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor)

### Definition

Represents a multi-dimensional array (tensor) of boolean values.

### Lexical Space

A valid JSON object **[[RFC-8259](#rfc-8259)]** with the following structure:

| Key     | Type                | Description                                                                                                  |
|---------|---------------------|--------------------------------------------------------------------------------------------------------------|
| `shape` | `array of integers` | Specifies the size of each dimension. The product of the integers must equal the length of the `data` array. |
| `data`  | `array of booleans` | A flat array of boolean values (`true` or `false`), stored in row-major (C-style) order.                     |

Other keys may be present in the JSON object, but they are ignored by the datatype.

### Value Space

An n-dimensional boolean tensor, where *n* is the length of shape array.

### Lexical-To-Value Mapping

The lexical representation is parsed as a JSON object.
The `shape` key is used to determine the dimensions of the tensor, and the `data` key contains the boolean values.
After parsing, the JSON object is converted into a tensor structure.

!!! example

    ```turtle
    "{\"shape\": [2, 2], \"data\": [true, false, false, true]}"^^dt:BooleanDataTensor .
    "{\"shape\": [2, 2, 2], \"data\": [true, false, false, true, false, false, false, true]}"^^dt:BooleanDataTensor .
    ```

## 4. SPARQL Functions
### 4.1. Transforming Functions

#### `dtf:cos`

[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:cos** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its cosine value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:cos("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 3.1415]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, -1]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:exp`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:exp** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its exponential value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:exp("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 1]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2.7183]}"^^dt:NumericDataTensor
    ```


---

#### `dtf:log`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:log** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its natural logarithm value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:log("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2.7183]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 1]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:logp`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:logp** (xsd:double *p*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result is a tensor of the same shape, where each element is replaced by its logarithm with base *p*.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:logp(10, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 10]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 1]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:poly`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:poly** (xsd:double *n*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result is a tensor where each element is raised to the power *n*.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:poly(2, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 9]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:scale`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:scale** (xsd:double *factor*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result is a tensor of the same shape, where each element is multiplied by the given scalar factor.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:scale(3, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [6, 9]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:sin`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:sin** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its sine value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:sin("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 3.1415]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 0]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:abs`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:abs** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its absolute value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:abs("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [-1, 2]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:cast`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:cast** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, xsd:string *type*)

The result of the function is a tensor of the same shape as the input tensor, where each element is cast to the specified type. The supported types are: `float16`, `float32`, `float64`, `int16`, `int32`, and `int64`.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:cast("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1.5, 2.5]}"^^dt:NumericDataTensor, "int32")
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [1, 2]}"^^dt:NumericDataTensor
    ```

### 4.2 Operators

When using the binary operators, the input tensors are broadcasted to a common shape. The broadcasting rules are the same as in NumPy**[[NumPy 8259](#numpy)]**. In the case of numeric tensors, the result of the mathematical operation is a tensor with the more precise type of the two input tensors. For example, if one tensor is `float32` and the other is `int32`, the result will be `float32`. 

#### `dtf:not`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:not** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*)

The result of the function is a tensor of the same shape as the input tensor, where each element is logically negated.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:not("{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^dt:BooleanDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}"^^dt:BooleanDataTensor
    ```

---

#### `dtf:add`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:add** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

The result of the function is a tensor of broadcasted shape, where each element is the sum of corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    dtf:add("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 4]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 6]}"^^dt:NumericDataTensor
    ```


!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    dtf:add("{\"type\":\"float32\",\"shape\":[1, 2, 2], \"data\":[3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[1],\"data\":[1, 2]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2, 2], \"data\": [4, 4, 4, 6]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:subtract`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:subtract** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

The result of the function is a tensor of broadcasted shape, where each element is the difference between corresponding elements in the input tensors.


!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    dtf:subtract("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [5, 7]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 4]}"^^dt:NumericDataTensor
    ```


!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    dtf:subtract("{\"type\":\"float32\",\"shape\":[2, 2], \"data\":[3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[2, 1]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 1, 1, 3]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:multiply`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:multiply** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

The result of the function is a tensor of broadcasted shape, where each element is the product of corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    dtf:multiply("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 5]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [8, 15]}"^^dt:NumericDataTensor
    ```


!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    dtf:multiply("{\"type\":\"int32\",\"shape\":[2, 2], \"data\":[3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[2, 1]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [6, 2, 6, 4]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:divide`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:divide** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

The result of the function is a tensor of broadcasted shape, where each element is the quotient of corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    dtf:divide("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [8, 9]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}")
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 3]}"^^dt:NumericDataTensor
    ```


!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    dtf:divide("{\"type\":\"int32\",\"shape\":[2, 2], \"data\":[3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[2, 1]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [1, 2, 1, 2]}"^^dt:NumericDataTensor
    ```


---

#### `dtf:eq`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:eq** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:eq** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*, [dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_2*)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding elements in the two tensors are equal, and `false` otherwise.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    dtf:eq("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 3]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [true, false]}"^^dt:BooleanDataTensor
    ```


!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    dtf:eq("\"shape\": [1, 2], \"data\": [true, false]}", "{\"shape\": [1], \"data\": [true]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [true, false]}"^^dt:BooleanDataTensor
    ```

---

#### `dtf:neq`

[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:neq** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:neq** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*, [dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_2*)


The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding elements in the two tensors are not equal, and `false` otherwise.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    dtf:neq("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 3]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [false, true]}"^^dt:BooleanDataTensor
    ```


!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    dtf:neq("\"shape\": [1, 2], \"data\": [true, false]}", "{\"shape\": [1], \"data\": [true]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [false, true]}"^^dt:BooleanDataTensor
    ```

---

#### `dtf:and`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:and** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*, [dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_2*)

The function returns a boolean tensor with a broadcasted shape, where each element is the logical AND of the input tensors.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:and("{\"shape\": [1, 2], \"data\": [true, false]}", "{\"shape\": [1, 2], \"data\": [true, true]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [true, false]}"^^dt:BooleanDataTensor
    ```

---

#### `dtf:or`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:or** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*, [dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_2*)

The function returns a boolean tensor with a broadcasted shape, where each element is the logical OR of the input tensors.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:or("{\"shape\": [1, 2], \"data\": [true, false]}", "{\"shape\": [1, 2], \"data\": [false, true]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [true, true]}"^^dt:BooleanDataTensor
    ```

---

#### `dtf:gt`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:gt** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding element from *term_1* is greater than the corresponding element from *term_2*, and `false` otherwise.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:gt("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 3]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [true, false]}"^^dt:BooleanDataTensor
    ```

---

#### `dtf:lt`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:lt** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding element from *term_1* is lesser than the corresponding element from *term_2*, and `false` otherwise.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:lt("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 3]}")
    ```

    returns

    ```turtle
    "{\"shape\": [1, 2], \"data\": [false, true]}"^^dt:BooleanDataTensor
    ```

### 4.3. Indexing Functions

#### `dtf:getSubDT`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:getSubDT** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *tensor*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#DataTensor) *indexTensor*)

[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:getSubDT** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *tensor*, [dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#DataTensor) *indexTensor*)

[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:getSubDT** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *tensor*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#DataTensor) *indexTensor*)

[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:getSubDT** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *tensor*, [dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *indexTensor*)

The result of the function is a sub-tensor extracted from the input numerical tensor using the boolean or numerical index tensor. The selection depends on the structure and values of the index tensor.

* When the *tensor* is 1-dimensional, the *index tensor* is a 1-dimensional tensor of indices, and the result is a 1-dimensional tensor containing the elements at those indices.

!!! example

    Evaluating the SPARQL expression
    ```sparql
    dtf:getSubDT("{\"type\":\"int32\",\"shape\":[8],\"data\":[3, 2, 3, 4, 3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[0, 1]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [1, 3]}"^^dt:NumericDataTensor
    ```
  
* When the tensor is multi-dimensional, and the number of rows in the *index tensor* is equal to the number of dimensions in the tensor, the index tensor is a 2-dimensional tensor where each row contains indices for each dimension. The result is a 1-dimensional tensor containing the elements at those indices.

!!! example 

    Evaluating the SPARQL expression

    ```sparql
    dtf:getSubDT("{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[0, 1, 1, 0]}"^^dt:NumericDataTensor)
    ```
    
    returns
  
    ```turtle
    "{\"type\": \"int32\", \"shape\": [2], \"data\": [3, 4]}"^^dt:NumericDataTensor
    ```

* When the tensor is multi-dimensional, and the number of rows in the *index tensor* is not equal to the number of dimensions in the tensor, than slice indexing is performed (depends on the index tensor dimensionality).
  
  - The index tensor is 1-dimensional (it has to be row vector), than slicing is performed along the first dimension, and the result is a tensor with the same number of dimensions as the input tensor, but with the first dimension reduced to the length of the *index tensor*.

!!! example
 
    Evaluating the SPARQL expression

    ```sparql
    dtf:getSubDT("{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[1, 1],\"data\":[1]}"^^dt:NumericDataTensor)
    ```
    
    returns
        
    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^dt:NumericDataTensor
    ```
    
  - The index tensor is 2-dimensional, than slicing is performed firstly the first dimension, and then the second dimension, and the result is a tensor with the same number of dimensions as the input tensor, but with the first two dimensions reduced to the lengths of the *index tensor*.
              
!!! example

    Evaluating the SPARQL expression
            
    ```sparql
    dtf:getSubDT("{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^dt:NumericDataTensor, "{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[0, 0, 1, 1]}"^^dt:NumericDataTensor)
    ```
        
    returns
        
    ```turtle 
    "{\"type\": \"int32\", \"shape\": [2], \"data\": [3, 4, 3, 4]}"^^dt:NumericDataTensor
    ```
            
  - When the index tensor is more than 3-dimensional, the function will raise an error, as it is not supported.

* If the index tensor is a boolean tensor, it is used to select elements from the input tensor based on the `true` values in the index tensor. The result is a 1-dimensional tensor containing the selected elements from the flattened tensor.

!!! example  

    Evaluating the SPARQL expression
                
    ```sparql
    dtf:getSubDT("{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\":\"bool\",\"shape\":[2, 2],\"data\":[true, false, true, true]}"^^dt:BooleanDataTensor)
    ```
            
    returns
            
    ```turtle
    "{\"type\": \"int32\", \"shape\": [3], \"data\": [3, 3, 4]}"^^dt:NumericDataTensor
    ```


### 4.4 Concatenating Functions

#### `dtf:concat`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:concat** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

This function returns a tensor that is the concatenation of the two input tensors along the specified axis. The other dimensions must match.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:concat(0, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [4, 2], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^dt:NumericDataTensor
    ```

#### `dtf:hstack`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:hstack** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

This function returns a tensor that is the result of horizontally stacking the two input tensors (i.e., concatenation along the last axis). The tensors must be broadcast-compatible along other dimensions.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:hstack("{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 4], \"data\": [1, 2, 5, 6, 3, 4, 7, 8]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:vstack`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:vstack** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

This function returns a tensor that is the result of vertically stacking the two input tensors (i.e., concatenation along the first axis). The tensors must be broadcast-compatible along other dimensions.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:vstack("{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [4, 2], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^dt:NumericDataTensor
    ```

### 4.5. Reduction Functions

#### `dtf:all`
[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **dtf:all** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*)

This function checks if all elements in the boolean tensor are true. Returns a single boolean value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:all("{\"shape\": [2], \"data\": [true, true]}"^^dt:BooleanDataTensor)  
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

---

#### `dtf:any`
[dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) **dtf:any** ([dt:BooleanDataTensor](https://w3id.org/rdf-tensor/datatypes#BooleanDataTensor) *term_1*)

This function checks if any element in the boolean tensor is true. Returns a single boolean value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:any("{\"shape\": [2], \"data\": [false, true]}"^^dt:BooleanDataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

---

#### `dtf:avg`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:avg** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)
[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:avg** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the average along the specified axis. If the axis is negative, the average is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:avg(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 2, 3, 4]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [1.5, 3.5]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:sum`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:sum** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)
[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:sum** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the sum along the specified axis. If the axis is negative, the sum is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:sum(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 2, 3, 4]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 7]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:max`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:max** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:max** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the maximum along the specified axis. If the axis is negative, the maximum is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:max(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 5, 2, 4]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [5, 4]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:median`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:median** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:median** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the median along the specified axis. If the axis is negative, the median is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:median(1, "{\"type\": \"float32\", \"shape\": [1, 3], \"data\": [7, 1, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [3]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:min`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:min** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:min** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the minimum along the specified axis. If the axis is negative, the minimum is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:min(1, "{\"type\": \"float32\", \"shape\": [1,3], \"data\": [7, 1, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [1]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:std`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:std** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:std** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the standard deviation along the specified axis. If the axis is negative, the standard deviation is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:std(1, "{\"type\": \"float32\", \"shape\": [1,3], \"data\": [1, 2, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [0.8165]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:var`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:var** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:var** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the variance along the specified axis. If the axis is negative, the variance is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:var(1, "{\"type\": \"float32\", \"shape\": [1,3], \"data\": [1, 2, 3]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [0.6667]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:norm1`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:norm1** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:norm1** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the L1 norm (sum of absolute values) along the specified axis. If the axis is negative, the L1 norm (sum of absolute values) is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:norm1(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, -1, -2, 2]}"^^dt:NumericDataTensor)  
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [2, 4]}"^^dt:NumericDataTensor
    ```

---

#### `dtf:norm2`
[dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) **dtf:norm2** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:norm1** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) *axis*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*)

This function computes the L2 norm (Euclidean norm) along the specified axis. If the axis is negative, the L2 norm (Euclidean norm) is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:norm2(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [3, 4, 6, 8]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [5, 10]}"^^dt:NumericDataTensor
    ```


### 4.6. Similarity Functions

#### `dtf:cosineSimilarity`
[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:cosineSimilarity** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

This function computes the cosine similarity between two numerical tensors. Returns a numeric scalar value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:cosineSimilarity( "{\"type\": \"float32\", \"shape\": [3], \"data\": [1, 0, 1]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [3], \"data\": [1, 1, 0]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    "0.5"^^xsd:float
    ```

---

#### `dtf:euclideanDistance`
[xsd:double](http://www.w3.org/2001/XMLSchema#double) **dtf:euclideanDistance** ([dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_1*, [dt:NumericDataTensor](https://w3id.org/rdf-tensor/datatypes#NumericDataTensor) *term_2*)

This function computes the Euclidean distance between two numerical tensors. Returns a numeric scalar value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    dtf:euclideanDistance("{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 4]}"^^dt:NumericDataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [0, 0]}"^^dt:NumericDataTensor)
    ```

    returns

    ```turtle
    `"5.0"^^xsd:float
    ```

## 5. SPARQL Aggregates

The following aggregation functions are implemented as SPARQL extension aggregates. Each function operates over NumericDataTensor values and returns a NumericDataTensor with the most precise type used within each group. These functions do not support the DISTINCT modifier.

### `dta:sum`
- **IRI:** `https://w3id.org/rdf-tensor/aggregates#sum`
- **Description:** Sums grouped numeric tensors element-wise.
- **Input:** A group of `NumericDataTensor` values.
- **Output:** A `NumericDataTensor` representing the element-wise sum of all tensors in the group.

### `dta:avg`
- **IRI:** `https://w3id.org/rdf-tensor/aggregates#avg`
- **Description:** Computes the element-wise average of grouped tensors.
- **Input:** A group of `NumericDataTensor` values.
- **Output:** A `NumericDataTensor` representing the average tensor.

### `dta:var`
- **IRI:** `https://w3id.org/rdf-tensor/aggregates#var`
- **Description:** Calculates the element-wise variance across grouped tensors.
- **Input:** A group of `NumericDataTensor` values.
- **Output:** A `NumericDataTensor` representing the variance tensor.

### `dta:std`
- **IRI:** `https://w3id.org/rdf-tensor/aggregates#std`
- **Description:** Computes the element-wise standard deviation across grouped tensors.
- **Input:** A group of `NumericDataTensor` values.
- **Output:** A `NumericDataTensor` representing the standard deviation tensor.

## A. References

### A.1. Informative references

**[rdf11-concepts]**

<a name="rdf-11"></a>
&nbsp; [RDF 1.1 Concepts and Abstract Syntax](https://www.w3.org/TR/rdf11-concepts/). Richard Cyganiak; David Wood; Markus Lanthaler. W3C. 25 February 2014. W3C Recommendation. URL: https://www.w3.org/TR/rdf11-concepts/


**[RFC-8259]**

<a name="rfc-8259"></a>
&nbsp; [RFC 8259](https://www.rfc-editor.org/rfc/rfc8259). Tim Bray. JSON Data Interchange Format. 2017. URL: https://www.rfc-editor.org/rfc/rfc8259


**[NumPy]**
<a name="numpy"></a>
&nbsp; [NumPy](https://numpy.org/). NumPy Developers. NumPy. 2023. URL: https://numpy.org/