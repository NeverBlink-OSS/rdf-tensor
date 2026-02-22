# Data tensors in RDF

**Unofficial Draft**  
_Date: {{ git_revision_date_localized }}_

**Editors:** <br>
&nbsp;Piotr Marciniak (Warsaw University of Technology)<br>
&nbsp;[Piotr Sowiński](https://ostrzyciel.eu) ([NeverBlink](https://neverblink.eu))<br>
&nbsp;[Nikita Kozlov](https://nik.kot.tools) ([NeverBlink](https://neverblink.eu))

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

### 4.2 Operators

When using the binary operators, the input tensors are broadcasted to a common shape. The broadcasting rules are the same as in ONNX **[[ONNX Broadcasting](https://onnx.ai/onnx/repo-docs/Broadcasting.html)]**. After broadcasting, the binary operator is applied element-wise to the input tensors.

Casting of input tensors to a common type is performed according to the rules defined in the ONNX model for each operator, which are based on the precision hierarchy of data types. The resulting tensor will have the more precise type of the two input tensors.

??? info "Type casting rules for binary operators"

    When applying a binary operator to two tensors of different types, the resulting tensor will have the more precise type of the two input tensors. The precision hierarchy is as follows:

    - `float64` > `float32` > `float16`
    - `int64` > `int32` > `int16`
    - `bool` is considered less precise than any numeric type.

    For example, if one tensor is of type `float32` and the other is of type `int32`, the resulting tensor will be of type `float32`. If one tensor is of type `bool` and the other is of type `int16`, the resulting tensor will be of type `int16`.

    In general, follow this algorithm for determining the resulting type:
    
    1. If both tensors have the same type, the result is of that type.
    2. If both tensors are floating-point types, the result is the type with greater precision.
    3. If both tensors are integer types, the result is the type with greater precision.
    4. If one tensor is a floating-point type and the other is an integer type, the result is the floating-point type.
    5. If one tensor is of type `bool`, the result is the other tensor's type.

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

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:sub** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:sub** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

The result of the function is a sub-tensor extracted from the input tensor using numerical index tensor. The selection depends on the structure and values of the index tensor.

- When the _tensor_ is 1-dimensional, the _index tensor_ is a 1-dimensional tensor of indices, and the result is a 1-dimensional tensor containing the elements at those indices.

!!! example

    Evaluating the SPARQL expression
    ```sparql
    tensor:sub("{\"type\":\"int32\",\"shape\":[8],\"data\":[3, 2, 3, 4, 3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[0, 1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [1, 2], \"data\": [1, 3]}"^^tensor:DataTensor
    ```

- When the tensor is multi-dimensional, and the number of rows in the _index tensor_ is equal to the number of dimensions in the tensor, the index tensor is a 2-dimensional tensor where each row contains indices for each dimension. The result is a 1-dimensional tensor containing the elements at those indices.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:sub("{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[0, 1, 1, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2], \"data\": [3, 4]}"^^tensor:DataTensor
    ```

- When the tensor is multi-dimensional, and the number of rows in the _index tensor_ is not equal to the number of dimensions in the tensor, than slice indexing is performed (depends on the index tensor dimensionality).
  - The index tensor is 1-dimensional (it has to be row vector), than slicing is performed along the first dimension, and the result is a tensor with the same number of dimensions as the input tensor, but with the first dimension reduced to the length of the _index tensor_.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:sub("{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[1, 1],\"data\":[1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor
    ```

- The index tensor is 2-dimensional, than slicing is performed firstly the first dimension, and then the second dimension, and the result is a tensor with the same number of dimensions as the input tensor, but with the first two dimensions reduced to the lengths of the _index tensor_.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:sub("{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[0, 0, 1, 1]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2], \"data\": [3, 4, 3, 4]}"^^tensor:DataTensor
    ```

- When the index tensor is more than 3-dimensional, the function will raise an error, as it is not supported.

---

#### `tensor:mask`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:mask** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:mask** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

The result of the function is a sub-tensor extracted from the input tensor using the boolean mask tensor. The selection depends on the mask tensor.

- The mask tensor is used to select elements from the input tensor based on the `true` values in the index tensor. The result is a 1-dimensional tensor containing the selected elements from the flattened tensor.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:sub("{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"bool\",\"shape\":[2, 2],\"data\":[true, false, true, true]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [3], \"data\": [3, 3, 4]}"^^tensor:DataTensor
    ```

---

#### tensor:index

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:index** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:index** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _tensor_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _indexTensor_)

The result of the function is an element or sub-tensor extracted from the input tensor using numerical index tensor. The selection depends on the structure and values of the index tensor.

- When the _index tensor_ size matches the number of dimensions in the input tensor, the _index tensor_ is a 1-dimensional tensor where each element corresponds to an index for each dimension. The result is a scalar value at that index.

- When the _index tensor_ size is less than the number of dimensions in the input tensor, the _index tensor_ is a 1-dimensional tensor where each element corresponds to an index for the first dimensions. The result is a sub-tensor with the remaining dimensions.

- When the _index tensor_ size is greater than the number of dimensions in the input tensor, an error is raised.

!!! example "Example 1"

    Evaluating the SPARQL expression

    ```sparql
    tensor:index("{\"type\":\"int32\",\"shape\":[2, 2],\"data\":[3, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[1, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "4"^^xsd:int
    ```

!!! example "Example 2"

    Evaluating the SPARQL expression

    ```sparql
    tensor:index("{\"type\":\"int32\",\"shape\":[2, 2, 2],\"data\":[1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor, "{\"type\":\"int32\",\"shape\":[2],\"data\":[1, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"int32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor
    ```

### 4.4 Concatenating Functions

#### `tensor:concat`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:concat** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function returns a tensor that is the concatenation of the two input tensors along the specified axis. The other dimensions must match.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:concat(0, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [4, 2], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    ```

#### `tensor:hstack`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:hstack** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function returns a tensor that is the result of horizontally stacking the two input tensors (i.e., concatenation along the last axis). The tensors must be broadcast-compatible along other dimensions.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:hstack("{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [2, 4], \"data\": [1, 2, 5, 6, 3, 4, 7, 8]}"^^tensor:DataTensor
    ```

---

#### `tensor:vstack`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:vstack** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function returns a tensor that is the result of vertically stacking the two input tensors (i.e., concatenation along the first axis). The tensors must be broadcast-compatible along other dimensions.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:vstack("{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [1, 2, 3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2, 2], \"data\": [5, 6, 7, 8]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [4, 2], \"data\": [1, 2, 3, 4, 5, 6, 7, 8]}"^^tensor:DataTensor
    ```

### 4.5. Reduction Functions

#### `tensor:all`

[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **tensor:all** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

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

---

#### `tensor:any`

[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **tensor:any** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

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

---

#### `tensor:none`

[xsd:boolean](http://www.w3.org/2001/XMLSchema#boolean) **tensor:none** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

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

---

#### `tensor:median`

[tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) **tensor:median** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:median** ([xsd:integer](http://www.w3.org/2001/XMLSchema#integer) _axis_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_)

This function computes the median along the specified axis. If the axis is negative, the median is calculated over the entire tensor. It returns a reduced tensor or a scalar.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:median(1, "{\"type\": \"float32\", \"shape\": [1, 3], \"data\": [7, 1, 3]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "{\"type\": \"float32\", \"shape\": [1], \"data\": [3]}"^^tensor:DataTensor
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

### 4.6. Similarity Functions

#### `tensor:cosineSimilarity`

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:cosineSimilarity** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function computes the cosine similarity between two numerical tensors. Returns a numeric scalar value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:cosineSimilarity( "{\"type\": \"float32\", \"shape\": [3], \"data\": [1, 0, 1]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [3], \"data\": [1, 1, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    "0.5"^^xsd:float
    ```

---

#### `tensor:euclideanDistance`

[xsd:double](http://www.w3.org/2001/XMLSchema#double) **tensor:euclideanDistance** ([tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_1_, [tensor:DataTensor](https://w3id.org/rdf-tensor/vocab#DataTensor) _term_2_)

This function computes the Euclidean distance between two numerical tensors. Returns a numeric scalar value.

!!! example

    Evaluating the SPARQL expression

    ```sparql
    tensor:euclideanDistance("{\"type\": \"float32\", \"shape\": [2], \"data\": [3, 4]}"^^tensor:DataTensor, "{\"type\": \"float32\", \"shape\": [2], \"data\": [0, 0]}"^^tensor:DataTensor)
    ```

    returns

    ```turtle
    `"5.0"^^xsd:float
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

## 5. SPARQL Aggregates

The following aggregation functions are implemented as SPARQL extension aggregates. Each function operates over DataTensor values and returns a DataTensor with the most precise type used within each group. These functions do not support the DISTINCT modifier.

### `tensor:SUM`

- **IRI:** `https://w3id.org/rdf-tensor/vocab#SUM`
- **Description:** Sums grouped numeric tensors element-wise.
- **Input:** A group of `DataTensor` values.
- **Output:** A `DataTensor` representing the element-wise sum of all tensors in the group.

### `tensor:AVG`

- **IRI:** `https://w3id.org/rdf-tensor/vocab#AVG`
- **Description:** Computes the element-wise average of grouped tensors.
- **Input:** A group of `DataTensor` values.
- **Output:** A `DataTensor` representing the average tensor.

### `tensor:VAR`

- **IRI:** `https://w3id.org/rdf-tensor/vocab#VAR`
- **Description:** Calculates the element-wise variance across grouped tensors.
- **Input:** A group of `DataTensor` values.
- **Output:** A `DataTensor` representing the variance tensor.

### `tensor:STD`

- **IRI:** `https://w3id.org/rdf-tensor/vocab#STD`
- **Description:** Computes the element-wise standard deviation across grouped tensors.
- **Input:** A group of `DataTensor` values.
- **Output:** A `DataTensor` representing the standard deviation tensor.

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
