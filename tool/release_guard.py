#!/usr/bin/env python3
"""Fail-closed source, artifact, and provenance gates for the release workflow."""

import argparse
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import stat
import subprocess

REPOSITORY = "pentaCoxian/gglp"
REPOSITORY_URL = f"https://github.com/{REPOSITORY}"
WORKFLOW = ".github/workflows/release.yml"
WORKFLOW_IDENTITY = f"{REPOSITORY_URL}/{WORKFLOW}@refs/heads/main"
CI_WORKFLOW = ".github/workflows/ci.yml"
SHA = r"[0-9a-f]{40}"
DIGEST = r"[0-9a-f]{64}"
VERSION = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
MAX_APK_SIZE = 200 * 1024 * 1024


def run(*args):
    return subprocess.check_output(args, text=True, timeout=180).strip()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON field: {key}")
        result[key] = value
    return result


def parse_json(text):
    return json.loads(text, object_pairs_hook=unique_object)


def api(path):
    return parse_json(run("gh", "api", "--hostname", "github.com", "-H",
                          "X-GitHub-Api-Version: 2022-11-28",
                          f"repos/{REPOSITORY}/{path}"))


def positive_integer(value, label):
    if isinstance(value, bool) or not re.fullmatch(r"[1-9][0-9]{0,19}", str(value)):
        raise ValueError(f"Invalid {label}")
    return int(value)


def commit_sha(value):
    if not isinstance(value, str) or not re.fullmatch(SHA, value):
        raise ValueError("Expected a full lowercase commit SHA")
    return value


def validate_context(environment, head):
    expected = {
        "GITHUB_REPOSITORY": REPOSITORY,
        "GITHUB_EVENT_NAME": "workflow_dispatch",
        "GITHUB_REF": "refs/heads/main",
        "GITHUB_WORKFLOW_REF": f"{REPOSITORY}/{WORKFLOW}@refs/heads/main",
        "GITHUB_SERVER_URL": "https://github.com",
    }
    if any(environment.get(key) != value for key, value in expected.items()):
        raise ValueError("Releases must run from the canonical main release workflow")
    source = commit_sha(environment.get("GITHUB_SHA"))
    if environment.get("GITHUB_WORKFLOW_SHA") != source or head != source:
        raise ValueError("Checkout, source, and release workflow commits must match")
    return source


def resolve_tag(tag):
    reference = api(f"git/ref/tags/{tag}")
    if reference.get("ref") != f"refs/tags/{tag}":
        raise ValueError("Release tag did not resolve exactly")
    target = reference.get("object", {})
    # Git annotated tags may point to other annotated tags. Never follow URLs
    # supplied in the API payload; only request validated object IDs in this repo.
    for _ in range(8):
        value = commit_sha(target.get("sha"))
        if target.get("type") == "commit":
            return value
        if target.get("type") != "tag":
            break
        target = api(f"git/tags/{value}").get("object", {})
    raise ValueError("Release tag must resolve to a commit")


def validate_environment(name, configuration, policies):
    if configuration.get("name") != name:
        raise ValueError(f"The {name} environment must exist")
    # GitHub exposes this field after protection rules are saved in Settings.
    # Require the observed disabled state, including when the field is absent.
    if configuration.get("can_admins_bypass") is not False:
        raise ValueError(f"{name} must disable administrator bypass")
    rules = configuration.get("protection_rules", [])
    reviewers = [rule for rule in rules if rule.get("type") == "required_reviewers"]
    allowed = reviewers[0].get("reviewers", []) if len(reviewers) == 1 else []
    # GitHub permits ANY listed reviewer to approve, so additional reviewers
    # would weaken this explicit maintainer approval policy.
    if (len(allowed) != 1 or allowed[0].get("type") != "User"
            or allowed[0].get("reviewer", {}).get("login", "").lower() != "pentacoxian"):
        raise ValueError(f"{name} must require approval by pentaCoxian")
    if configuration.get("deployment_branch_policy") != {
            "protected_branches": False, "custom_branch_policies": True}:
        raise ValueError(f"{name} must explicitly restrict deployments to main")
    branches = policies.get("branch_policies", [])
    if (policies.get("total_count") != 1 or len(branches) != 1
            or branches[0].get("name") != "main" or branches[0].get("type") != "branch"):
        raise ValueError(f"{name} must allow only the main branch, without tags or patterns")


def validate_ci_run(item, source, workflow_id):
    if (item.get("head_sha") != source or item.get("head_branch") != "main"
            or item.get("event") != "push" or item.get("workflow_id") != workflow_id
            or item.get("path") != CI_WORKFLOW
            or item.get("repository", {}).get("full_name") != REPOSITORY
            or item.get("head_repository", {}).get("full_name") != REPOSITORY):
        raise ValueError("CI run must belong to the canonical push/main workflow and exact source")
    return tuple(positive_integer(item.get(field), field)
                 for field in ("run_number", "run_attempt", "id"))


def verified_ci(source):
    workflow = api("actions/workflows/ci.yml")
    workflow_id = positive_integer(workflow.get("id"), "CI workflow ID")
    if workflow.get("path") != CI_WORKFLOW or workflow.get("state") != "active":
        raise ValueError("Canonical Android CI workflow must be active")
    result = api(f"actions/workflows/ci.yml/runs?event=push&branch=main&head_sha={source}&per_page=100")
    candidates = result.get("workflow_runs", [])
    if not candidates or result.get("total_count") != len(candidates):
        raise ValueError("Exact source must have an unambiguous Android CI run")
    latest = max(candidates, key=lambda item: validate_ci_run(item, source, workflow_id))
    # Refresh the selected run so a newer, failed or running attempt cannot be
    # masked by a previously successful attempt in the workflow listing.
    current = api(f"actions/runs/{positive_integer(latest.get('id'), 'CI run ID')}")
    if (validate_ci_run(current, source, workflow_id) != validate_ci_run(latest, source, workflow_id)
            or current.get("status") != "completed" or current.get("conclusion") != "success"):
        raise ValueError("Latest Android CI run and attempt must have completed successfully")
    return current["id"]


def source(tag):
    if not re.fullmatch(f"v{VERSION}", tag):
        raise ValueError("Release tag must be a stable vX.Y.Z version")
    value = validate_context(os.environ, run("git", "rev-parse", "HEAD"))
    if resolve_tag(tag) != value:
        raise ValueError("Release tag must point to this exact workflow commit")
    branch = api("branches/main")
    if branch.get("name") != "main" or branch.get("protected") is not True:
        raise ValueError("The main branch must be protected")
    if branch.get("commit", {}).get("sha") != value:
        raise ValueError("Release source is stale: current main must match the workflow commit")
    ci_run_id = verified_ci(value)
    for name in ("release-signing", "release-publishing"):
        validate_environment(name, api(f"environments/{name}"),
                             api(f"environments/{name}/deployment-branch-policies?per_page=100"))
    # Recheck moving refs after the API validations. Each privileged job invokes
    # this gate again after its environment approval.
    if (resolve_tag(tag) != value
            or api("branches/main").get("commit", {}).get("sha") != value):
        raise ValueError("Release references moved while validating the source")
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with Path(output).open("a", encoding="utf-8") as target:
            target.write(f"source_sha={value}\nci_run_id={ci_run_id}\n")
    print(f"Verified source {value}; Android CI run {ci_run_id}")
    return value, ci_run_id


def read_file(path, maximum, *, content=False):
    flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW
    descriptor = os.open(path, flags)
    with os.fdopen(descriptor, "rb") as source:
        before = os.fstat(source.fileno())
        if not stat.S_ISREG(before.st_mode) or not 0 < before.st_size <= maximum:
            raise ValueError(f"Expected a nonempty regular file of at most {maximum} bytes: {path}")
        digest = hashlib.sha256()
        chunks = []
        size = 0
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            size += len(chunk)
            if size > maximum:
                raise ValueError("File grew beyond its permitted size")
            digest.update(chunk)
            if content:
                chunks.append(chunk)
        after = os.fstat(source.fileno())
        if (size != before.st_size or after.st_size != before.st_size
                or after.st_mtime_ns != before.st_mtime_ns):
            raise ValueError("File changed during verification")
    return b"".join(chunks) if content else digest.hexdigest()


def digest(file, sha256):
    if not isinstance(sha256, str) or not re.fullmatch(DIGEST, sha256):
        raise ValueError("Expected a lowercase SHA-256 digest")
    if not hmac.compare_digest(read_file(file, MAX_APK_SIZE), sha256):
        raise ValueError("APK digest does not match the verified build")


def validate_attestation_result(results, source_sha, run_id, run_attempt):
    expected = {
        "issuer": "https://token.actions.githubusercontent.com",
        "subjectAlternativeName": WORKFLOW_IDENTITY,
        "buildSignerURI": WORKFLOW_IDENTITY,
        "buildSignerDigest": source_sha,
        "sourceRepositoryURI": REPOSITORY_URL,
        "sourceRepositoryDigest": source_sha,
        "sourceRepositoryRef": "refs/heads/main",
        "buildConfigURI": WORKFLOW_IDENTITY,
        "buildConfigDigest": source_sha,
        "buildTrigger": "workflow_dispatch",
        "runnerEnvironment": "github-hosted",
        "runInvocationURI": f"{REPOSITORY_URL}/actions/runs/{run_id}/attempts/{run_attempt}",
    }
    if not isinstance(results, list) or not results:
        raise ValueError("No cryptographically verified release provenance")
    for result in results:
        certificate = result.get("verificationResult", {}).get("signature", {}).get("certificate", {})
        if all(certificate.get(key) == value for key, value in expected.items()):
            return
    # These fields are from the verified X.509 certificate, populated from
    # GitHub's OIDC claims, NOT the workflow-controlled statement.predicate.
    # See gh_attestation_verify and sigstore-go's certificate.Extensions.
    raise ValueError("Provenance certificate does not identify this exact release run and attempt")


def provenance(directory, source_sha, run_id, run_attempt):
    commit_sha(source_sha)
    run_id = positive_integer(run_id, "release run ID")
    run_attempt = positive_integer(run_attempt, "release run attempt")
    if directory.is_symlink() or not directory.is_dir():
        raise ValueError("Release directory must be a real directory")
    manifest = parse_json(read_file(directory / "update.json", 65536, content=True))
    name = manifest.get("apkFileName")
    if not isinstance(name, str) or not re.fullmatch(f"gglp-{VERSION}\\.apk", name):
        raise ValueError("Invalid APK filename in update manifest")
    digest(directory / name, manifest.get("sha256"))
    read_file(directory / "provenance.json", 10 * 1024 * 1024)
    for artifact in (name, "update.json"):
        result = parse_json(run(
            "gh", "attestation", "verify", str(directory / artifact),
            "--hostname", "github.com", "--repo", REPOSITORY,
            "--bundle", str(directory / "provenance.json"),
            "--signer-workflow", f"{REPOSITORY}/{WORKFLOW}",
            "--cert-identity", WORKFLOW_IDENTITY,
            "--source-ref", "refs/heads/main", "--source-digest", source_sha,
            "--signer-digest", source_sha, "--deny-self-hosted-runners", "--format", "json"))
        validate_attestation_result(result, source_sha, run_id, run_attempt)
    print(f"Verified release provenance for source {source_sha}, run {run_id}, attempt {run_attempt}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    check_source = commands.add_parser("source")
    check_source.add_argument("--tag", required=True)
    check_digest = commands.add_parser("digest")
    check_digest.add_argument("--file", type=Path, required=True)
    check_digest.add_argument("--sha256", required=True)
    check_provenance = commands.add_parser("provenance")
    check_provenance.add_argument("--directory", type=Path, required=True)
    check_provenance.add_argument("--source-sha", required=True)
    check_provenance.add_argument("--run-id", required=True)
    check_provenance.add_argument("--run-attempt", required=True)
    arguments = vars(parser.parse_args())
    command = arguments.pop("command")
    {"source": source, "digest": digest, "provenance": provenance}[command](**arguments)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, TypeError, AttributeError,
            subprocess.SubprocessError) as error:
        raise SystemExit(f"Release gate failed: {error}") from error
