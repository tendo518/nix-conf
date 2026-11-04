"""Render a PLY mesh or point cloud to a PNG preview image."""

from __future__ import annotations

import argparse
import math
import os
import struct
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

TYPE_MAP = {
    "char": "i1", "int8": "i1", "uchar": "u1", "uint8": "u1",
    "short": "i2", "int16": "i2", "ushort": "u2", "uint16": "u2",
    "int": "i4", "int32": "i4", "uint": "u4", "uint32": "u4",
    "float": "f4", "float32": "f4", "double": "f8", "float64": "f8",
}


class PlyError(RuntimeError):
    pass


STRUCT_MAP = {
    "char": "b", "int8": "b", "uchar": "B", "uint8": "B",
    "short": "h", "int16": "h", "ushort": "H", "uint16": "H",
    "int": "i", "int32": "i", "uint": "I", "uint32": "I",
    "float": "f", "float32": "f", "double": "d", "float64": "d",
}


def struct_format(endian: str, type_name: str) -> str:
    fmt = STRUCT_MAP[type_name]
    return fmt if fmt in ("b", "B") else endian + fmt


def parse_header(data: bytes):
    pos = 0
    lines: list[str] = []
    while pos < len(data):
        end = data.find(b"\n", pos)
        if end < 0:
            end = len(data)
        line = data[pos:end].decode("ascii", "replace").rstrip("\r")
        pos = end + 1
        lines.append(line)
        if line.strip() == "end_header":
            break

    if not lines or lines[0].strip() != "ply":
        raise PlyError("not a PLY file")

    fmt = None
    elements: list[dict] = []
    current = None
    for raw in lines[1:]:
        parts = raw.strip().split()
        if not parts:
            continue
        key = parts[0]
        if key == "format":
            if len(parts) < 2 or parts[1] not in (
                "ascii", "binary_little_endian", "binary_big_endian"
            ):
                raise PlyError(f"unsupported PLY format: {raw}")
            fmt = parts[1]
        elif key == "element":
            if len(parts) < 3:
                raise PlyError(f"bad element line: {raw}")
            current = {"name": parts[1], "count": int(parts[2]), "props": []}
            elements.append(current)
        elif key == "property":
            if current is None:
                raise PlyError("property before element")
            if len(parts) >= 5 and parts[1] == "list":
                if parts[2] not in TYPE_MAP or parts[3] not in TYPE_MAP:
                    raise PlyError(f"unsupported list property: {raw}")
                current["props"].append({
                    "name": parts[4], "list": True,
                    "count_type": parts[2], "item_type": parts[3],
                })
            elif len(parts) >= 3:
                if parts[1] not in TYPE_MAP:
                    raise PlyError(f"unsupported property type: {raw}")
                current["props"].append({
                    "name": parts[2], "list": False, "type": parts[1],
                })
            else:
                raise PlyError(f"bad property line: {raw}")
    if fmt is None:
        raise PlyError("missing PLY format declaration")
    return fmt, elements, pos


def element_dtype(element: dict, endian: str):
    fields = []
    for prop in element["props"]:
        if prop["list"]:
            return None
        fields.append((prop["name"], endian + TYPE_MAP[prop["type"]]))
    return np.dtype(fields)


def parse_ascii(data: bytes, elements: list[dict]) -> dict[str, object]:
    tokens = data.split()
    cursor = 0
    result: dict[str, object] = {}

    def take() -> float:
        nonlocal cursor
        if cursor >= len(tokens):
            raise PlyError("unexpected end of ASCII PLY data")
        value = float(tokens[cursor])
        cursor += 1
        return value

    for element in elements:
        values: dict[str, list] = {p["name"]: [] for p in element["props"]}
        for _ in range(element["count"]):
            for prop in element["props"]:
                if prop["list"]:
                    count = int(take())
                    values[prop["name"]].append([int(take()) for _ in range(count)])
                else:
                    values[prop["name"]].append(take())
        result[element["name"]] = values
    return result


def parse_binary(data: bytes, offset: int, fmt: str, elements: list[dict]):
    endian = "<" if fmt == "binary_little_endian" else ">"
    result: dict[str, object] = {}

    for element in elements:
        dtype = element_dtype(element, endian)
        if dtype is not None:
            size = dtype.itemsize * element["count"]
            if offset + size > len(data):
                raise PlyError("unexpected end of binary PLY data")
            array = np.frombuffer(data, dtype=dtype, count=element["count"], offset=offset)
            offset += size
            result[element["name"]] = {name: array[name] for name in dtype.names}
            continue

        values: dict[str, list] = {p["name"]: [] for p in element["props"]}
        for _ in range(element["count"]):
            for prop in element["props"]:
                if prop["list"]:
                    count_fmt = struct_format(endian, prop["count_type"])
                    count_size = struct.calcsize(count_fmt)
                    if offset + count_size > len(data):
                        raise PlyError("unexpected end of binary PLY data")
                    count = int(struct.unpack_from(count_fmt, data, offset)[0])
                    offset += count_size

                    item_fmt = struct_format(endian, prop["item_type"])
                    item_size = struct.calcsize(item_fmt)
                    byte_count = count * item_size
                    if offset + byte_count > len(data):
                        raise PlyError("unexpected end of binary PLY data")
                    if count:
                        items = np.frombuffer(
                            data, dtype=item_fmt, count=count, offset=offset
                        ).tolist()
                    else:
                        items = []
                    offset += byte_count
                    values[prop["name"]].append([int(v) for v in items])
                else:
                    value_fmt = struct_format(endian, prop["type"])
                    value_size = struct.calcsize(value_fmt)
                    if offset + value_size > len(data):
                        raise PlyError("unexpected end of binary PLY data")
                    values[prop["name"]].append(
                        struct.unpack_from(value_fmt, data, offset)[0]
                    )
                    offset += value_size
        result[element["name"]] = values
    return result


def extract_geometry(elements: list[dict], values: dict[str, object]):
    vertices = None
    colors = None
    faces: list[np.ndarray] = []

    for element in elements:
        name = element["name"]
        mapping = values.get(name)
        if not isinstance(mapping, dict):
            continue

        if vertices is None:
            xyz_names = [n for n in ("x", "y", "z") if n in mapping]
            if len(xyz_names) != 3:
                scalar_names = [
                    p["name"] for p in element["props"] if not p["list"]
                ]
                if len(scalar_names) < 3:
                    continue
                xyz_names = scalar_names[:3]
            vertices = np.column_stack(
                [np.asarray(mapping[n], dtype=np.float64) for n in xyz_names]
            )

            for candidate in (
                ("red", "green", "blue"),
                ("r", "g", "b"),
                ("diffuse_red", "diffuse_green", "diffuse_blue"),
            ):
                if all(c in mapping for c in candidate):
                    colors = np.column_stack(
                        [np.asarray(mapping[c], dtype=np.float64) for c in candidate]
                    )
                    if colors.size and float(np.nanmax(colors)) <= 1.0:
                        colors *= 255.0
                    colors = np.clip(colors, 0, 255).astype(np.uint8)
                    break

        if name == "face" or "vertex" in name.lower():
            for prop in element["props"]:
                if not prop["list"]:
                    continue
                for face in mapping.get(prop["name"], []):
                    index = np.asarray(face, dtype=np.int64)
                    if index.size >= 3:
                        faces.append(index)

    if vertices is None or not len(vertices):
        raise PlyError("no vertices found")

    finite = np.isfinite(vertices).all(axis=1)
    if not finite.all():
        vertices = vertices.copy()
        vertices[~finite] = 0.0
    if colors is not None and len(colors) != len(vertices):
        colors = None
    return vertices, colors, faces


def triangulate(faces: list[np.ndarray]) -> np.ndarray:
    triangles: list[list[int]] = []
    for face in faces:
        for i in range(1, len(face) - 1):
            triangles.append([int(face[0]), int(face[i]), int(face[i + 1])])
    if not triangles:
        return np.empty((0, 3), dtype=np.int64)
    result = np.asarray(triangles, dtype=np.int64)
    valid = (result >= 0).all(axis=1)
    return result[valid]


def rasterize(
    width: int,
    height: int,
    vertices: np.ndarray,
    colors: np.ndarray | None,
    triangles: np.ndarray,
    yaw: float,
    pitch: float,
) -> Image.Image:
    extent = np.max(vertices.max(axis=0) - vertices.min(axis=0))
    if not np.isfinite(extent) or extent <= 0:
        extent = 1.0
    center = (vertices.max(axis=0) + vertices.min(axis=0)) * 0.5
    v = (vertices - center) / extent

    yaw_r = math.radians(yaw)
    pitch_r = math.radians(pitch)
    cy, sy = math.cos(yaw_r), math.sin(yaw_r)
    cp, sp = math.cos(pitch_r), math.sin(pitch_r)

    x = cy * v[:, 0] - sy * v[:, 1]
    y = sy * v[:, 0] + cy * v[:, 1]
    z = v[:, 2]
    xr = x
    yr = cp * y + sp * z
    zr = -sp * y + cp * z

    xy = np.column_stack((xr, yr))
    lo = xy.min(axis=0)
    hi = xy.max(axis=0)
    span = np.maximum(hi - lo, 1e-9)
    margin = 0.08
    fit = min(width * (1 - 2 * margin) / span[0], height * (1 - 2 * margin) / span[1])
    px = width * 0.5 + (xr - (lo[0] + hi[0]) * 0.5) * fit
    py = height * 0.5 - (yr - (lo[1] + hi[1]) * 0.5) * fit

    yy = np.arange(height, dtype=np.float32)[:, None]
    blend = yy / max(1, height - 1)
    top = np.array([15, 23, 42], dtype=np.float32)
    bottom = np.array([30, 41, 59], dtype=np.float32)
    background = top[None, None, :] * (1 - blend[:, :, None]) + bottom[None, None, :] * blend[:, :, None]
    image = np.repeat(background, width, axis=1).astype(np.uint8)
    zbuf = np.full((height, width), -np.inf, dtype=np.float32)

    if len(triangles):
        tri = triangles
        if len(tri) > 60000:
            keep = np.linspace(0, len(tri) - 1, 60000, dtype=np.int64)
            tri = tri[keep]

        p0 = np.column_stack((px[tri[:, 0]], py[tri[:, 0]], zr[tri[:, 0]]))
        p1 = np.column_stack((px[tri[:, 1]], py[tri[:, 1]], zr[tri[:, 1]]))
        p2 = np.column_stack((px[tri[:, 2]], py[tri[:, 2]], zr[tri[:, 2]]))

        cross = np.cross(p1 - p0, p2 - p0)
        norm = np.linalg.norm(cross, axis=1)
        valid = norm > 1e-9
        normals = np.zeros_like(cross)
        normals[valid] = cross[valid] / norm[valid, None]
        light = np.array([0.35, 0.55, 0.76], dtype=np.float32)
        light /= np.linalg.norm(light)
        shade = np.clip(0.22 + 0.78 * np.abs(normals @ light), 0.0, 1.0)

        if colors is None:
            base = np.array([76, 145, 225], dtype=np.float32)
            face_color = np.clip(base[None, :] * shade[:, None], 0, 255).astype(np.uint8)
        else:
            mean_color = colors[tri].astype(np.float32).mean(axis=1)
            face_color = np.clip(mean_color * shade[:, None], 0, 255).astype(np.uint8)

        for i in range(len(tri)):
            x0, y0, z0 = p0[i]
            x1, y1, z1 = p1[i]
            x2, y2, z2 = p2[i]
            minx = max(0, int(math.floor(min(x0, x1, x2))))
            maxx = min(width - 1, int(math.ceil(max(x0, x1, x2))))
            miny = max(0, int(math.floor(min(y0, y1, y2))))
            maxy = min(height - 1, int(math.ceil(max(y0, y1, y2))))
            if minx > maxx or miny > maxy:
                continue

            denom = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
            if abs(denom) < 1e-9:
                continue
            gx, gy = np.meshgrid(
                np.arange(minx, maxx + 1, dtype=np.float32) + 0.5,
                np.arange(miny, maxy + 1, dtype=np.float32) + 0.5,
            )
            w0 = ((y1 - y2) * (gx - x2) + (x2 - x1) * (gy - y2)) / denom
            w1 = ((y2 - y0) * (gx - x2) + (x0 - x2) * (gy - y2)) / denom
            w2 = 1.0 - w0 - w1
            inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
            if not inside.any():
                continue
            depth = w0 * z0 + w1 * z1 + w2 * z2
            depth_mask = inside & (depth > zbuf[miny : maxy + 1, minx : maxx + 1])
            if not depth_mask.any():
                continue
            zbuf[miny : maxy + 1, minx : maxx + 1][depth_mask] = depth[depth_mask]
            sub_image = image[miny : maxy + 1, minx : maxx + 1]
            sub_image[depth_mask] = face_color[i]

    else:
        order = np.argsort(zr)
        radius = max(1, min(width, height) // 240)
        pil = Image.fromarray(image)
        draw = ImageDraw.Draw(pil)
        point_color = (96, 165, 250)
        for i in order:
            x = int(round(px[i]))
            y = int(round(py[i]))
            if 0 <= x < width and 0 <= y < height:
                color = tuple(int(c) for c in colors[i]) if colors is not None else point_color
                draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
        image = np.asarray(pil).copy()

    img = Image.fromarray(image)
    label = f"{len(vertices):,} vertices"
    if len(triangles):
        label += f"  |  {len(triangles):,} triangles"
    label += f"  |  yaw {int(round(yaw)) % 360} deg"
    ImageDraw.Draw(img).text((10, 8), label, fill=(203, 213, 225))
    return img


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--width", type=int, default=1000)
    parser.add_argument("--height", type=int, default=800)
    parser.add_argument("--yaw", type=float, default=35.0)
    parser.add_argument("--pitch", type=float, default=65.0)
    args = parser.parse_args()

    width = max(64, min(args.width, 1800))
    height = max(64, min(args.height, 1400))

    try:
        data = args.input.read_bytes()
        fmt, elements, offset = parse_header(data)
        if fmt == "ascii":
            values = parse_ascii(data[offset:], elements)
        else:
            values = parse_binary(data, offset, fmt, elements)
        vertices, colors, faces = extract_geometry(elements, values)
        triangles = triangulate(faces)
        image = rasterize(
            width, height, vertices, colors, triangles, args.yaw, args.pitch
        )

        args.output.parent.mkdir(parents=True, exist_ok=True)
        fd, temp_name = tempfile.mkstemp(
            prefix=".ply-preview-", suffix=".png", dir=str(args.output.parent)
        )
        os.close(fd)
        try:
            image.save(temp_name, format="PNG", optimize=True)
            os.replace(temp_name, args.output)
        finally:
            try:
                os.unlink(temp_name)
            except FileNotFoundError:
                pass
    except Exception as exc:
        print(f"ply-preview: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
