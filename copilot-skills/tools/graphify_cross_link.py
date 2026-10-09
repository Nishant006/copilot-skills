#!/usr/bin/env python3
"""Add cross-repository edges to the graphify global graph.

`graphify global add` namespaces every node id as ``<repo>::<local_id>``, which
places each project side by side in one file but leaves them unconnected. This
tool adds the missing edges so the global graph answers "how do these services
talk to each other?".

Linking policy
--------------
Two nodes in *different* repos are linked when they share a normalised label and
that label is a credible integration point:

HIGH   (score 0.95) - true runtime integration: Kafka topics, Service Bus
       queues/subscriptions, Mongo collections, external vendors, and shared
       message/event contracts.
MEDIUM (score 0.75) - a domain type duplicated across repos: a shared contract
       shape, not necessarily a runtime link.
LOW    - excluded. Framework boilerplate and generic schema keys share a name by
       coincidence; linking them produces a hairball, not information.

Idempotency
-----------
Every edge written here carries ``_cross_link: true``. The tool strips all such
edges before recomputing, so running it repeatedly converges on the same result
and never duplicates. It only ever adds edges - nodes are left untouched.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

DEFAULT_GLOBAL_GRAPH = Path.home() / ".graphify" / "global-graph.json"

CROSS_LINK_FLAG = "_cross_link"
RELATION = "shares_data_with"

HIGH_SCORE = 0.95
MEDIUM_SCORE = 0.75

# Max distinct nodes a label may have inside one repo before it is treated as
# generic. A real topic or contract appears once or twice per repo; a generic
# token appears everywhere.
MAX_NODES_PER_REPO = 5

MIN_LABEL_LENGTH = 5

# Generic structural/schema/config keys. Shared by coincidence of format.
GENERIC_LABELS = {
    "name", "type", "title", "version", "info", "description", "summary",
    "properties", "payload", "message", "messages", "channels", "components",
    "subscribe", "publish", "operationid", "contenttype", "schema", "schemas",
    "format", "value", "values", "key", "keys", "data", "status", "code",
    "error", "errors", "result", "results", "items", "item", "list", "map",
    "config", "configuration", "settings", "options", "params", "parameters",
    "request", "response", "headers", "header", "body", "url", "uri", "path",
    "id", "ids", "enabled", "disabled", "default", "defaults", "spec",
    "metadata", "labels", "annotations", "env", "image", "port", "ports",
    "host", "hosts", "replicas", "resources", "limits", "requests", "service",
    "services", "app", "apps", "namespace", "cluster", "context", "event",
    "events", "string", "integer", "boolean", "number", "object", "array",
    "null", "true", "false", "ref", "state", "json", "yaml", "yml", "asyncapi",
    "openapi", "storeid", "messageid", "specversion", "lastsyncedsha",
    "lastsyncedat", "lastsyncedpr", "lastsyncedby", "builder", "test", "tests",
    "main", "util", "utils", "common", "core", "base", "abstract", "impl",
    "additionalproperties", "traceid", "externalid", "receivedat",
    "lastmodifieddate", "createddate", "updatedat", "createdat",
}

# Test fixtures duplicate production type names across repos but describe no
# integration. Matched against the normalised label.
TEST_LABEL_PATTERN = re.compile(r"(test|tests|testcase|itcase|spec|mock|stub|fixture)$")


# Spring / infrastructure boilerplate. Same class name in several repos means
# the same framework was used, not that the services are connected.
FRAMEWORK_LABELS = {
    "mongoconfig", "redisconfig", "kafkaconfig", "kafkatemplate",
    "mongotemplate", "redistemplate", "resttemplate", "webclient",
    "objectmapper", "kafkaproducer", "kafkaconsumer", "producerfactory",
    "consumerfactory", "cachemanager", "rediscachemanager", "securityconfig",
    "swaggerconfig", "openapiconfig", "webconfig", "appconfig", "beanconfig",
    "asyncconfig", "schedulerconfig", "circuitbreakerconfig", "retryconfig",
    "exceptionhandler", "globalexceptionhandler", "controlleradvice",
    "healthcheck", "healthindicator", "application", "applicationtests",
    "constants", "constant", "enums", "enum", "mapper", "mappers", "converter",
    "validator", "interceptor", "filter", "logger", "loggingaspect",
    "servicebusconfig", "threadpoolconfig", "executorconfig", "jacksonconfig",
    "mavenwrapperdownloader", "applicationtest", "basetest", "testutil",
    "testutils", "testconfig", "testcontainer", "swagger", "springapplication",
}

# HIGH-confidence integration vocabulary, matched against the raw label.
HIGH_SIGNAL_PATTERN = re.compile(
    r"(kafka[-_]?topic|[-_]topic[-_]|topic[-_]name|servicebus|service[-_]bus"
    r"|queue|subscription|\bdlq\b|dead[-_]?letter"
    r"|braze|infobip|alecto"
    r"|collection"
    r"|envelope|webhook)",
    re.IGNORECASE,
)

# Shared cross-service contract types (message/event payloads crossing a wire).
CONTRACT_SUFFIX_PATTERN = re.compile(
    r"(message|envelope|eventpayload|eventdto|notificationdto|requestdto"
    r"|responsedto|commanddto|payload)$",
    re.IGNORECASE,
)

# MEDIUM: a domain type duplicated across repos.
MEDIUM_SUFFIX_PATTERN = re.compile(
    r"(dto|entity|document|record|model|contract|event|request|response|log)$",
    re.IGNORECASE,
)


def normalise(label: str) -> str:
    """Reduce a label to a comparison key: lowercase alphanumerics only."""
    return re.sub(r"[^a-z0-9]", "", label.lower())


def is_structural_label(label: str) -> bool:
    """True for labels that duplicate another node rather than name a concept.

    Method labels (``.send()``) and file labels (``Foo.java``) mirror a class or
    module node that is already indexed, so linking them doubles every edge for
    no extra information.
    """
    stripped = label.strip()
    if stripped.startswith(".") or stripped.endswith("()"):
        return True
    return bool(re.search(r"\.(java|kt|py|ts|js|go|json|ya?ml|md|xml|sql)$", stripped, re.I))


def classify(label: str, norm: str) -> str | None:
    """Return 'HIGH', 'MEDIUM', or None if the label must not be linked."""
    if len(norm) < MIN_LABEL_LENGTH:
        return None
    if norm in GENERIC_LABELS or norm in FRAMEWORK_LABELS:
        return None
    if is_structural_label(label):
        return None
    if TEST_LABEL_PATTERN.search(norm):
        return None

    # HIGH is vocabulary-driven, so it accepts kebab-case infrastructure names
    # such as `communication-topic-low` as well as PascalCase contract types.
    if HIGH_SIGNAL_PATTERN.search(label) or CONTRACT_SUFFIX_PATTERN.search(norm):
        return "HIGH"

    # MEDIUM must name a *type*, not a field. A POJO/JSON field such as
    # `traceId` or `campaignId` appears in every service and carries no
    # integration meaning, so require a PascalCase identifier.
    if not label[:1].isupper():
        return None
    if MEDIUM_SUFFIX_PATTERN.search(norm):
        return "MEDIUM"
    if re.search(r"[a-z][A-Z]", label):
        return "MEDIUM"
    return None



def pick_representative(nodes: list[dict]) -> dict:
    """Choose one node per (label, repo) to carry the cross-repo edge.

    Prefers a concept/doc node (the semantic layer describes intent) and then
    the shortest source path, which tends to be the canonical definition rather
    than a test or nested variant.
    """
    def sort_key(node: dict) -> tuple:
        file_type = node.get("file_type", "")
        semantic_rank = 0 if file_type in {"concept", "rationale", "document"} else 1
        source = node.get("source_file") or ""
        is_test = 1 if re.search(r"(^|/)test", source, re.I) else 0
        return (is_test, semantic_rank, len(source), node.get("id", ""))

    return sorted(nodes, key=sort_key)[0]


def build_links(nodes: list[dict], policy: str) -> list[dict]:
    """Compute cross-repo edges for the given policy ('high_only'|'high_medium'|'all')."""
    buckets: dict[str, dict[str, list[dict]]] = defaultdict(lambda: defaultdict(list))
    labels: dict[str, str] = {}

    for node in nodes:
        repo = node.get("repo")
        label = (node.get("label") or "").strip()
        if not repo or not label:
            continue
        # External stubs (JDK/Spring types such as RuntimeException or
        # Serializable) are referenced but never defined in any repo, so they
        # carry no source_file. `graphify global add` collapses them onto
        # whichever repo merges first, which would otherwise mis-attribute a
        # cross-repo link to a repo that does not own the symbol.
        if not (node.get("source_file") or "").strip():
            continue
        norm = normalise(label)
        if not norm:
            continue
        buckets[norm][repo].append(node)
        labels.setdefault(norm, label)

    allowed = {"HIGH"}
    if policy in {"high_medium", "all"}:
        allowed.add("MEDIUM")

    links: list[dict] = []
    seen_pairs: set[tuple[str, str]] = set()

    for norm, per_repo in buckets.items():
        if len(per_repo) < 2:
            continue
        if any(len(group) > MAX_NODES_PER_REPO for group in per_repo.values()):
            continue

        label = labels[norm]
        tier = classify(label, norm)
        if tier is None and policy == "all":
            tier = "MEDIUM"
        if tier not in allowed:
            continue

        score = HIGH_SCORE if tier == "HIGH" else MEDIUM_SCORE
        reps = {repo: pick_representative(group) for repo, group in per_repo.items()}
        ordered = sorted(reps.items())

        for i in range(len(ordered)):
            for j in range(i + 1, len(ordered)):
                source = ordered[i][1]["id"]
                target = ordered[j][1]["id"]
                pair = (source, target) if source < target else (target, source)
                if pair in seen_pairs:
                    continue
                seen_pairs.add(pair)
                links.append({
                    "source": pair[0],
                    "target": pair[1],
                    "relation": RELATION,
                    "confidence": "INFERRED",
                    "confidence_score": score,
                    "weight": score,
                    "source_file": None,
                    "source_location": None,
                    CROSS_LINK_FLAG: True,
                    "link_basis": label,
                    "link_tier": tier,
                })

    return links


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--graph", type=Path, default=DEFAULT_GLOBAL_GRAPH,
                        help="path to global-graph.json")
    parser.add_argument("--policy", choices=["high_only", "high_medium", "all"],
                        default="high_medium", help="link policy tier")
    parser.add_argument("--dry-run", action="store_true",
                        help="report what would change without writing")
    args = parser.parse_args()

    if not args.graph.exists():
        print(f"cross-link: no global graph at {args.graph} - nothing to do.")
        return 0

    graph = json.loads(args.graph.read_text(encoding="utf-8"))
    nodes = graph.get("nodes", [])
    key = "links" if "links" in graph else "edges"
    links = graph.get(key, [])

    repos = {n.get("repo") for n in nodes if n.get("repo")}
    if len(repos) < 2:
        print(f"cross-link: only {len(repos)} repo(s) in global graph - nothing to link.")
        return 0

    kept = [e for e in links if not e.get(CROSS_LINK_FLAG)]
    removed = len(links) - len(kept)

    new_links = build_links(nodes, args.policy)

    # Never shadow a real extracted edge with an inferred one.
    existing = {
        (e["source"], e["target"]) if e["source"] < e["target"]
        else (e["target"], e["source"])
        for e in kept
        if e.get("source") and e.get("target")
    }
    new_links = [e for e in new_links if (e["source"], e["target"]) not in existing]

    tiers: dict[str, int] = defaultdict(int)
    for e in new_links:
        tiers[e["link_tier"]] += 1

    print(
        f"cross-link: {len(repos)} repos | removed {removed} stale | "
        f"added {len(new_links)} ({tiers['HIGH']} HIGH, {tiers['MEDIUM']} MEDIUM) "
        f"| policy={args.policy}"
    )

    if args.dry_run:
        for e in sorted(new_links, key=lambda x: (x["link_tier"], x["link_basis"]))[:30]:
            print(f"   [{e['link_tier']:<6}] {e['link_basis'][:40]:<42} "
                  f"{e['source'].split('::')[0]} <-> {e['target'].split('::')[0]}")
        return 0

    graph[key] = kept + new_links
    tmp = args.graph.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(graph, ensure_ascii=False), encoding="utf-8")
    tmp.replace(args.graph)
    return 0


if __name__ == "__main__":
    sys.exit(main())
