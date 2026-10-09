#!/usr/bin/env python3
"""Back up and restore the semantic (LLM-extracted) layer of a repo graph.

Why this exists
---------------
graphify stores its extraction cache *inside* ``graphify-out/cache/``. If that
directory is lost — deleted by hand, or removed because it was a stale shared
symlink — both the graph and its semantic cache go with it. ``graphify update``
is AST-only, so the rebuilt graph comes back with zero semantic nodes and the
only way to recover them is a fresh (expensive) LLM extraction pass.

Semantic nodes are the costly part of the graph, so they are mirrored outside
``graphify-out`` to ``~/.graphify/semantic-backup/<repo>.json`` after every
successful build, and restored automatically when a graph comes back without
them. AST nodes are deliberately not backed up: they rebuild deterministically
from source in seconds.

Semantic nodes are distinguished from AST nodes by the absence of the
``_origin`` attribute, which graphify sets only on AST-extracted nodes.

Usage:
    graphify_semantic_backup.py save    <repo_dir>
    graphify_semantic_backup.py restore <repo_dir>
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

BACKUP_ROOT = Path.home() / ".graphify" / "semantic-backup"


def _graph_path(repo: Path) -> Path:
    return repo / "graphify-out" / "graph.json"


def _split(nodes: list[dict]) -> tuple[list[dict], list[dict]]:
    """Return (ast_nodes, semantic_nodes)."""
    ast = [n for n in nodes if "_origin" in n]
    semantic = [n for n in nodes if "_origin" not in n]
    return ast, semantic


def _load(path: Path) -> dict | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _write_atomic(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    tmp.replace(path)


def save(repo: Path) -> int:
    graph = _load(_graph_path(repo))
    if not graph:
        return 0
    _, semantic = _split(graph.get("nodes", []))
    if not semantic:
        # Never overwrite a good backup with an empty one.
        return 0

    sem_ids = {n["id"] for n in semantic}
    links = [
        e
        for e in graph.get("links", [])
        if e.get("source") in sem_ids or e.get("target") in sem_ids
    ]
    # Hyperedges are produced only by semantic extraction, so all of them
    # belong to the semantic layer and must be mirrored too.
    hyperedges = graph.get("hyperedges", [])

    _write_atomic(
        BACKUP_ROOT / f"{repo.name}.json",
        {
            "repo": repo.name,
            "nodes": semantic,
            "links": links,
            "hyperedges": hyperedges,
        },
    )
    return len(semantic)


def restore(repo: Path) -> int:
    graph_path = _graph_path(repo)
    graph = _load(graph_path)
    if not graph:
        return 0
    _, semantic = _split(graph.get("nodes", []))
    if semantic and graph.get("hyperedges"):
        return 0  # graph still has its semantic layer; nothing to do

    backup = _load(BACKUP_ROOT / f"{repo.name}.json")
    if not backup or not backup.get("nodes"):
        return 0

    existing = {n["id"] for n in graph.get("nodes", [])}
    added = [n for n in backup["nodes"] if n["id"] not in existing]

    if not added and graph.get("hyperedges"):
        return 0

    graph["nodes"].extend(added)

    # Only re-attach edges whose endpoints both exist, so the graph stays valid.
    ids = existing | {n["id"] for n in added}
    seen = {
        (e.get("source"), e.get("target"), e.get("relation"))
        for e in graph.get("links", [])
    }
    for e in backup.get("links", []):
        key = (e.get("source"), e.get("target"), e.get("relation"))
        if e.get("source") in ids and e.get("target") in ids and key not in seen:
            graph.setdefault("links", []).append(e)
            seen.add(key)

    if not graph.get("hyperedges") and backup.get("hyperedges"):
        graph["hyperedges"] = backup["hyperedges"]

    _write_atomic(graph_path, graph)
    return len(added)


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in ("save", "restore"):
        print(__doc__, file=sys.stderr)
        return 2

    action, repo = sys.argv[1], Path(sys.argv[2]).resolve()
    count = save(repo) if action == "save" else restore(repo)

    if action == "save" and count:
        print(f"semantic backup: {count} nodes saved for {repo.name}")
    elif action == "restore" and count:
        print(f"semantic restore: {count} nodes recovered for {repo.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
