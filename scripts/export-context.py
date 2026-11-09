#!/usr/bin/env python3
"""Build a portable development context from an explicit public-document list."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys


APP = Path(__file__).resolve().parent.parent
SOURCES = {
    "app": (
        "docs/system/status.md", "docs/system/handoff.md", "AGENTS.md",
        "docs/product.md", "docs/system/policies.md", "docs/system/architecture.md",
        "docs/system/plan.md", "docs/ai/workflow.md", "docs/ai/task-template.md",
        "docs/repository-plan.md", "docs/decisions/001-foundation.md",
        "docs/design/calendar-first.md", "docs/api/contract-reference.json",
    ),
    "backend": (
        "AGENTS.md", "README.md", "docs/local-development.md",
        "contracts/README.md", "contracts/implementation.md", "contracts/openapi.yaml",
        "docs/pipeline.md", "docs/query-policy.md", "docs/reviewed-publish.md", "docs/backend-architecture.md", "docs/ott-candidates.md", "docs/decisions/README.md",
        "docs/reviews/2026-11-09-contract-review.md", "docs/data-source-assessment.md",
        "docs/research/2026-11-09-ott-feasibility.md", "docs/research/2026-11-09-ott-access.json",
    ),
    "verifier": (
        "AGENTS.md", "README.md", "requirements/README.md",
        "docs/contracts/reference.json", "docs/learning/README.md",
        "docs/evidence-v2.md", "docs/runner.md", "requirements/proposals/vfy-01-observation-map.md",
        "reviews/2026-11-09-local-runner.md",
    ),
}
DOCUMENT_DIRS = {
    "app": ("docs/ai/tasks",),
    "backend": ("docs/tasks", "docs/decisions"),
    "verifier": ("docs/tasks",),
}
COMMON = ("architecture.md", "plan.md", "policies.md", "status.md", "handoff.md")
MARKER = "<!-- context-manifest\n"
END = "\n-->"


def git(root, *args):
    return subprocess.check_output(
        ["git", "-C", str(root), *args], text=True, stderr=subprocess.PIPE
    ).strip()


def read_source(root, relative):
    source = root / relative
    # A document symlink must not pull unrelated local files into the export.
    source.resolve(strict=True).relative_to(root.resolve(strict=True))
    return source.read_bytes()


def snapshot(roots):
    for name in COMMON:
        relative = "docs/system/" + name
        canonical = read_source(roots["app"], relative)
        for label in ("backend", "verifier"):
            if read_source(roots[label], relative) != canonical:
                raise ValueError("공통 문서 사본 불일치: " + label + "/" + relative)
    repos, documents, sections = {}, [], []
    for label, paths in SOURCES.items():
        root = roots[label]
        if Path(git(root, "rev-parse", "--show-toplevel")).resolve() != root.resolve():
            raise ValueError("저장소 루트가 아님: " + label)
        repos[label] = {
            "head": git(root, "rev-parse", "HEAD"),
            "branch": git(root, "branch", "--show-current"),
            "status": git(root, "status", "--porcelain=v1", "--untracked-files=normal"),
        }
        # Only direct Markdown children of these public record directories.
        records = sorted({str(path.relative_to(root))
                          for directory in DOCUMENT_DIRS[label]
                          for path in (root / directory).glob("*.md")})
        for relative in dict.fromkeys((*paths, *records)):
            data = read_source(root, relative)
            digest = hashlib.sha256(data).hexdigest()
            name = root.name + "/" + relative
            documents.append({"path": name, "sha256": digest})
            # Fence embedded files so local headings/comments cannot alter the manifest.
            content = data.decode("utf-8")
            fence = "`" * max(4, max((len(s) for s in content.split() if set(s) == {"`"}), default=0) + 1)
            sections.append("## " + name + "\n\nSHA-256: `" + digest + "`\n\n"
                            + fence + "text\n" + content.rstrip() + "\n" + fence + "\n")
    return {"format": 1, "repositories": repos, "sources": documents}, sections


def render(manifest, sections, generated_at):
    manifest = dict(manifest, generatedAt=generated_at)
    header = (
        "# GODIEOR · ChatGPT 웹 개발 맥락 전달본\n\n"
        "생성 시각(UTC): " + generated_at + "\n\n"
        "구현·설계 대화용이다. 독립 reviewer에게 이 전달본을 제공하지 않는다.\n"
        "첫 출처인 status.md부터 읽고 확정/제안/미정, 가상/실제, 작성자 실행/독립 검증을 구분한다.\n"
        "대화 전체·제품 코드 전체·비밀·실시간 상태는 포함하지 않는다. 포함하지 않은 링크를 읽었다고 가정하지 않는다.\n"
        "상대 링크는 원래 저장소 기준이며, 포함된 출처는 아래 파일명으로 찾는다.\n"
        "현재 checkout의 파일을 묶었다. dirty가 있으면 HEAD의 내용과 다를 수 있다.\n"
        "웹 논의는 로컬을 자동 갱신하지 않는다. 변경 제안·사용자 결정을 작업 카드로 돌려준다.\n\n"
    )
    table = ["| 저장소 | HEAD | branch | 작업 트리 |", "|---|---|---|---|"]
    for name, repo in manifest["repositories"].items():
        table.append("| " + name + " | `" + repo["head"] + "` | `" + repo["branch"]
                     + "` | " + ("dirty: 아래 manifest 확인" if repo["status"] else "clean") + " |")
    return (header + "\n".join(table) + "\n\n" + MARKER
            + json.dumps(manifest, ensure_ascii=False, indent=2) + END + "\n\n"
            + "\n".join(sections))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backend", type=Path, default=APP.parent / "godieor-backend")
    parser.add_argument("--verifier", type=Path, default=APP.parent / "godieor-verifier")
    parser.add_argument("--check", action="store_true", help="기존 전달본의 소스·커밋·상태 일치 확인")
    args = parser.parse_args()
    roots = {"app": APP, "backend": args.backend.resolve(), "verifier": args.verifier.resolve()}
    output = APP / "work/context/chatgpt-context.md"
    try:
        manifest, sections = snapshot(roots)
        if args.check:
            existing = output.read_text(encoding="utf-8")
            start = existing.index(MARKER) + len(MARKER)
            saved = json.loads(existing[start:existing.index(END, start)])
            if existing != render(manifest, sections, saved["generatedAt"]):
                raise ValueError("전달본이 오래됐거나 변경됨. 커밋/문서 확인 후 다시 생성하세요.")
            print("최신 전달본 확인: " + str(output))
        else:
            generated_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
            content = render(manifest, sections, generated_at)
            # Never overwrite a symlink or write through one outside the ignored directory.
            work = APP / "work"
            if output.is_symlink() or work.is_symlink() or output.parent.is_symlink():
                raise ValueError("출력 경로에 symlink를 사용할 수 없습니다.")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(content, encoding="utf-8")
            print("생성: " + str(output) + " (" + str(len(manifest["sources"])) + "개 출처)")
        return 0
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print("맥락 전달본 오류: " + str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
