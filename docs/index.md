# Data tensors in RDF

**Unofficial Draft**  
_Date: {{ git_revision_date_localized }}_

**Editors:** <br>
&nbsp;[Nikita Kozlov](https://nik.kot.tools) ([NeverBlink](https://neverblink.eu))<br>
&nbsp;[Piotr Sowiński](https://ostrzyciel.eu) ([NeverBlink](https://neverblink.eu))

**Former editors:** <br>
&nbsp;Piotr Marciniak (Warsaw University of Technology)

---

## Abstract

This specification defines an approach to represent data tensors (multi-dimensional arrays) as literals in RDF.
It introduces two new RDF datatypes – `tensor:DataTensor` and `tensor:DataTensor`, along with an extension of the SPARQL language.
This extension includes 36 functions and 6 aggregates, enabling the efficient processing of tensor data within RDF frameworks.

**[See our paper for more information](https://arxiv.org/abs/2504.19224)**

## Status of This Document

This document is a draft and does not represent an official standard. It is intended for discussion and gathering feedback within the community.

## 1. Introduction

### 1.1 Document Conventions

_This section is non-normative._

Examples in this document assume that the following prefixes have been declared to represent the IRIs shown with them here:

**Prefixes used:**

| Prefix   | Namespace                            |
| -------- | ------------------------------------ |
| `ex`     | `http://example.org/data-tensor#`    |
| `tensor` | `https://w3id.org/rdf-tensor/vocab#` |
| `xsd`    | `http://www.w3.org/2001/XMLSchema#`  |

## 2. The `tensor:DataTensor` Datatype

### IRI

[`https://w3id.org/rdf-tensor/vocab#DataTensor`](https://w3id.org/rdf-tensor/vocab#DataTensor)

### Definition

Represents a multi-dimensional array (tensor) of numeric or boolean values.

### Lexical Space

A valid JSON object **[[RFC-8259](#rfc-8259)]** with the following structure:

| Key     | Type                        | Description                                                                                                                                                        |
| ------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `type`  | `string`                    | Must be one of: `float16`, `float32`, `float64`, `int16`, `int32`, `int64`, `bool`, `uint8`, `uint16`, `uint32`, `uint64`. Defines the type of elements.           |
| `shape` | `array of integers`         | Specifies the size of each dimension. The product of the integers must equal the length of the `data` array.                                                       |
| `data`  | `array of numbers or bools` | A flat array of numbers or booleans in row-major (C-style) order. Numbers must use decimal or exponential notation. Booleans are represented as `true` or `false`. |

Other keys may be present in the JSON object, but they are ignored by the datatype.

### Value Space

An n-dimensional numeric tensor, where _n_ is the length of shape array.

### Lexical-To-Value Mapping

The lexical representation is parsed as a JSON object.
The `shape` key is used to determine the dimensions of the tensor, the `data` key contains the numeric values,
the `type` key is used to efficiently choose the number of bytes for storing numbers and set precision.
After parsing, the JSON object is converted into a tensor structure.

!!! example

    ```turtle
    "{\"type\": \"float32\", \"shape\": [3, 2], \"data\": [0.1, 1.2, 2.2, 3.2, 4.1, 5.4e2]}"^^tensor:DataTensor
    "{\"type\": \"int32\", \"shape\": [1, 2, 2, 2], \"data\": [1, 3, 4, 12, 22, 32, 41, 5]}"^^tensor:DataTensor
    "{\"type\": \"bool\", \"shape\": [2, 3], \"data\": [true, false, true, false, true, false]}"^^tensor:DataTensor
    ```

## 3. The `tensor:Range` Datatype

### IRI

[`https://w3id.org/rdf-tensor/vocab#Range`](https://w3id.org/rdf-tensor/vocab#Range)

### Definition

Represents a range of numeric values, defined by a minimum (inclusive) and maximum (exclusive) value or a "full" range, which includes all possible numeric values.

### Lexical Space

A valid JSON object **[[RFC-8259](#rfc-8259)]** with the following structure:

| Key    | Type     | Description                                                                                                                                              |
| ------ | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type` | `string` | Either `full` or `concrete`. If `full`, the range includes all possible numeric values. If `concrete`, the range is defined by the `from` and `to` keys. |
| `from` | `number` | The minimum value of the range. Required if `type` is `concrete`.                                                                                        |
| `to`   | `number` | The maximum value of the range. Required if `type` is `concrete`.                                                                                        |

Other keys may be present in the JSON object, but they are ignored by the datatype.

### Value Space

An interval of numeric values, defined by the minimum (inclusive) and maximum (exclusive) values, or the full range of numeric values.

### Lexical-To-Value Mapping

The lexical representation is parsed as a JSON object.
The `type` key is used to determine if the range is `full` or `concrete`.
If `type` is `concrete`, the `from` and `to` keys are used to define the range, where `from` is the minimum value (inclusive) and `to` is the maximum value (exclusive).
After parsing, the JSON object is converted into a tensor structure.

!!! example

    ```turtle
    "{\"type\": \"full\"}"^^tensor:Range .
    "{\"type\": \"concrete\", \"from\": 0, \"to\": 10}"^^tensor:Range .
    ```

## 4. SPARQL Functions

Each SPARQL function in this specification is defined as an [ONNX](https://onnx.ai/) model template. These templates contain **model variables** that depend on the actual input (i.e., the data type or shape of an input tensor, axis value). The model variables are denoted in the ONNX model definition using angle brackets, e.g., `<input_type>`, and are described in the "Model description" section for each function. Implementations are expected to resolve these variables at query evaluation time, generate a concrete ONNX model from the template, and execute it using an ONNX runtime.

With this approach it is ensured that the semantics of each function are precisely and unambiguously defined by a machine-readable model, while remaining portable across any ONNX-compatible execution environment.

Examples and description are provided for users to understand the expected behavior of each function, but the actual implementation **must** follow the ONNX model definition.

??? info "RDF tensor type to ONNX data type mapping"

    The mapping from RDF tensor types to ONNX data types is as follows:

    | RDF Tensor Type | ONNX Data Type |
    | --------------- | -------------- |
    | `float16`       | FLOAT16        |
    | `float32`       | FLOAT          |
    | `float64`       | DOUBLE         |
    | `int16`         | INT16          |
    | `int32`         | INT32          |
    | `int64`         | INT64          |
    | `bool`          | BOOL           |
    | `uint8`         | UINT8          |
    | `uint16`        | UINT16         |
    | `uint32`        | UINT32         |
    | `uint64`        | UINT64         |

    Any other types are not supported and will result in an error during query evaluation.

### 4.1. Transforming Functions

#### `tensor:cos`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:cos** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its cosine value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:cos("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 3.1415]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, -1]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the cosine of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_cos_model.pbtxt"
        {% include "./onnx/tensor_cos_model.pbtxt" %}
        ```

---

#### `tensor:exp`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:exp** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its exponential value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:exp("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2.7183]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the exponential of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_exp_model.pbtxt"
        {% include "./onnx/tensor_exp_model.pbtxt" %}
        ```

---

#### `tensor:log`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:log** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its natural logarithm value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:log("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2.7183]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 1]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the natural logarithm of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_log_model.pbtxt"
        {% include "./onnx/tensor_log_model.pbtxt" %}
        ```

---

#### `tensor:logp`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:logp** (xsd:double _p_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result is a tensor of the same shape, where each element is replaced by its logarithm with base _p_.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:logp(10, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 10]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 1]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the logarithm with base _p_ of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `log_base_value`: The logarithm base `log(p)`, where _p_ is the value of the first argument of the function.

    === "Model definition"

        ```pbtxt title="tensor_logp_model.pbtxt"
        {% include "./onnx/tensor_logp_model.pbtxt" %}
        ```

---

#### `tensor:poly`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:poly** (xsd:double _n_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result is a tensor where each element is raised to the power _n_.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:poly(2, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 9]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the corresponding element in `input1` raised to the power _n_.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `exponent_value`: The exponent value _n_ of type DOUBLE, which is the value of the first argument of the function.

    === "Model definition"

        ```pbtxt title="tensor_poly_model.pbtxt"
        {% include "./onnx/tensor_poly_model.pbtxt" %}
        ```

---

#### `tensor:scale`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:scale** (xsd:double _factor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result is a tensor of the same shape, where each element is multiplied by the given scalar factor.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:scale(3, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [6, 9]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the corresponding element in `input1` multiplied by the scalar factor.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `factor_value`: The scaling factor of type DOUBLE, which is the value of the first argument of the function.

    === "Model definition"

        ```pbtxt title="tensor_scale_model.pbtxt"
        {% include "./onnx/tensor_scale_model.pbtxt" %}
        ```

---

#### `tensor:sin`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:sin** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its sine value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:sin("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 3.1415]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [0, 0]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and DOUBLE type, where each element is the sine of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_sin_model.pbtxt"
        {% include "./onnx/tensor_sin_model.pbtxt" %}
        ```

---

#### `tensor:abs`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:abs** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is replaced by its absolute value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:abs("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [-1, 2]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and <input_type> type, where each element is the absolute value of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_abs_model.pbtxt"
        {% include "./onnx/tensor_abs_model.pbtxt" %}
        ```

---

#### `tensor:cast`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:cast** (xsd:string _type_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is cast to the specified type. The supported types are: `float16`, `float32`, `float64`, `int16`, `int32`, `int64` and `bool`. `Bool` type is special - all non-zero values are cast to `true`, and zero values are cast to `false`. If a bool DataTensor is cast to a numeric type, `true` values become `1`, and `false` values become `0`.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:cast("int32", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1.5, 2.5]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [1, 2]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:cast("bool", "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [0, 5]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}"^^tensor:DataTensor
    ```

!!! example "Example 3"

    Evaluating the SPARQL expression

    ```sparql
    tensor:cast("float32", "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1.0, 0.0]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and <output_type> type, where each element is the corresponding element in `input1` cast to the specified type.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `output_type`: The data type to which the elements of the input tensor will be cast, determined by the value of the first argument of the function.

    === "Model definition"

        ```pbtxt title="tensor_cast_model.pbtxt"
        {% include "./onnx/tensor_cast_model.pbtxt" %}
        ```

---

#### `tensor:reshape`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:reshape** (xsd:integer ... _newShape_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor with the specified new shape. The total number of elements will remain the same; thus, the product of the dimensions in the new shape must equal the product of the dimensions in the original shape.

If one of the dimensions in the new shape is specified as -1, its size will be inferred such that the total number of elements remains unchanged.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:reshape(2, 2, "{\"type\":\"int32\",\"shape\":[4],\"data\":[1, 2, 3, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:reshape(1, 4, "{\"type\":\"bool\",\"shape\":[4],\"data\":[true, false, true, false]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 4], \"data\": [true, false, true, false]}"^^tensor:DataTensor
    ```

!!! example "Example 3"

    Evaluating the SPARQL expression

    ```sparql
    tensor:reshape(2, -1, "{\"type\":\"int32\",\"shape\":[6],\"data\":[1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 3], \"data\": [1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the new shape specified by the first argument and the same <input_type> type, containing the same data as `input1` but reshaped.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `new_shape_length`: The number of dimensions in the new shape, determined by the number of integer arguments before the tensor argument.
        - `new_shape_values`: The values of the new shape dimensions, determined by the integer arguments before the tensor argument.

    === "Model definition"

        ```pbtxt title="tensor_reshape_model.pbtxt"
        {% include "./onnx/tensor_reshape_model.pbtxt" %}
        ```

---

#### `tensor:transpose`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:transpose** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor where the dimensions are reversed. For example, a tensor with shape `[2, 3, 4]` will become a tensor with shape `[4, 3, 2]`.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:transpose("{\"type\":\"int32\",\"shape\":[2, 3],\"data\":[1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [3, 2], \"data\": [1, 4, 2, 5, 3, 6]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:transpose("{\"type\": \"bool\", \"shape\":[2, 2],\"data\":[true, false, false, true]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [2, 2], \"data\": [true, false, false, true]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor where the dimensions are reversed compared to `input1`, and the data is transposed accordingly.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_transpose_model.pbtxt"
        {% include "./onnx/tensor_transpose_model.pbtxt" %}
        ```

---

#### `tensor:flatten`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:flatten** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a one-dimensional tensor containing all the elements of the input tensor in row-major (C-style) order.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:flatten("{\"type\":\"int32\",\"shape\":[2, 3],\"data\":[1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [6], \"data\": [1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:flatten("{\"type\": \"bool\", \"shape\":[2, 2],\"data\":[true, false, false, true]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [4], \"data\": [true, false, false, true]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A one-dimensional tensor containing all the elements of `input1` in row-major order, with the same <input_type> type.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_flatten_model.pbtxt"
        {% include "./onnx/tensor_flatten_model.pbtxt" %}
        ```

---

#### `tensor:not`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:not** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where each element is logically negated. For numeric tensors, non-zero values are treated as `true`, and zero and negative values as `false`.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:not("{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:not("{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [0, 5]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and BOOL type, where each element is the logical negation of the corresponding element in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_not_model.pbtxt"
        {% include "./onnx/tensor_not_model.pbtxt" %}
        ```

---

#### `tensor:sort`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:sort** (xsd:string _direction_, xsd:integer _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

The result of the function is a tensor of the same shape as the input tensor, where the elements are sorted along the specified axis in the given direction. The `direction` argument can be either `asc` for ascending order or `desc` for descending order. The `axis` argument specifies the axis along which to sort, where `0` is the first axis, `1` is the second axis, and so on, and negative values count from the last axis backwards (e.g., `-1` is the last axis).

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:sort("asc", 0, "{\"type\": \"int32\", \"shape\": [2, 3], \"data\": [2, 3, 1, 5, 6, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 3], \"data\": [3, 2, 1, 6, 5, 4]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:sort("asc", 2, "{\"type\": \"float64\", \"shape\": [2, 2, 3], \"data\": [3, 1, 2, 6, 4, 5, 9, 7, 8, 12, 10, 11]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float64\", \"shape\": [2, 2, 3], \"data\": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same shape as `input1` and the same <input_type> type, where the elements are sorted along the specified axis in the given direction.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `largest_value`: 1 if the sorting direction is `desc`, and 0 if the sorting direction is `asc`.
        - `axis_value`: The value of the `axis` argument, which specifies the axis along which to sort.
        - `axis_size_value`: The size of the specified axis, which can be determined from the shape of the input tensor.

        Model definition dispatch:

        - For int16 tensors, the implementation is expected to use a different model definition that handles the ONNX limitation of not supporting int16 reduction operations.

    === "Model definition for int16 tensors"

        ```pbtxt title="tensor_sort_int16_model.pbtxt"
        {% include "./onnx/tensor_sort_int16_model.pbtxt" %}
        ```

    === "Model definition for non-int16 tensors"

        ```pbtxt title="tensor_sort_model.pbtxt"
        {% include "./onnx/tensor_sort_model.pbtxt" %}
        ```

---

#### `tensor:resize`

??? info "Resizing functions"

    The functions starting with `tensor:resize` resize a tensor to a different shape by interpolating values. These functions both accept a common set of optional configuration arguments dispatched left-to-right by XSD type and (for mode-dependent arguments) by the value of `mode`:

    1. If the next argument is `xsd:string`, it is taken as the interpolation _mode_. Default: `"linear"`.
    2. If the next argument is `xsd:string`, it is taken as the _coordinateTransformationMode_. Default: `"half_pixel"`.
    3. If _mode_ is `"nearest"` and the next argument is `xsd:string`, it is taken as the _nearestMode_. Default: `"round_prefer_floor"`. Consumed only when _mode_ is `"nearest"`.
    4. If _mode_ is `"cubic"` and the next argument is `xsd:double`, it is taken as _cubicCoeffA_. Default: `-0.75`. Consumed only when _mode_ is `"cubic"`.
    5. If the next argument is `xsd:boolean`, it is taken as the _antialias_ flag. Default: `false`.

    ??? info "Validation errors for resizing functions"

        Implementations must raise a query-evaluation error if:

        - _antialias_ is `true` and _mode_ is `"nearest"`.
        - _coordinateTransformationMode_ is `"tf_crop_and_resize"`. This mode is incompatible with the semantics of these functions and is not supported.
        - _nearestMode_ is provided but _mode_ is not `"nearest"`.
        - _cubicCoeffA_ is provided but _mode_ is not `"cubic"`.
        - The number of sizes/scales does not equal the rank of the input tensor.
        - Any size is less than or equal to `0`, or any scale is less than or equal to `0`.

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:resize** ([xsd:string _mode_], [xsd:string _coordinateTransformationMode_], [xsd:string _nearestMode_], [xsd:double _cubicCoeffA_], [xsd:boolean _antialias_], [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _sizes_)

The result of the function is a tensor resized to the exact shape given by _sizes_, interpolating elements of _term_1_ according to _mode_ and _coordinateTransformationMode_. The _sizes_ tensor must be a 1-D `int64` tensor whose length equals the rank of _term_1_.

Admissible values for the configuration arguments:

- _mode_: `"nearest"`, `"linear"` (default), or `"cubic"`. The `"linear"` mode performs N-linear interpolation (e.g., bilinear for 2-D); `"cubic"` performs N-cubic.
- _coordinateTransformationMode_: `"half_pixel"` (default), `"half_pixel_symmetric"`, `"pytorch_half_pixel"`, `"align_corners"`, or `"asymmetric"`.
- _nearestMode_: `"round_prefer_floor"` (default), `"round_prefer_ceil"`, `"floor"`, or `"ceil"`.
- _cubicCoeffA_: any `xsd:double`. Common values are `-0.5` (TensorFlow-compatible) and `-0.75` (PyTorch-compatible, default).
- _antialias_: when `true`, the linear and cubic kernels are stretched by `max(1, 1/scale)` per dimension being downscaled. Ignored by `"nearest"`.

!!! example "Example 1"

    Evaluating the SPARQL expression (nearest-neighbour 2x upscaling)

    ```sparql
    tensor:resize(
        "nearest", "asymmetric",
        "{\"type\":\"int32\",\"shape\":[1,1,2,2],\"data\":[1, 2, 3, 4]}"^^tensor:DataTensor,
        "{\"type\":\"int64\",\"shape\":[4],\"data\":[1, 1, 4, 4]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 1, 4, 4], \"data\": [1, 1, 2, 2, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 4, 4]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression (nearest-neighbour 0.5x downscaling)

    ```sparql
    tensor:resize(
        "nearest", "asymmetric",
        "{\"type\":\"int32\",\"shape\":[1,1,4,4],\"data\":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]}"^^tensor:DataTensor,
        "{\"type\":\"int64\",\"shape\":[4],\"data\":[1, 1, 2, 2]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 1, 2, 2], \"data\": [1, 3, 9, 11]}"^^tensor:DataTensor
    ```

!!! example "Example 3"

    Evaluating the SPARQL expression (bilinear upscaling, all config defaults)

    ```sparql
    tensor:resize(
        "{\"type\":\"float32\",\"shape\":[1,1,2,2],\"data\":[1, 2, 3, 4]}"^^tensor:DataTensor,
        "{\"type\":\"int64\",\"shape\":[4],\"data\":[1, 1, 4, 4]}"^^tensor:DataTensor
    )
    ```

    returns a `[1, 1, 4, 4]` `float32` tensor bilinearly interpolated from the input.

!!! example "Example 4"

    Evaluating the SPARQL expression (anti-aliased bicubic downscaling, TensorFlow-compatible coefficient)

    ```sparql
    tensor:resize(
        "cubic", "half_pixel", -0.5, true,
        "{\"type\":\"float32\",\"shape\":[1,1,8,8],\"data\":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64]}"^^tensor:DataTensor,
        "{\"type\":\"int64\",\"shape\":[4],\"data\":[1, 1, 3, 3]}"^^tensor:DataTensor
    )
    ```

    returns a `[1, 1, 3, 3]` `float32` tensor produced by bicubic downsampling with the `a = -0.5` kernel and an antialiasing prefilter.

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A 1-D tensor of INT64 type, with length equal to the rank of `input1`, specifying the target size of each dimension.
        - `output1`: A tensor of <input_type> type with shape given by `input2`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `mode_value`: The resolved value of the _mode_ argument, or `"linear"` if omitted.
        - `coord_transform_mode_value`: The resolved value of the _coordinateTransformationMode_ argument, or `"half_pixel"` if omitted.
        - `nearest_mode_value`: The resolved value of the _nearestMode_ argument, or `"round_prefer_floor"` if omitted.
        - `cubic_coeff_a_value`: The resolved value of _cubicCoeffA_ as FLOAT, or `-0.75` if omitted.
        - `antialias_value`: `1` if _antialias_ is `true`, `0` otherwise (default).

    === "Model definition"

        ```pbtxt title="tensor_resize_model.pbtxt"
        {% include "./onnx/tensor_resize_model.pbtxt" %}
        ```

---

#### `tensor:resizeByScales`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:resizeByScales** ([xsd:string _mode_], [xsd:string _coordinateTransformationMode_], [xsd:string _nearestMode_], [xsd:double _cubicCoeffA_], [xsd:boolean _antialias_], [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _scales_)

The result of the function is a tensor where each dimension is scaled by the corresponding factor in _scales_. The output size on dimension _i_ is `floor(input_size[i] * scales[i])`. The _scales_ tensor must be a 1-D floating-point tensor (`float16`, `float32`, or `float64`) whose length equals the rank of _term_1_, and each value must be greater than `0`. A scale of `1.0` leaves that dimension unchanged.

The configuration arguments _mode_, _coordinateTransformationMode_, _nearestMode_, _cubicCoeffA_, and _antialias_ have identical semantics to [`tensor:resize`](#tensorresize).

!!! example "Example 1"

    Evaluating the SPARQL expression (2× bilinear upscaling on H and W with all defaults)
 
    ```sparql
    tensor:resizeByScales(
        "{\"type\":\"float32\",\"shape\":[1,1,2,2],\"data\":[1, 2, 3, 4]}"^^tensor:DataTensor,
        "{\"type\":\"float32\",\"shape\":[4],\"data\":[1.0, 1.0, 2.0, 2.0]}"^^tensor:DataTensor
    )
    ```

    returns a `[1, 1, 4, 4]` `float32` tensor.

!!! example "Example 2"

    Evaluating the SPARQL expression (nearest-neighbour 3× upscaling)

    ```sparql
    tensor:resizeByScales(
        "nearest", "asymmetric", "floor",
        "{\"type\":\"int32\",\"shape\":[1,1,2,2],\"data\":[1, 2, 3, 4]}"^^tensor:DataTensor,
        "{\"type\":\"float32\",\"shape\":[4],\"data\":[1.0, 1.0, 3.0, 3.0]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 1, 6, 6], \"data\": [1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 3, 3, 3, 4, 4, 4, 3, 3, 3, 4, 4, 4]}"^^tensor:DataTensor
    ```

!!! example "Example 3"

    Evaluating the SPARQL expression (anti-aliased bicubic downscaling with PyTorch coefficient)

    ```sparql
    tensor:resizeByScales(
        "cubic", "half_pixel", -0.75, true,
        "{\"type\":\"float32\",\"shape\":[1,1,8,8],\"data\":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64]}"^^tensor:DataTensor,
        "{\"type\":\"float32\",\"shape\":[4],\"data\":[1.0, 1.0, 0.5, 0.5]}"^^tensor:DataTensor
    )
    ```

    returns a `[1, 1, 4, 4]` `float32` tensor produced by anti-aliased bicubic downscaling.

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A 1-D tensor of FLOAT type, with length equal to the rank of `input1`, specifying the scale factor for each dimension.
        - `output1`: A tensor of <input_type> type with shape `floor(input_shape * input2)` per dimension.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `mode_value`: The resolved value of the _mode_ argument, or `"linear"` if omitted.
        - `coord_transform_mode_value`: The resolved value of the _coordinateTransformationMode_ argument, or `"half_pixel"` if omitted.
        - `nearest_mode_value`: The resolved value of the _nearestMode_ argument, or `"round_prefer_floor"` if omitted.
        - `cubic_coeff_a_value`: The resolved value of _cubicCoeffA_ as FLOAT, or `-0.75` if omitted.
        - `antialias_value`: `1` if _antialias_ is `true`, `0` otherwise (default).

        Implementations must cast the _scales_ input tensor to FLOAT before passing it to the ONNX `Resize` operator, as required by the operator's type constraints.

    === "Model definition"

        ```pbtxt title="tensor_resize_by_scales_model.pbtxt"
        {% include "./onnx/tensor_resize_by_scales_model.pbtxt" %}
        ```

---

### 4.2 Operators

When using the binary operators, the input tensors are broadcasted to a common shape. The broadcasting rules are the same as in **[ONNX Broadcasting](https://onnx.ai/onnx/repo-docs/Broadcasting.html)**. After broadcasting, the binary operator is applied element-wise to the input tensors.

Casting of input tensors to a common type is performed according to the rules defined in the ONNX model for each operator, which are based on the precision hierarchy of data types. The resulting tensor will have the more precise type of the two input tensors.

??? info "Type casting rules for binary operators"

    When applying a binary operator to two tensors of different types, the resulting tensor will have the more precise type of the two input tensors. The precision hierarchy is as follows:

    - `float64` > `float32` > `float16`
    - `uint64` >= `int64` > `uint32` >= `int32` > `uint16` >= `int16` > `uint8` >= `int8`
    - `bool` is considered less precise than any numeric type.

    For example, if one tensor is of type `float32` and the other is of type `int32`, the resulting tensor will be of type `float32`. If one tensor is of type `bool` and the other is of type `int16`, the resulting tensor will be of type `int16`.

    In general, follow this algorithm for determining the resulting type:
    
    1. If both tensors have the same type, the result is of that type.
    2. If both tensors are floating-point types, the result is the type with greater precision.
    3. If both tensors are integer types of the same signedness, the result is the type with greater precision.
    4. If both tensors are integer types but one is signed and the other is unsigned, the result is the unsigned type with greater precision.
    5. If one tensor is a floating-point type and the other is an integer type, the result is the floating-point type with greater precision.
    6. If one tensor is of type `bool`, the result is the other tensor's type.

??? info "Optimizing casts for binary operators with identical input types"

    If the input tensors of a binary operator have identical types, it is allowed to skip the type casting step (usually first two `Cast` nodes in the ONNX model definition) and directly apply the operator to the input tensors. This optimization can improve performance by avoiding unnecessary type conversions. However, it is crucial to ensure that the semantics of the function remain unchanged, and the result is the same as if the casts were applied. 
    
    Implementations may verify that the input tensors have the same type before applying this optimization. If the types are different, the implementation must follow the type casting rules as defined in the ONNX model to ensure correct results.

#### `tensor:add`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:add** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The result of the function is a tensor of broadcasted shape, where each element is the sum of corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:add("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 6]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:add("{\"type\":\"float32\",\"shape\":[1, 2, 2], \"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[1],\"data\":[1, 2]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2, 2], \"data\": [4, 4, 4, 6]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A tensor of the broadcasted shape and the more precise type of the two input tensors, where each element is the sum of corresponding elements in `input1` and `input2`.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details)

    === "Model definition"

        ```pbtxt title="tensor_add_model.pbtxt"
        {% include "./onnx/tensor_add_model.pbtxt" %}
        ```

---

#### `tensor:subtract`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:subtract** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The result of the function is a tensor of broadcasted shape, where each element is the difference between corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:subtract("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [5, 7]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 4]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:subtract("{\"type\":\"float32\",\"shape\":[2, 2], \"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[2, 1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 1, 1, 3]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A tensor of the broadcasted shape and the more precise type of the two input tensors, where each element is the difference between corresponding elements in `input1` and `input2`.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details)

    === "Model definition"

        ```pbtxt title="tensor_subtract_model.pbtxt"
        {% include "./onnx/tensor_subtract_model.pbtxt" %}
        ```

---

#### `tensor:multiply`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:multiply** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The result of the function is a tensor of broadcasted shape, where each element is the product of corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:multiply("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 5]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [8, 15]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:multiply("{\"type\":\"int32\",\"shape\":[2, 2], \"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[2, 1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [6, 2, 6, 4]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A tensor of the broadcasted shape and the more precise type of the two input tensors, where each element is the product of corresponding elements in `input1` and `input2`.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details)

    === "Model definition"

        ```pbtxt title="tensor_multiply_model.pbtxt"
        {% include "./onnx/tensor_multiply_model.pbtxt" %}
        ```

---

#### `tensor:divide`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:divide** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The result of the function is a tensor of broadcasted shape, where each element is the quotient of corresponding elements in the input tensors.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:divide("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [8, 9]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [2, 3]}")
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 3]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:divide("{\"type\":\"int32\",\"shape\":[2, 2], \"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[2, 1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [1, 2, 1, 2]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A tensor of the broadcasted shape and the more precise type of the two input tensors, where each element is the quotient of corresponding elements in `input1` and `input2`.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details)

---

#### `tensor:eq`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:eq** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding elements in the two tensors are equal, and `false` otherwise.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:eq("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 3]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:eq("\"shape\": [1, 2], \"data\": [true, false]}", "{\"type\": \"bool\", \"shape\": [1], \"data\": [true]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A boolean tensor of the broadcasted shape, where each element is `true` if the corresponding elements in `input1` and `input2` are equal, and `false` otherwise.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the resolved input tensors, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details).

    === "Model definition"

        ```pbtxt title="tensor_eq_model.pbtxt"
        {% include "./onnx/tensor_eq_model.pbtxt" %}
        ```

---

#### `tensor:neq`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:neq** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:neq** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding elements in the two tensors are not equal, and `false` otherwise.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:neq("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [1, 3]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:neq("{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}", "{\"type\": \"bool\", \"shape\": [1], \"data\": [true]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A boolean tensor of the broadcasted shape, where each element is `true` if the corresponding elements in `input1` and `input2` are not equal, and `false` otherwise.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the resolved input tensors, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details).

    === "Model definition"

        ```pbtxt title="tensor_neq_model.pbtxt"
        {% include "./onnx/tensor_neq_model.pbtxt" %}
        ```

---

#### `tensor:and`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:and** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The function returns a boolean tensor with a broadcasted shape, where each element is the logical AND of the input tensors.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:and("{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}", "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, true]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:and("{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [0, 5]}", "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [2, 0]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, false]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A boolean tensor of the broadcasted shape, where each element is the logical AND of the corresponding elements in `input1` and `input2`.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_and_model.pbtxt"
        {% include "./onnx/tensor_and_model.pbtxt" %}
        ```

---

#### `tensor:or`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:or** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The function returns a boolean tensor with a broadcasted shape, where each element is the logical OR of the input tensors.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:or("{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}", "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, true]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:or("{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [0, 5]}", "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [2, 0]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, true]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A boolean tensor of the broadcasted shape, where each element is the logical OR of the corresponding elements in `input1` and `input2`.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_or_model.pbtxt"
        {% include "./onnx/tensor_or_model.pbtxt" %}
        ```

---

#### `tensor:gt`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:gt** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding element from _term_1_ is greater than the corresponding element from _term_2_, and `false` otherwise.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:gt("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 3]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [true, false]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A boolean tensor of the broadcasted shape, where each element is `true` if the corresponding element in `input1` is greater than the corresponding element in `input2`, and `false` otherwise.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the resolved input tensors, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details).

    === "Model definition"

        ```pbtxt title="tensor_gt_model.pbtxt"
        {% include "./onnx/tensor_gt_model.pbtxt" %}
        ```

---

#### `tensor:lt`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:lt** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

The function returns a boolean tensor with a broadcasted shape, where each element is `true` if the corresponding element from _term_1_ is lesser than the corresponding element from _term_2_, and `false` otherwise.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:lt("{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [4, 2]}", "{\"type\": \"float32\", \"shape\": [1, 2], \"data\": [3, 3]}")
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [1, 2], \"data\": [false, true]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A tensor of any shape and <input_type> type, which can be broadcasted to the shape of `input1`.
        - `output1`: A boolean tensor of the broadcasted shape, where each element is `true` if the corresponding element in `input1` is lesser than the corresponding element in `input2`, and `false` otherwise.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `resolved_type`: The data type of the resolved input tensors, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details).

    === "Model definition"

        ```pbtxt title="tensor_lt_model.pbtxt"
        {% include "./onnx/tensor_lt_model.pbtxt" %}
        ```

### 4.3. Indexing Functions

#### `tensor:sub`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:sub** ([tensor:Range](https://w3id.org/rdf-tensor/vocab#Range) _range1_, ..., [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_)

Extracts a sub-tensor from the input tensor using range-based slicing, similar to NumPy array slicing. Each range argument specifies how to slice along the corresponding dimension of the tensor. The number of range arguments must match the number of dimensions in the input tensor.

!!! example

    Evaluating the SPARQL expression (equivalent to NumPy `tensor[1:3]`)
    ```sparql
    tensor:sub(
        tensor:range(1, 3),
        "{\"type\":\"int32\",\"shape\":[5],\"data\":[10, 20, 30, 40, 50]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2], \"data\": [20, 30]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression (equivalent to NumPy `tensor[:, 1:2]`)
    ```sparql
    tensor:sub(
        tensor:range(),
        tensor:range(1, 2),
        "{\"type\":\"int32\",\"shape\":[2, 3],\"data\":[1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 1], \"data\": [2, 5]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression (equivalent to NumPy `tensor[:, 0:1, 1:2]`)
    ```sparql
    tensor:sub(
        tensor:range(),
        tensor:range(0, 1),
        tensor:range(1, 2),
        "{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 1, 1], \"data\": [2, 6]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression (equivalent to NumPy `tensor[1:2, :]`)
    ```sparql
    tensor:sub(
        tensor:range(1, 2),
        tensor:range(),
        "{\"type\":\"int32\",\"shape\":[3, 2],\"data\":[1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [3, 4]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of the same type as `input1`, where the shape is determined by the specified ranges along each dimension.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axes_length`: The number of dimensions in the input tensor, which must match the number of range arguments.
        - `axes_values`, `starts_values`, `ends_values`: The values of the range arguments, which determine how to slice along each dimension. For each dimension, the range is deconstructed into its corresponding `axis`, `start`, and `end` values. For full slices, the `start` is set to 0 and the `end` is set to the size of the dimension.

    === "Model definition"

        ```pbtxt title="tensor_sub_model.pbtxt"
        {% include "./onnx/tensor_sub_model.pbtxt" %}
        ```

---

#### `tensor:mask`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:mask** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _maskTensor_)

Extracts elements from the input tensor using a boolean mask tensor. The mask tensor must have the same shape as the input tensor or be broadcastable to it.

The function selects elements from the input tensor where the corresponding value in the mask tensor is `true`. The result is always a 1-dimensional tensor containing the selected elements in row-major (C-style) order.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:mask(
        "{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^tensor:DataTensor,
        "{\"shape\":[2, 2],\"data\":[true, false, true, true]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [3], \"data\": [3, 3, 4]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: A boolean tensor of the same shape as `input1` or broadcastable to it, where `true` values indicate which elements to select from `input1`.
        - `output1`: A 1-dimensional tensor containing the selected elements from `input1` in row-major (C-style) order.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `mask_length`: The count of true values in the mask tensor, which determines the length of the output tensor.

    === "Model definition"

        ```pbtxt title="tensor_mask_model.pbtxt"
        {% include "./onnx/tensor_mask_model.pbtxt" %}
        ```

---

#### `tensor:index`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:index** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

Extracts an element or sub-tensor from the input tensor using a numerical index tensor. The behavior depends on the structure of the index tensor.

**Behavior:**

- When the _index tensor_ size matches the number of dimensions in the input tensor, each element corresponds to an index for each dimension. The result is a scalar value at that index.
- When the _index tensor_ size is less than the number of dimensions in the input tensor, each element corresponds to an index for the first N dimensions. The result is a sub-tensor with the remaining dimensions.
- When the _index tensor_ size is greater than the number of dimensions in the input tensor, an error is raised.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:index(
        "{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^tensor:DataTensor,
        "{\"type\":\"int32\",\"shape\":[2],\"data\":[1, 0]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "3"^^xsd:int
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:index(
        "{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor,
        "{\"type\":\"int32\",\"shape\":[1],\"data\":[1]}"^^tensor:DataTensor
    )
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `input2`: An integer tensor where each element is an index for the corresponding dimension of `input1`. The shape of `input2` must be 1D and its size must be less than or equal to the number of dimensions in `input1`.
        - `output1`: A scalar value if the size of `input2` matches the number of dimensions in `input1`, or a sub-tensor containing the remaining dimensions if the size of `input2` is less than the number of dimensions in `input1`.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_index_model.pbtxt"
        {% include "./onnx/tensor_index_model.pbtxt" %}
        ```

### 4.4 Concatenating Functions

For concatenation functions, the input tensors must have compatible shapes according to the rules of **[broadcasting](https://onnx.ai/onnx/repo-docs/Broadcasting.html)**. The output tensor's shape is determined by the shapes of the input tensors and the specified axis of concatenation.

The rules of type resolution and precision hierarchy apply to these functions as well, meaning that the output tensor's data type is determined by the input tensors' data types according to the defined hierarchy.

See both at the [Operators section](#42-operators) above.

#### `tensor:concat`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:concat** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_3_, ...)

This function returns a tensor that is the concatenation of the input tensors along the specified axis. The other dimensions must match.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:concat(0, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [4, 2], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:concat(1, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [9, 10, 11, 12]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 6], \"data\": [1, 2, 5, 6, 9, 10, 3, 4, 7, 8, 11, 12]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input1_type> type.
        - `input2`: A tensor that can be concatenated with `input1` along the specified axis, and has <input2_type> type.
        - `input3`, ..., `inputN`: Additional tensors that can be concatenated with `input1` and `input2` along the specified axis, and have compatible types.
        - `output1`: A tensor of <resolved_type> type, where the shape is determined by concatenating the shapes of `input1` and `input2` along the specified axis.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `input3_type`, ..., `inputN_type`: The data types of additional input tensors, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details) (for more than 2 input tensors, the resolution is applied iteratively across all input types).
        - `axis_value`: The axis along which to concatenate the input tensors, which can be any integer value from `-rank` to `rank-1`, where `rank` is the number of dimensions in the input tensors.

    === "Model definition"

        ```pbtxt title="tensor_concat_model.pbtxt"
        {% include "./onnx/tensor_concat_model.pbtxt" %}
        ```

#### `tensor:hstack`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:hstack** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_3_, ...)

This function returns a tensor that is the result of horizontally stacking the input tensors (i.e., concatenation along the last axis). The tensors must be broadcast-compatible along other dimensions.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:hstack("{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 4], \"data\": [1, 2, 5, 6, 3, 4, 7, 8]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:hstack("{\"type\": \"float32\", \"shape\": [2], \"data\": [1, 2]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 4],}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [5, 6],}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [7, 8],}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 8], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input1_type> type.
        - `input2`: A tensor that can be concatenated with `input1` along the last axis, and has <input2_type> type.
        - `input3`, ..., `inputN`: Additional tensors that can be concatenated with `input1` and `input2` along the last axis, and have compatible types.
        - `output1`: A tensor of <resolved_type> type, where the shape is determined by concatenating the shapes of `input1` and `input2` along the last axis.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `input3_type`, ..., `inputN_type`: The data types of additional input tensors, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details) (for more than 2 input tensors, the resolution is applied iteratively across all input types).
        - `axis_value`: The last axis along which to concatenate the input tensors, which is determined by the rank of the input tensors. For 1D tensors, the axis is 0; for higher-dimensional tensors, the axis is the last one (i.e., `rank-1`).

    === "Model definition"

        ```pbtxt title="tensor_hstack_model.pbtxt"
        {% include "./onnx/tensor_hstack_model.pbtxt" %}
        ```

---

#### `tensor:vstack`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:vstack** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_3_, ...)

This function returns a tensor that is the result of vertically stacking the input tensors (i.e., concatenation along the first axis). The tensors must be broadcast-compatible along other dimensions.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:vstack("{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [4, 2], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:vstack("{\"type\": \"float32\", \"shape\": [2], \"data\": [1, 2]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 4],}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [5, 6],}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [7, 8],}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [8], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input1_type> type.
        - `input2`: A tensor that can be concatenated with `input1` along the first axis, and has <input2_type> type.
        - `input3`, ..., `inputN`: Additional tensors that can be concatenated with `input1` and `input2` along the first axis, and have compatible types.
        - `output1`: A tensor of <resolved_type> type, where the shape is determined by concatenating the shapes of `input1` and `input2` along the first axis.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.
        - `input3_type`, ..., `inputN_type`: The data types of additional input tensors, which can be any supported type.
        - `resolved_type`: The data type of the output tensor, determined by the resolution of the input types according to the precision hierarchy. (see the info box above for more details) (for more than 2 input tensors, the resolution is applied iteratively across all input types).

        **Definition dispatch**:

        - If the input tensors are 1D, then the implementation is expected to use **model definition for 1D tensors**.
        - If the input tensors are ND (N > 1), then the implementation is expected to use **model definition for ND tensors**.
    
    === "Model definition for 1D tensors"

        ```pbtxt title="tensor_vstack_1d_model.pbtxt"
        {% include "./onnx/tensor_vstack_1d_model.pbtxt" %}
        ```

    === "Model definition for ND tensors"

        ```pbtxt title="tensor_vstack_nd_model.pbtxt"
        {% include "./onnx/tensor_vstack_nd_model.pbtxt" %}
        ```

### 4.5. Reduction Functions

#### `tensor:all`

[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **tensor:all** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function checks if all elements in the boolean tensor are true. In case of numeric tensor, it checks if all elements are non-zero. Returns a single boolean value.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:all("{\"type\": \"bool\", \"shape\": [2], \"data\": [true, true]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:all("{\"type\": \"bool\", \"shape\": [2], \"data\": [1, 2]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A single boolean value that is `true` if all elements in the input tensor are true (for boolean tensors) or non-zero (for numeric tensors), and `false` otherwise.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_all_model.pbtxt"
        {% include "./onnx/tensor_all_model.pbtxt" %}
        ```

---

#### `tensor:any`

[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **tensor:any** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function checks if any element in the boolean tensor is true. In case of numeric tensor, it checks if any element is non-zero. Returns a single boolean value.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:any("{\"type\": \"bool\", \"shape\": [2], \"data\": [false, true]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:any("{\"type\": \"bool\", \"shape\": [2], \"data\": [1, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A single boolean value that is `true` if any element in the input tensor is true (for boolean tensors) or non-zero (for numeric tensors), and `false` otherwise.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_any_model.pbtxt"
        {% include "./onnx/tensor_any_model.pbtxt" %}
        ```

---

#### `tensor:none`

[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **tensor:none** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function checks if no elements in the boolean tensor are true. In case of numeric tensor, it checks if all elements are zero. Returns a single boolean value.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:none("{\"type\": \"bool\", \"shape\": [2], \"data\": [false, false]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:none("{\"type\": \"bool\", \"shape\": [2], \"data\": [0, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "true"^^xsd:boolean
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A single boolean value that is `true` if no elements in the input tensor are true (for boolean tensors) or all elements are zero (for numeric tensors), and `false` otherwise.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_none_model.pbtxt"
        {% include "./onnx/tensor_none_model.pbtxt" %}
        ```

---

#### `tensor:avg`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:avg** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:avg** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the average along the specified axis. If the axis is negative, the average is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:avg(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [1.5, 3.5]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the average, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.

    === "Model definition for full reduction"

        ```pbtxt title="tensor_avg_full_model.pbtxt"
        {% include "./onnx/tensor_avg_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction"

        ```pbtxt title="tensor_avg_axis_model.pbtxt"
        {% include "./onnx/tensor_avg_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:sum`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:sum** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:sum** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the sum along the specified axis. If the axis is negative, the sum is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:sum(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 7]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the sum, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
        - For int16 tensors, the implementation is expected to use a different model definition that handles the ONNX limitation of not supporting int16 reduction operations.

    === "Model definition for full reduction for int16 tensors"

        ```pbtxt title="tensor_sum_full_model.pbtxt"
        {% include "./onnx/tensor_sum_full_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for int16 tensors"

        ```pbtxt title="tensor_sum_axis_model.pbtxt"
        {% include "./onnx/tensor_sum_axis_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for full reduction for non-int16 tensors"

        ```pbtxt title="tensor_sum_full_model.pbtxt"
        {% include "./onnx/tensor_sum_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for non-int16 tensors"

        ```pbtxt title="tensor_sum_axis_model.pbtxt"
        {% include "./onnx/tensor_sum_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:prod`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:prod** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:prod** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the product along the specified axis. If the axis is negative, the product is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:prod(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [2, 12]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the product, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
        - For int16 tensors, the implementation is expected to use a different model definition that handles the ONNX limitation of not supporting int16 reduction operations.

    === "Model definition for full reduction for int16 tensors"

        ```pbtxt title="tensor_prod_full_model.pbtxt"
        {% include "./onnx/tensor_prod_full_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for int16 tensors"

        ```pbtxt title="tensor_prod_axis_model.pbtxt"
        {% include "./onnx/tensor_prod_axis_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for full reduction for non-int16 tensors"

        ```pbtxt title="tensor_prod_full_model.pbtxt"
        {% include "./onnx/tensor_prod_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for non-int16 tensors"

        ```pbtxt title="tensor_prod_axis_model.pbtxt"
        {% include "./onnx/tensor_prod_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:max`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:max** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:max** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the maximum along the specified axis. If the axis is negative, the maximum is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:max(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, 5, 2, 4]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [5, 4]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the maximum, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
        - For int16 tensors, the implementation is expected to use a different model definition that handles the ONNX limitation of not supporting int16 reduction operations.

    === "Model definition for full reduction for int16 tensors"

        ```pbtxt title="tensor_max_full_model.pbtxt"
        {% include "./onnx/tensor_max_full_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for int16 tensors"

        ```pbtxt title="tensor_max_axis_model.pbtxt"
        {% include "./onnx/tensor_max_axis_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for full reduction for non-int16 tensors"

        ```pbtxt title="tensor_max_full_model.pbtxt"
        {% include "./onnx/tensor_max_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for non-int16 tensors"

        ```pbtxt title="tensor_max_axis_model.pbtxt"
        {% include "./onnx/tensor_max_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:min`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:min** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:min** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the minimum along the specified axis. If the axis is negative, the minimum is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:min(1, "{\"type\": \"float32\", \"shape\": [1,3], \"data\": [7, 1, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [1]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the minimum, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
        - For int16 tensors, the implementation is expected to use a different model definition that handles the ONNX limitation of not supporting int16 reduction operations.

    === "Model definition for full reduction for int16 tensors"

        ```pbtxt title="tensor_min_full_model.pbtxt"
        {% include "./onnx/tensor_min_full_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for int16 tensors"

        ```pbtxt title="tensor_min_axis_model.pbtxt"
        {% include "./onnx/tensor_min_axis_reduction_int16_model.pbtxt" %}
        ```

    === "Model definition for full reduction for non-int16 tensors"

        ```pbtxt title="tensor_min_full_model.pbtxt"
        {% include "./onnx/tensor_min_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction for non-int16 tensors"

        ```pbtxt title="tensor_min_axis_model.pbtxt"
        {% include "./onnx/tensor_min_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:std`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:std** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:std** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the standard deviation along the specified axis. If the axis is negative, the standard deviation is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:std(1, "{\"type\": \"float32\", \"shape\": [1,3], \"data\": [1, 2, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [0.8165]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the standard deviation, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.
        - `bessel_factor_value`: The Bessel's correction factor, which is used to determine the divisor for calculating the standard deviation. Calculated as n / (n-1), where n is the number of elements along the specified axis.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.

    === "Model definition for full reduction"

        ```pbtxt title="tensor_std_full_model.pbtxt"
        {% include "./onnx/tensor_std_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction"

        ```pbtxt title="tensor_std_axis_model.pbtxt"
        {% include "./onnx/tensor_std_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:var`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:var** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:var** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the variance along the specified axis. If the axis is negative, the variance is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:var(1, "{\"type\": \"float32\", \"shape\": [1,3], \"data\": [1, 2, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [0.6667]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the variance, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.
        - `bessel_factor_value`: The Bessel's correction factor, which is used to determine the divisor for calculating the variance. Calculated as n / (n-1), where n is the number of elements along the specified axis.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.

    === "Model definition for full reduction"

        ```pbtxt title="tensor_var_full_model.pbtxt"
        {% include "./onnx/tensor_var_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction"

        ```pbtxt title="tensor_var_axis_model.pbtxt"
        {% include "./onnx/tensor_var_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:norm1`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:norm1** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:norm1** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the L1 norm (sum of absolute values) along the specified axis. If the axis is negative, the L1 norm (sum of absolute values) is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:norm1(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [1, -1, -2, 2]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [2, 4]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the L1 norm, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
        - For int16 tensors, the implementation is expected to use a different model definition that handles the ONNX limitation of not supporting int16 reduction operations.

    === "Model definition for full reduction for int16 tensors"

        ```pbtxt title="tensor_norm1_full_model.pbtxt"
        {% include "./onnx/tensor_norm1_full_reduction_int16_model.pbtxt" %}
        ```
    
    === "Model definition for axis reduction for int16 tensors"

        ```pbtxt title="tensor_norm1_axis_model.pbtxt"
        {% include "./onnx/tensor_norm1_axis_reduction_int16_model.pbtxt" %}
        ```
    
    === "Model definition for full reduction for non-int16 tensors"

        ```pbtxt title="tensor_norm1_full_model.pbtxt"
        {% include "./onnx/tensor_norm1_full_reduction_model.pbtxt" %}
        ```
    
    === "Model definition for axis reduction for non-int16 tensors"

        ```pbtxt title="tensor_norm1_axis_model.pbtxt"
        {% include "./onnx/tensor_norm1_axis_reduction_model.pbtxt" %}
        ```
    
---

#### `tensor:norm2`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:norm2** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:norm1** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the L2 norm (Euclidean norm) along the specified axis. If the axis is negative, the L2 norm (Euclidean norm) is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:norm2(1, "{\"type\": \"float32\", \"shape\": [2,2], \"data\": [3, 4, 6, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [5, 10]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the L2 norm, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
    
    === "Model definition for full reduction"

        ```pbtxt title="tensor_norm2_full_model.pbtxt"
        {% include "./onnx/tensor_norm2_full_reduction_model.pbtxt" %}
        ```
    
    === "Model definition for axis reduction"

        ```pbtxt title="tensor_norm2_axis_model.pbtxt"
        {% include "./onnx/tensor_norm2_axis_reduction_model.pbtxt" %}
        ```
    
---

#### `tensor:quantile`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:quantile** ([xsd:double](http://www.w3.org/2001/XMLSchema#double) _q_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:quantile** ([xsd:double](http://www.w3.org/2001/XMLSchema#double) _q_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the q-th quantile along the specified axis. The quantile value q should be between 0 and 1 (e.g., 0.5 for median, 0.25 for first quartile). If the axis is negative, the quantile is calculated over the entire flattened tensor. It returns a reduced tensor or a scalar.

If the quantile falls between two data points, the function should return the nearest data point to the quantile.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:quantile(0.5, 1, "{\"type\": \"float32\", \"shape\": [2,3], \"data\": [1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [2, 5]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:quantile(0.25, -1, "{\"type\": \"float32\", \"shape\": [2,3], \"data\": [1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "2"^^xsd:float
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `output1`: A tensor of <input_type> type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the quantile, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.
        - `axis_size_value`: The size of the specified axis, which is used to determine the position of the quantile in the sorted order of the data along that axis. For `axis_value` >= 0, this is the size of the dimension corresponding to `axis_value`. For `axis_value` < 0, this is the total number of elements in the input tensor.
        - `quantile_index_value`: The index of the quantile in the sorted order of the data along the specified axis, calculated as `quantile_index_value = floor(q * (axis_size_value - 1))`, where q is the quantile value.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.

    === "Model definition for full reduction"

        ```pbtxt title="tensor_quantile_full_model.pbtxt"
        {% include "./onnx/tensor_quantile_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction"

        ```pbtxt title="tensor_quantile_axis_model.pbtxt"
        {% include "./onnx/tensor_quantile_axis_reduction_model.pbtxt" %}
        ```

---

#### `tensor:quantileInterpolate`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:quantileInterpolate** ([xsd:double](http://www.w3.org/2001/XMLSchema#double) _q_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:quantileInterpolate** ([xsd:double](http://www.w3.org/2001/XMLSchema#double) _q_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the q-th quantile along the specified axis. The quantile value q should be between 0 and 1 (e.g., 0.5 for median, 0.25 for first quartile). If the axis is negative, the quantile is calculated over the entire flattened tensor. It returns a reduced tensor or a scalar.

If the quantile falls between two data points, the function should interpolate between them to return a value that represents the quantile. The interpolation method is defined as linear interpolation between the two nearest data points.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:quantileInterpolate(0.5, 1, "{\"type\": \"float32\", \"shape\": [2,3], \"data\": [1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2], \"data\": [2, 5]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:quantileInterpolate(0.25, -1, "{\"type\": \"float32\", \"shape\": [2,3], \"data\": [1, 2, 3, 4, 5, 6]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "2.25"^^xsd:float
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input_type> type.
        - `lower_index`: A tensor of integer type representing the index of the lower data point for interpolation. For `axis_value` >= 0, this is calculated as `floor(q * (axis_size_value - 1))`. For `axis_value` < 0, this is calculated as `floor(q * (total_size - 1))`, where `total_size` is the total number of elements in the input tensor.
        - `upper_index`: A tensor of integer type representing the index of the upper data point for interpolation. For `axis_value` >= 0, this is calculated as `ceil(q * (axis_size_value - 1))`. For `axis_value` < 0, this is calculated as `ceil(q * (total_size - 1))`, where `total_size` is the total number of elements in the input tensor.
        - `fraction`: A tensor of float type representing the fractional part for interpolation, calculated as `q * (axis_size_value - 1) - lower_index` for `axis_value` >= 0, or `q * (total_size - 1) - lower_index` for `axis_value` < 0.
        - `output1`: A tensor of DOUBLE type, where the shape is determined by reducing the input tensor along the specified axis.

        Model variables:

        - `input_type`: The data type of the input tensor, which can be any supported type.
        - `axis_value`: The axis along which to compute the quantile, which can be any integer value from `-1` to `rank-1`, where `rank` is the number of dimensions in the input tensor.
        - `axis_size_value`: The size of the specified axis, which is used to determine the position of the quantile in the sorted order of the data along that axis. For `axis_value` >= 0, this is the size of the dimension corresponding to `axis_value`. For `axis_value` < 0, this is the total number of elements in the input tensor.

        Model definition dispatch:
        
        - if `axis_value` is negative, then the implementation is expected to use **model definition for full reduction**.
        - if `axis_value` is non-negative, then the implementation is expected to use **model definition for axis reduction**.
        - if it is determined that interpolation is needed (i.e., the quantile falls between two data points), then the implementation is expected to use the model definition for interpolation. Otherwise, it should use the model definition for no interpolation.

    === "Model definition for full reduction with no interpolation"

        ```pbtxt title="tensor_quantile_interpolate_no_interpolation_full_reduction_model.pbtxt"
        {% include "./onnx/tensor_quantile_interpolate_no_interpolation_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction with no interpolation"

        ```pbtxt title="tensor_quantile_interpolate_no_interpolation_axis_reduction_model.pbtxt"
        {% include "./onnx/tensor_quantile_interpolate_no_interpolation_axis_reduction_model.pbtxt" %}
        ```
    
    === "Model definition for full reduction with interpolation"

        ```pbtxt title="tensor_quantile_interpolate_with_interpolation_full_reduction_model.pbtxt"
        {% include "./onnx/tensor_quantile_interpolate_with_interpolation_full_reduction_model.pbtxt" %}
        ```

    === "Model definition for axis reduction with interpolation"

        ```pbtxt title="tensor_quantile_interpolate_with_interpolation_axis_reduction_model.pbtxt"
        {% include "./onnx/tensor_quantile_interpolate_with_interpolation_axis_reduction_model.pbtxt" %}
        ```

---

### 4.6. Similarity Functions

#### `tensor:cosineSimilarity`

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:cosineSimilarity** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function computes the cosine similarity between two tensors. Returns a numeric scalar value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:cosineSimilarity( "{\"type\": \"float32\", \"shape\": [3], \"data\": [1, 0, 1]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [3], \"data\": [1, 1, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "0.5"^^xsd:float
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input1_type> type.
        - `input2`: A tensor of the same shape and <input2_type> type.
        - `output1`: A single numeric value representing the cosine similarity between the two input tensors.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_cosine_similarity_model.pbtxt"
        {% include "./onnx/tensor_cosine_similarity_model.pbtxt" %}
        ```

---

#### `tensor:euclideanDistance`

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:euclideanDistance** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function computes the Euclidean distance between two tensors. Returns a numeric scalar value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:euclideanDistance("{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [0, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    `"5.0"^^xsd:float
    ```

??? note "ONNX definition of this function"

    === "Model description"

        Model inputs and outputs:

        - `input1`: A tensor of any shape and <input1_type> type.
        - `input2`: A tensor of the same shape and <input2_type> type.
        - `output1`: A single numeric value representing the Euclidean distance between the two input tensors.

        Model variables:

        - `input1_type`: The data type of the first input tensor, which can be any supported type.
        - `input2_type`: The data type of the second input tensor, which can be any supported type.

    === "Model definition"

        ```pbtxt title="tensor_euclidean_distance_model.pbtxt"
        {% include "./onnx/tensor_euclidean_distance_model.pbtxt" %}
        ```

### 4.7 Creation Functions

#### `tensor:create`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:create** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) | [xsd:float](http://www.w3.org/2001/XMLSchema#float) | [xsd:double](http://www.w3.org/2001/XMLSchema#double) | [xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) ... _values_)

This function creates a `DataTensor` from a list of scalar values of the specified type. The resulting tensor has a shape of `[N]`, where N is the number of input values.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:create("int32", 1, 2, 3, 4)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [4], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:create("bool", true, false, true)
    ```

    returns

    ```turtle
    "{\"type\": \"bool\", \"shape\": [3], \"data\": [true, false, true]}"^^tensor:DataTensor
    ```

#### `tensor:range`

[tensor:Range](https://w3id.org/rdf-tensor/vocab#Range) **tensor:range** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _from_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _to_)

[tensor:Range](https://w3id.org/rdf-tensor/vocab#Range) **tensor:range** ()

This function creates a `Range` object representing a sequence of indices from `from` to `to` (inclusive of `from`, exclusive of `to`). If no arguments are provided, it represents the full range.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:range(0, 5)
    ```

    returns a `Range` object representing the indices from 0 to 4.

    ```turtle
    "{\"type\": \"concrete\", \"from\": 0, \"to\": 5}"^^tensor:Range
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:range()
    ```

    returns a `Range` object representing the full range of indices for slicing tensors.

    ```turtle
    "{\"type\": \"full\"}"^^tensor:Range
    ```

---

#### `tensor:shape`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:shape** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function returns a 1-dimensional tensor of type `int64` containing the shape (dimensions) of the input tensor. For example, if the input tensor has shape `[2, 3, 4]`, the result is a 1-dimensional tensor `[2, 3, 4]` with shape `[3]`.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:shape("{\"type\": \"float32\", \"shape\": [2, 3, 4], \"data\": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int64\", \"shape\": [3], \"data\": [2, 3, 4]}"^^tensor:DataTensor
    ```

---

#### `tensor:arange`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:arange** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _start_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _stop_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:arange** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _start_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _stop_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _step_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:arange** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [tensor:Range](https://w3id.org/rdf-tensor/vocab#Range) _range_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _step_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:arange** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [tensor:Range](https://w3id.org/rdf-tensor/vocab#Range) _range_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:arange** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [xsd:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _dt_, [xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _step_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:arange** ([xsd:string](http://www.w3.org/2001/XMLSchema#string) _type_, [xsd:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _dt_)

This function creates a 1D tensor containing evenly spaced values within the half-open interval [start, stop). Similar to NumPy's `np.arange`. The first argument is the data type (e.g., "int32", "float64"), followed by start, stop, and optionally step (default 1). The resulting tensor has shape [N], where N is the number of values in the range.

The function supports multiple overloads for specifying the range:
- Using `start`, `stop`, and optional `step` as integers.
- Using a `Range` object to specify the start and stop values.
- Using a `DataTensor` of shape [2] to specify the start and stop values, where the first element is the start and the second element is the stop.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:arange("int32", 0, 5)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [5], \"data\": [0, 1, 2, 3, 4]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:arange("float64", 0, 10, 2)
    ```

    returns

    ```turtle
    "{\"type\": \"float64\", \"shape\": [5], \"data\": [0.0, 2.0, 4.0, 6.0, 8.0]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:arange("int32", 5, 0, -1)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [5], \"data\": [5, 4, 3, 2, 1]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:arange("int32", tensor:range(0, 5))
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [5], \"data\": [0, 1, 2, 3, 4]}"^^tensor:DataTensor
    ```

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:arange("int32", "{\"type\": \"int64\", \"shape\": [2], \"data\": [0, 5]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [5], \"data\": [0, 1, 2, 3, 4]}"^^tensor:DataTensor
    ```

---

## 5. SPARQL Aggregates

The following aggregation functions are implemented as SPARQL extension aggregates. Each aggregate operates over a group of `tensor:DataTensor` values bound during SPARQL `GROUP BY` evaluation and returns a single `tensor:DataTensor`. All tensors within a group must have the same shape. When tensors have different numeric data types, automatic type casting is performed to a common type. These aggregates do not support the `DISTINCT` modifier.

Each aggregate is defined by up to three ONNX model templates, corresponding to the three phases of aggregation:

- Initial model – processes the first value in a group to set up internal accumulators.
- Reduce model – incorporates each subsequent value into the accumulators.
- Complete model – produces the final aggregated result from the accumulators.

Simple aggregates (e.g., `tensor:SUM`) may not require a separate initial model if the first value can be used directly as the accumulator.

### `tensor:SUM`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:SUM** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _?expr_)

Computes the element-wise sum of all tensors in a group. The result is a tensor of the same shape as the input tensors, where each element is the sum of the corresponding elements across all tensors in the group. When input tensors have different numeric data types, they are cast to a common type before summation.

!!! example

    Given the following RDF data:

    ```turtle
    :x :p1 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p2 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p3 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    ```

    Evaluating the SPARQL query

    ```sparql
    SELECT (tensor:SUM(?val) AS ?sum)
    WHERE { ?s ?p ?val }
    GROUP BY ?s
    ```

    returns a binding where `?sum` is

    ```turtle
    "{\"type\": \"float64\", \"shape\": [3], \"data\": [41.0, 71.0, 91.0]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this aggregate"

    === "Model description"

        Aggregation phases:

        - Initial: The first tensor value is used directly as the accumulator. No ONNX model is needed.
        - Reduce: Each subsequent tensor is added element-wise to the accumulator using an ONNX `Add` operation.
        - Complete: The accumulator is returned directly as the result. No ONNX model is needed.

        Reduce model inputs and outputs:

        - `input1`: The current accumulator tensor of <accumulator_type> type.
        - `input2`: The next tensor to add, of <input_type> type.
        - `output1`: The updated accumulator tensor after element-wise addition of <resolved_type> type.

        Model variables:

        - `accumulator_type`: The data type of the current accumulator tensor.
        - `input_type`: The data type of the incoming tensor, which can be any supported numeric type.
        - `resolved_type`: The common data type to which both the accumulator and input tensor are cast for addition, determined by type hierarchy and casting rules.

    === "Reduce model definition"

        ```pbtxt title="tensor_SUM_reduce_model.pbtxt"
        {% include "./onnx/tensor_SUM_reduce_model.pbtxt" %}
        ```

---

### `tensor:AVG`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:AVG** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _?expr_)

Computes the element-wise average (arithmetic mean) of all tensors in a group. The result is always a DOUBLE-typed tensor of the same shape as the input tensors, where each element is the mean of the corresponding elements across all tensors in the group.

Internally, the aggregate accumulates the element-wise sum and the count of tensors. On completion, the sum is cast to DOUBLE and divided by the count.

!!! example

    Given the following RDF data:

    ```turtle
    :x :p1 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p2 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p3 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p4 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p5 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    ```

    Evaluating the SPARQL query

    ```sparql
    SELECT (tensor:AVG(?val) AS ?avg)
    WHERE { ?s ?p ?val }
    GROUP BY ?s
    ```

    returns a binding where `?avg` is

    ```turtle
    "{\"type\": \"float64\", \"shape\": [3], \"data\": [12.2, 22.2, 30.2]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this aggregate"

    === "Model description"

        Aggregation phases:

        - Initial: The first tensor value and a count of 1 are stored as the accumulator. No ONNX model is needed.
        - Reduce: Each subsequent tensor is added element-wise to the accumulator sum using an ONNX `Add` operation, and the count is incremented.
        - Complete: The accumulated sum is cast to DOUBLE and divided element-wise by the count to produce the mean.

        Reduce model inputs and outputs:

        - `input1`: The current sum accumulator tensor of <accumulator_type> type.
        - `input2`: The next tensor to add, of <input_type> type.
        - `output1`: The updated sum accumulator tensor after element-wise addition of <resolved_type> type.

        Complete model inputs and outputs:

        - `input1`: The accumulated sum tensor of <accumulator_type> type.
        - `output1`: The average tensor of DOUBLE type, computed as `Cast(input1, DOUBLE) / count`.

        Model variables:

        - `accumulator_type`: The data type of the current sum accumulator tensor.
        - `input_type`: The data type of the incoming tensor, which can be any supported numeric type.
        - `resolved_type`: The common data type to which both the accumulator and input tensor are cast for addition, determined by type hierarchy and casting rules.
        - `count_value`: The total number of tensors in the group, of type DOUBLE.

    === "Reduce model definition"

        ```pbtxt title="tensor_AVG_reduce_model.pbtxt"
        {% include "./onnx/tensor_AVG_reduce_model.pbtxt" %}
        ```

    === "Complete model definition"

        ```pbtxt title="tensor_AVG_complete_model.pbtxt"
        {% include "./onnx/tensor_AVG_complete_model.pbtxt" %}
        ```

---

### `tensor:VAR`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:VAR** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _?expr_)

Computes the element-wise population variance of all tensors in a group. The result is always a DOUBLE-typed tensor of the same shape as the input tensors, where each element is the variance of the corresponding elements across all tensors in the group.

The variance is computed using the formula: Var(X) = E[X^2] − (E[X])^2, where E denotes the mean over the group. Internally, the aggregate tracks the element-wise sum of squares and the element-wise sum. On completion, it divides both by the count and applies the formula.

Requires at least two tensors in the group.

!!! example

    Given the following RDF data:

    ```turtle
    :x :p1 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p2 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p3 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p4 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p5 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    ```

    Evaluating the SPARQL query

    ```sparql
    SELECT (tensor:VAR(?val) AS ?variance)
    WHERE { ?s ?p ?val }
    GROUP BY ?s
    ```

    returns a binding where `?variance` is approximately

    ```turtle
    "{\"type\": \"float64\", \"shape\": [3], \"data\": [9.075, 9.075, 0.075]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this aggregate"

    === "Model description"

        Aggregation phases:

        - Initial: the first tensor is cast to DOUBLE. The element-wise square (x^2) is computed as one accumulator, and the cast value itself is the other. The count is initialized to 1.
        - Reduce: each subsequent tensor is cast to DOUBLE, squared, and added to the sum-of-squares accumulator. The cast value is added to the sum accumulator. The count is incremented.
        - Complete: the variance is computed as E[X^2] − (E[X])^2 by dividing both accumulators by the count and applying the formula.

        Initial model inputs and outputs:

        - `input1`: The first tensor value of <input_type> type.
        - `output1`: The squared tensor (x^2), cast to DOUBLE type.
        - `output2`: The tensor value itself, cast to DOUBLE type.

        Reduce model inputs and outputs:

        - `input1`: The current sum-of-squares accumulator tensor of DOUBLE type.
        - `input2`: The current sum accumulator tensor of DOUBLE type.
        - `input3`: The next tensor to accumulate, of <input_type> type.
        - `output1`: The updated sum-of-squares accumulator (input1 + Cast(input3)^2).
        - `output2`: The updated sum accumulator (input2 + Cast(input3)).

        Complete model inputs and outputs:

        - `input1`: The accumulated sum-of-squares tensor of DOUBLE type.
        - `input2`: The accumulated sum tensor of DOUBLE type.
        - `output1`: The variance tensor of DOUBLE type, computed as (input1 / count) − (input2 / count)^2.

        Model variables:

        - `input_type`: The data type of the incoming tensor, which can be any supported numeric type.
        - `count_value`: The total number of tensors in the group, of type DOUBLE.

    === "Initial model definition"

        ```pbtxt title="tensor_VAR_initial_model.pbtxt"
        {% include "./onnx/tensor_VAR_initial_model.pbtxt" %}
        ```

    === "Reduce model definition"

        ```pbtxt title="tensor_VAR_reduce_model.pbtxt"
        {% include "./onnx/tensor_VAR_reduce_model.pbtxt" %}
        ```

    === "Complete model definition"

        ```pbtxt title="tensor_VAR_complete_model.pbtxt"
        {% include "./onnx/tensor_VAR_complete_model.pbtxt" %}
        ```

---

### `tensor:STD`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:STD** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _?expr_)

Computes the element-wise population standard deviation of all tensors in a group. The result is always a DOUBLE-typed tensor of the same shape as the input tensors, where each element is the standard deviation of the corresponding elements across all tensors in the group.

The standard deviation is computed as the square root of the population variance: Std(X) = sqrtVar(X) = sqrt(E[X^2] − (E[X])^2). Internally, the aggregate uses the same accumulation strategy as `tensor:VAR` (tracking sum of squares and sum), but applies an additional square root in the completion phase.

Requires at least two tensors in the group.

!!! example

    Given the following RDF data:

    ```turtle
    :x :p1 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p2 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p3 "{\"type\":\"float64\",\"shape\":[3],\"data\":[15.5, 25.5, 30.5]}"^^tensor:DataTensor .
    :x :p4 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    :x :p5 "{\"type\":\"int32\",\"shape\":[3],\"data\":[10, 20, 30]}"^^tensor:DataTensor .
    ```

    Evaluating the SPARQL query

    ```sparql
    SELECT (tensor:STD(?val) AS ?stddev)
    WHERE { ?s ?p ?val }
    GROUP BY ?s
    ```

    returns a binding where `?stddev` is approximately

    ```turtle
    "{\"type\": \"float64\", \"shape\": [3], \"data\": [3.0125, 3.0125, 0.2739]}"^^tensor:DataTensor
    ```

??? note "ONNX definition of this aggregate"

    === "Model description"

        **Aggregation phases:**

        - Initial: the first tensor is cast to DOUBLE. The element-wise square (x^2) is computed as one accumulator, and the cast value itself is the other. The count is initialized to 1.
        - Reduce: each subsequent tensor is cast to DOUBLE, squared, and added to the sum-of-squares accumulator. The cast value is added to the sum accumulator. The count is incremented.
        - Complete: the variance is computed as E[X^2] − (E[X])^2, followed by an element-wise square root to produce the standard deviation.

        **Initial model inputs and outputs:**

        - `input1`: The first tensor value of <input_type> type.
        - `output1`: The squared tensor (x^2), cast to DOUBLE type.
        - `output2`: The tensor value itself, cast to DOUBLE type.

        **Reduce model inputs and outputs:**

        - `input1`: The current sum-of-squares accumulator tensor of DOUBLE type.
        - `input2`: The current sum accumulator tensor of DOUBLE type.
        - `input3`: The next tensor to accumulate, of <input_type> type.
        - `output1`: The updated sum-of-squares accumulator (input1 + Cast(input3)^2).
        - `output2`: The updated sum accumulator (input2 + Cast(input3)).

        **Complete model inputs and outputs:**

        - `input1`: The accumulated sum-of-squares tensor of DOUBLE type.
        - `input2`: The accumulated sum tensor of DOUBLE type.
        - `output1`: The standard deviation tensor of DOUBLE type, computed as sqrt((input1 / count) − (input2 / count)^2).

        Model variables:

        - `input_type`: The data type of the incoming tensor, which can be any supported numeric type.
        - `count_value`: The total number of tensors in the group, of type DOUBLE.

    === "Initial model definition"

        ```pbtxt title="tensor_STD_initial_model.pbtxt"
        {% include "./onnx/tensor_STD_initial_model.pbtxt" %}
        ```

    === "Reduce model definition"

        ```pbtxt title="tensor_STD_reduce_model.pbtxt"
        {% include "./onnx/tensor_STD_reduce_model.pbtxt" %}
        ```

    === "Complete model definition"

        ```pbtxt title="tensor_STD_complete_model.pbtxt"
        {% include "./onnx/tensor_STD_complete_model.pbtxt" %}
        ```

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

**[ONNX (Open Neural Network Exchange)]**

<a name="onnx"></a>
&nbsp; [ONNX (Open Neural Network Exchange)](https://onnx.ai/). ONNX. 2019. URL: https://onnx.ai/
