#!/usr/bin/env python3
import re


def _err(errors, path, msg):
    loc = "$" + "".join(f"[{repr(p)}]" if isinstance(p, str) else f"[{p}]" for p in path)
    errors.append(f"{loc}: {msg}")


def _resolve_ref(root_schema, ref):
    if not ref.startswith("#/"):
        raise ValueError(f"Unsupported $ref: {ref}")
    cur = root_schema
    for part in ref[2:].split("/"):
        cur = cur[part]
    return cur


def validate_instance(instance, schema, root_schema=None, path=None, errors=None):
    if root_schema is None:
        root_schema = schema
    if path is None:
        path = []
    if errors is None:
        errors = []

    if "$ref" in schema:
        return validate_instance(instance, _resolve_ref(root_schema, schema["$ref"]), root_schema, path, errors)

    if "const" in schema and instance != schema["const"]:
        _err(errors, path, f"expected const {schema['const']!r}, got {instance!r}")

    t = schema.get("type")
    if t == "object":
        if not isinstance(instance, dict):
            _err(errors, path, "expected object")
            return errors
        required = schema.get("required", [])
        for key in required:
            if key not in instance:
                _err(errors, path, f"missing required property {key!r}")
        props = schema.get("properties", {})
        additional = schema.get("additionalProperties", True)
        for key, value in instance.items():
            if key in props:
                validate_instance(value, props[key], root_schema, path + [key], errors)
            elif isinstance(additional, dict):
                validate_instance(value, additional, root_schema, path + [key], errors)
            elif additional is False:
                _err(errors, path + [key], "additional property not allowed")
    elif t == "string":
        if not isinstance(instance, str):
            _err(errors, path, "expected string")
            return errors
        min_len = schema.get("minLength")
        if min_len is not None and len(instance) < min_len:
            _err(errors, path, f"string shorter than minLength {min_len}")
        pat = schema.get("pattern")
        if pat and re.match(pat, instance) is None:
            _err(errors, path, f"string does not match pattern {pat!r}")
        if "enum" in schema and instance not in schema["enum"]:
            _err(errors, path, f"value {instance!r} not in enum {schema['enum']!r}")
    elif t is None:
        if "enum" in schema and instance not in schema["enum"]:
            _err(errors, path, f"value {instance!r} not in enum {schema['enum']!r}")
    else:
        raise ValueError(f"Unsupported schema type: {t}")

    return errors
