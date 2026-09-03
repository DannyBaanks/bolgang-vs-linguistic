"""P02 semantic-graph reducer. Derives the canonical semantic process graph
mechanically from normalized P02 traces.

Rules:
- node id = semantic operation name (deterministic, no object IDs)
- edge = observed adjacency (op -> next op) within ONE case trace
- frequency = count of events with that operation across ALL traces
- same operation may be exercised by multiple cases; frequencies, inputs are
  aggregated over the union of traces.
- nothing is fabricated; if an edge isn't in a trace, it isn't in the graph.

Also emits source_map.json + data_dependencies.json with pinned sha256.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256_file(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def load_json(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


# --- Static source-provenance mapping (frozen upstream semantics) ------------
# Each semantic operation is mapped to the upstream source file(s) that
# implement it, and to the frozen immutable data files it consults.
#
# Provenance is grounded in the P00/P01 frozen upstream checkout content.
# Hashes are computed at build time against the mounted checkout directory.

def build_source_map(upstream: Path, operations: list[dict]) -> list[dict]:
    rows = []

    def rec(op_name, files, methods, why):
        fmeta = []
        for rel in files:
            p = upstream / rel
            entry = {"relative_path": rel}
            entry["sha256"] = sha256_file(p) if p.is_file() else None
            fmeta.append(entry)
        rows.append({
            "semantic_operation": op_name,
            "upstream_relative_files": fmeta,
            "methods_or_constants": methods,
            "why_this_source_maps_to_the_operation": why,
        })

    for op in operations:
        opname = op["id"]
        if opname in (
            "detect.started", "detect.terminal",
        ):
            rec(opname, ["lib/linguist.rb"], ["Linguist.detect",
                "STRATEGIES"], "Top-level detection entry/exit; the ordered strategy list drives candidate refinement.")

        elif opname in (
            "strategy.modeline", "strategy.modeline.result",
        ):
            rec(opname, ["lib/linguist/strategy/modeline.rb",
                         "lib/linguist/language.rb"],
                ["Linguist::Strategy::Modeline.call",
                 "Language.find_by_alias", "Language.alias_index"],
                "Modeline strategy consults the alias index from languages.yml.")

        elif opname in ("strategy.filename", "strategy.filename.result"):
            rec(opname, ["lib/linguist/strategy/filename.rb",
                         "lib/linguist/language.rb"],
                ["Linguist::Strategy::Filename.call",
                 "Language.find_by_filename", "Language.filename_index"],
                "Filename strategy consults the filename index from languages.yml.")

        elif opname in ("strategy.shebang", "strategy.shebang.result"):
            rec(opname, ["lib/linguist/shebang.rb",
                         "lib/linguist/language.rb"],
                ["Linguist::Shebang.call", "Language.find_by_interpreter",
                 "Language.interpreter_index"],
                "Shebang strategy reads the first line and consults the interpreter index from languages.yml.")

        elif opname in ("strategy.extension", "strategy.extension.result"):
            rec(opname, ["lib/linguist/strategy/extension.rb",
                         "lib/linguist/language.rb"],
                ["Linguist::Strategy::Extension.call",
                 "Language.find_by_extension", "Language.extension_index"],
                "Extension strategy consults the extension index from languages.yml, skipping generic.yml-listed extensions.")

        elif opname in ("strategy.xml", "strategy.xml.result"):
            rec(opname, ["lib/linguist/strategy/xml.rb"],
                ["Linguist::Strategy::XML.call"],
                "XML strategy checks the first two lines for the XML declaration.")

        elif opname in ("strategy.manpage", "strategy.manpage.result"):
            rec(opname, ["lib/linguist/strategy/manpage.rb"],
                ["Linguist::Strategy::Manpage.call", "MANPAGE_EXTS"],
                "Manpage strategy matches numeric-sectioned extensions (man/mdco etc.).")

        elif opname in ("heuristics.call", "heuristics.call.result"):
            rec(opname, ["lib/linguist/heuristics.rb",
                         "lib/linguist/language.rb"],
                ["Linguist::Heuristics.call", "Heuristics.load",
                 "Heuristics#matches?", "Heuristics#call"],
                "Heuristics disambiguate candidates by matching herlper patterns (from heuristics.yml) against content.")

        elif opname in ("classifier.call", "classifier.call.result"):
            rec(opname, ["lib/linguist/classifier.rb",
                         "lib/linguist/samples.rb",
                         "lib/linguist/yaml_serializer.rb"] if (upstream / "lib/linguist/yaml_serializer.rb").is_file() else ["lib/linguist/classifier.rb", "lib/linguist/samples.rb"],
                ["Linguist::Classifier.call", "Classifier.classify",
                 "Samples.cache", "Samples.load_samples"],
                "Classifier is a trained-tag centroid model over sample tokens. Uses the cached samples matrix already trained upstream.")

        elif opname in ("flag.binary_check",):
            rec(opname, ["lib/linguist/blob_helper.rb"],
                ["BlobHelper#binary?", "BlobHelper#likely_binary?"],
                "Flags a blob as binary so detect can short-circuit without matching any strategy.")

        elif opname in ("flag.vendored",):
            rec(opname, ["lib/linguist/blob_helper.rb"],
                ["BlobHelper#vendored?"],
                "Vendored classification by path regexp matching.")

        elif opname in ("flag.generated",):
            rec(opname, ["lib/linguist/generated.rb"],
                ["CG Instances", "Generated#generated?",
                 "Generated#generated_go?", "generated_parser?",
                 "generated_postscript?", "generated_protocol_buffer",
                 "generated_by_zephir?", "generated_net_docfile?"],
                "Generated classification by marker/rule checks.")

        elif opname in ("flag.documentation",):
            rec(opname, ["lib/linguist/blob_helper.rb"],
                ["BlobHelper#documentation?"],
                "Documentation classification by path regexp.")

        elif opname in ("repo.include_in_language_stats",):
            rec(opname, ["lib/linguist/blob_helper.rb"],
                ["BlobHelper#include_in_language_stats?"],
                "Per-blob inclusion test used by repository aggregation.")

        elif opname in ("repo.languages_aggregate", "repo.breakdown_by_file"):
            rec(opname, ["lib/linguist/repository.rb"],
                ["Linguist::Repository#languages", "Repository#compute_stats",
                 "Repository#breakdown_by_file"],
                "Repository aggregation walks the git tree and updates per-language byte counts.")

        elif opname.startswith("metadata.find_by_") or opname.startswith("metadata.language_lookup"):
            rec(opname, ["lib/linguist/language.rb"],
                ["Language.find_by_alias", "Language.find_by_filename",
                 "Language.find_by_extension", "Language.find_by_interpreter",
                 "Language.alias_index", "Language.filename_index",
                 "Language.extension_index", "Language.interpreter_index"],
                "Language metadata lookups consult the frozen languages.yml index.")

        else:
            # Unknown op: record it honestly, with no provenance mapping.
            rec(opname, [], [], "No provenance mapped (review needed).")

    return rows


def build_data_deps(upstream: Path) -> list[dict]:
    rows = []
    for rel in [
        "lib/linguist/languages.yml",
        "lib/linguist/heuristics.yml",
        "lib/linguist/vendor.yml",
        "lib/linguist/documentation.yml",
        "lib/linguist/generic.yml",
        "lib/linguist/generated.rb",
        "lib/linguist/samples_data.rb",
        "lib/linguist/language.rb",
        "lib/linguist.rb",
    ]:
        p = upstream / rel
        rows.append({
            "name": rel,
            "sha256": sha256_file(p) if p.is_file() else None,
            "role": (
                "language metadata (names/extensions/filenames/aliases/interpreters)" if "languages" in rel else
                "content heuristics disambiguation rules" if "heuristics" in rel else
                "vendored path patterns" if "vendor" in rel else
                "documentation path patterns" if "documentation" in rel else
                "generic extensions (skipped by extension strategy)" if "generic" in rel else
                "generated-content rules" if "generated" in rel else
                "trained classifier samples matrix" if "samples_data" in rel else
                "language index construction + lookup surface" if "language.rb" in rel else
                "top-level detection entry and STRATEGIES" if rel == "lib/linguist.rb" else "data"
            ),
        })
    return rows


def resolve_path(arg: str) -> Path:
    return Path(arg)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--traces", required=True)
    ap.add_argument("--upstream", required=True,
                    help="Path to the frozen upstream Linguist checkout")
    ap.add_argument("--out", required=True)
    ap.add_argument("--source-map-out", required=True)
    ap.add_argument("--deps-out", required=True)
    args = ap.parse_args()

    traces_doc = load_json(Path(args.traces))
    upstream = Path(args.upstream)
    if not upstream.is_dir():
        raise FileNotFoundError(f"upstream not found: {upstream}")

    cases = traces_doc["traces"]

    # Aggregate operations.
    op_arena: dict[str, dict] = {}

    def touch(op_name: str):
        node = op_arena.get(op_name)
        if node is None:
            node = {
                "id": op_name,
                "semantic_operation": op_name,
                "required_inputs": set(),
                "state_reads": set(),
                "state_writes": set(),
                "immutable_data_dependencies": set(),
                "successors": set(),
                "cases_observed_in": set(),
                "observed_frequency": 0,
            }
            op_arena[op_name] = node
        return node

    edge_counts: dict[str, int] = {}
    # "successors" of op A = op names that directly follow it in ANY case trace.

    for case in cases:
        events = case["events"]
        prev_op = None
        for ev in events:
            op_name = ev["operation"]
            node = touch(op_name)
            node["cases_observed_in"].add(case["case_id"])
            node["observed_frequency"] += 1

            if isinstance(ev.get("inputs"), dict):
                for k in ev["inputs"].keys():
                    node["required_inputs"].add(k)
            for item in ev.get("state_read", []):
                node["state_reads"].add(item)
            for item in ev.get("state_write", []):
                node["state_writes"].add(item)
            for item in ev.get("data_dependencies", []):
                node["immutable_data_dependencies"].add(item)

            if prev_op is not None and prev_op != op_name:
                edge_key = f"{prev_op} -> {op_name}"
                edge_counts[edge_key] = edge_counts.get(edge_key, 0) + 1
                op_arena[prev_op]["successors"].add(op_name)
            prev_op = op_name

    # Ops closure — materialize as canonical rows.
    operations = []
    for op_name in sorted(op_arena.keys()):
        node = op_arena[op_name]
        operations.append({
            "id": node["id"],
            "semantic_operation": node["semantic_operation"],
            "required_inputs": sorted(node["required_inputs"]),
            "state_reads": sorted(node["state_reads"]),
            "state_writes": sorted(node["state_writes"]),
            "immutable_data_dependencies": sorted(node["immutable_data_dependencies"]),
            "successors": sorted(node["successors"]),
            "observed_frequency": node["observed_frequency"],
            "cases_observed_in": sorted(node["cases_observed_in"]),
        })

    # Derive edges in canonical form.
    edges = []
    for edge_key in sorted(edge_counts.keys()):
        a, b = edge_key.split(" -> ", 1)
        edges.append({"from": a, "to": b, "count": edge_counts[edge_key]})

    graph = {
        "schema": "p02-semantic-graph/1",
        "counting_unit": "one trace event entry (one wrapped upstream call frame, one fixture invocation)",
        "operations": operations,
        "edges": edges,
        "cases_traced": len(cases),
        "note": "Node frequency equals the number of trace events carrying that operation across the run; graph edges only exist where a trace took that transition.",
    }

    sm = build_source_map(upstream, operations)
    deps = build_data_deps(upstream)

    with open(args.out, "w", encoding="utf-8", newline="\n") as f:
        json.dump(graph, f, indent=1, ensure_ascii=False, sort_keys=True)
        f.write("\n")

    with open(args.source_map_out, "w", encoding="utf-8", newline="\n") as f:
        json.dump({
            "schema": "p02-source-map/1",
            "rows": sort_rows(sm),
        }, f, indent=1, ensure_ascii=False, sort_keys=True)
        f.write("\n")

    with open(args.deps_out, "w", encoding="utf-8", newline="\n") as f:
        json.dump({
            "schema": "p02-data-dependencies/1",
            "rows": deps,
        }, f, indent=1, ensure_ascii=False, sort_keys=True)
        f.write("\n")

    print(json.dumps({
        "operations": len(operations),
        "edges": len(edges),
        "source_rows": len(sm),
        "deps_rows": len(deps),
    }))


def sort_rows(rows: list[dict]) -> list[dict]:
    return sorted(rows, key=lambda r: r.get("semantic_operation", ""))


if __name__ == "__main__":
    main()