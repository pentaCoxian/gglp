"""Negative security tests for source approval and artifact provenance gates."""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "release_guard", Path(__file__).resolve().parents[1] / "release_guard.py")
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)
SHA = "a" * 40
OTHER_SHA = "b" * 40


def environment():
    return {
        "GITHUB_REPOSITORY": guard.REPOSITORY,
        "GITHUB_EVENT_NAME": "workflow_dispatch",
        "GITHUB_REF": "refs/heads/main",
        "GITHUB_WORKFLOW_REF": f"{guard.REPOSITORY}/{guard.WORKFLOW}@refs/heads/main",
        "GITHUB_SERVER_URL": "https://github.com",
        "GITHUB_SHA": SHA,
        "GITHUB_WORKFLOW_SHA": SHA,
    }


def protection(name="release-signing"):
    return {
        "name": name,
        "can_admins_bypass": False,
        "deployment_branch_policy": {"protected_branches": False, "custom_branch_policies": True},
        "protection_rules": [{"type": "required_reviewers", "reviewers": [
            {"type": "User", "reviewer": {"login": "pentaCoxian"}}]}],
    }


def policy():
    return {"total_count": 1, "branch_policies": [{"name": "main", "type": "branch"}]}


def ci_run():
    return {
        "id": 123, "workflow_id": 55, "run_number": 4, "run_attempt": 1,
        "path": guard.CI_WORKFLOW, "head_sha": SHA, "head_branch": "main", "event": "push",
        "repository": {"full_name": guard.REPOSITORY},
        "head_repository": {"full_name": guard.REPOSITORY},
        "status": "completed", "conclusion": "success",
    }


def certificate():
    return {
        "issuer": "https://token.actions.githubusercontent.com",
        "subjectAlternativeName": guard.WORKFLOW_IDENTITY,
        "buildSignerURI": guard.WORKFLOW_IDENTITY,
        "buildSignerDigest": SHA,
        "sourceRepositoryURI": guard.REPOSITORY_URL,
        "sourceRepositoryDigest": SHA,
        "sourceRepositoryRef": "refs/heads/main",
        "buildConfigURI": guard.WORKFLOW_IDENTITY,
        "buildConfigDigest": SHA,
        "buildTrigger": "workflow_dispatch",
        "runnerEnvironment": "github-hosted",
        "runInvocationURI": f"{guard.REPOSITORY_URL}/actions/runs/456/attempts/2",
    }


def attestation(cert=None):
    return [{"verificationResult": {"signature": {"certificate": certificate() if cert is None else cert}}}]


class ContextTests(unittest.TestCase):
    def test_only_canonical_dispatch_main_context_is_accepted(self):
        self.assertEqual(guard.validate_context(environment(), SHA), SHA)
        for key, value in {
            "GITHUB_REPOSITORY": "attacker/gglp", "GITHUB_EVENT_NAME": "pull_request_target",
            "GITHUB_REF": "refs/tags/v0.9.2", "GITHUB_WORKFLOW_REF": "attacker/workflow",
            "GITHUB_SERVER_URL": "https://github.example", "GITHUB_SHA": "a" * 7,
            "GITHUB_WORKFLOW_SHA": OTHER_SHA,
        }.items():
            with self.subTest(key=key), self.assertRaises(ValueError):
                guard.validate_context({**environment(), key: value}, SHA)
        with self.assertRaises(ValueError):
            guard.validate_context(environment(), OTHER_SHA)
        for key in environment():
            incomplete = environment()
            del incomplete[key]
            with self.subTest(missing=key), self.assertRaises(ValueError):
                guard.validate_context(incomplete, SHA)

    def test_annotated_and_lightweight_tags_resolve_only_to_commits(self):
        reference = {"ref": "refs/tags/v0.9.2", "object": {"type": "commit", "sha": SHA}}
        with patch.object(guard, "api", return_value=reference):
            self.assertEqual(guard.resolve_tag("v0.9.2"), SHA)
        annotated = {"ref": "refs/tags/v0.9.2", "object": {"type": "tag", "sha": OTHER_SHA}}
        with patch.object(guard, "api", side_effect=[annotated, {"object": reference["object"]}]):
            self.assertEqual(guard.resolve_tag("v0.9.2"), SHA)
        for invalid in ({**reference, "ref": "refs/tags/v0.9.20"},
                        {**reference, "object": {"type": "tree", "sha": SHA}},
                        {**reference, "object": {"type": "commit", "sha": "../../escape"}},
                        annotated):
            with patch.object(guard, "api", return_value=invalid), self.assertRaises(ValueError):
                guard.resolve_tag("v0.9.2")


class ProtectionTests(unittest.TestCase):
    def test_environment_must_require_owner(self):
        guard.validate_environment("release-signing", protection(), policy())
        mutations = [
            {"name": "other"}, {"protection_rules": []}, {"deployment_branch_policy": None},
            {"deployment_branch_policy": {"protected_branches": True, "custom_branch_policies": False}},
        ]
        for change in mutations:
            with self.subTest(change=change), self.assertRaises(ValueError):
                guard.validate_environment("release-signing", {**protection(), **change}, policy())
        for reviewers in ([], [{"type": "User", "reviewer": {"login": "attacker"}}],
                          [{"type": "Team", "reviewer": {"login": "pentaCoxian"}}],
                          protection()["protection_rules"][0]["reviewers"] * 2):
            changed = protection()
            changed["protection_rules"][0]["reviewers"] = reviewers
            with self.subTest(reviewers=reviewers), self.assertRaises(ValueError):
                guard.validate_environment("release-signing", changed, policy())

    def test_environment_rejects_enabled_or_unknown_administrator_bypass(self):
        for bypass in (True, None, "false", 0):
            changed = {**protection(), "can_admins_bypass": bypass}
            with self.subTest(bypass=bypass), self.assertRaisesRegex(ValueError, "administrator bypass"):
                guard.validate_environment("release-signing", changed, policy())
        changed = protection()
        del changed["can_admins_bypass"]
        with self.assertRaisesRegex(ValueError, "administrator bypass"):
            guard.validate_environment("release-signing", changed, policy())

    def test_main_only_policy_rejects_tags_patterns_and_extra_branches(self):
        for name, kind in (("*", "branch"), ("main*", "branch"), ("main", "tag"), ("v*", "tag"),
                           ("refs/heads/main", "branch"), ("main", None)):
            changed = {"total_count": 1, "branch_policies": [{"name": name, "type": kind}]}
            with self.subTest(name=name, kind=kind), self.assertRaises(ValueError):
                guard.validate_environment("release-signing", protection(), changed)
        for changed in ({}, {"total_count": 2, "branch_policies": policy()["branch_policies"]},
                        {"total_count": 2, "branch_policies": policy()["branch_policies"] * 2}):
            with self.assertRaises(ValueError):
                guard.validate_environment("release-signing", protection(), changed)


class CiTests(unittest.TestCase):
    def api(self, items=None, current=None, workflow=None):
        return patch.object(guard, "api", side_effect=[
            workflow or {"id": 55, "path": guard.CI_WORKFLOW, "state": "active"},
            {"total_count": len(items if items is not None else [ci_run()]),
             "workflow_runs": items if items is not None else [ci_run()]},
            current or ci_run(),
        ])

    def test_successful_exact_ci(self):
        with self.api():
            self.assertEqual(guard.verified_ci(SHA), 123)

    def test_wrong_repository_workflow_event_branch_or_commit_is_rejected(self):
        for change in ({"head_sha": OTHER_SHA}, {"head_branch": "feature"}, {"event": "pull_request"},
                       {"workflow_id": 12}, {"path": ".github/workflows/fake.yml"},
                       {"repository": {"full_name": "attacker/gglp"}},
                       {"head_repository": {"full_name": "attacker/gglp"}}, {"id": True}):
            with self.subTest(change=change), self.api(items=[{**ci_run(), **change}]), self.assertRaises(ValueError):
                guard.verified_ci(SHA)

    def test_failed_running_skipped_missing_and_newer_runs_fail_closed(self):
        for status, conclusion in (("in_progress", None), ("queued", None),
                                   ("completed", "failure"), ("completed", "skipped"),
                                   ("completed", "cancelled"), ("completed", None)):
            with self.subTest(status=status, conclusion=conclusion), self.api(
                    current={**ci_run(), "status": status, "conclusion": conclusion}), self.assertRaises(ValueError):
                guard.verified_ci(SHA)
        with self.api(items=[]), self.assertRaises(ValueError):
            guard.verified_ci(SHA)
        newer = {**ci_run(), "id": 124, "run_number": 5, "conclusion": "failure"}
        with self.api(items=[newer, ci_run()], current=newer), self.assertRaises(ValueError):
            guard.verified_ci(SHA)
        with self.api(current={**ci_run(), "run_attempt": 2}), self.assertRaises(ValueError):
            guard.verified_ci(SHA)
        with self.api(workflow={"id": 55, "path": guard.CI_WORKFLOW, "state": "disabled_manually"}), self.assertRaises(ValueError):
            guard.verified_ci(SHA)


class SourceGateTests(unittest.TestCase):
    def fake_api(self, path):
        if path.startswith("git/ref/tags/"):
            return {"ref": "refs/tags/v0.9.2", "object": {"type": "commit", "sha": SHA}}
        if path == "branches/main":
            return {"name": "main", "protected": True, "commit": {"sha": SHA}}
        if path.startswith("environments/"):
            parts = path.split("/")
            return policy() if len(parts) == 3 else protection(parts[1])
        raise AssertionError(path)

    def test_complete_source_gate_outputs_immutable_source_and_ci(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "output"
            with patch.dict(os.environ, {**environment(), "GITHUB_OUTPUT": str(output)}, clear=True), \
                    patch.object(guard, "run", return_value=SHA), \
                    patch.object(guard, "api", side_effect=self.fake_api), \
                    patch.object(guard, "verified_ci", return_value=123):
                self.assertEqual(guard.source("v0.9.2"), (SHA, 123))
            self.assertEqual(output.read_text(), f"source_sha={SHA}\nci_run_id=123\n")

    def test_stale_tag_unprotected_main_and_moved_refs_fail(self):
        for target, change in (("git/ref/tags/v0.9.2", {"object": {"type": "commit", "sha": OTHER_SHA}}),
                               ("branches/main", {"protected": False}),
                               ("branches/main", {"commit": {"sha": OTHER_SHA}})):
            def altered(path):
                value = self.fake_api(path)
                return {**value, **change} if path == target else value
            with self.subTest(target=target, change=change), \
                    patch.dict(os.environ, environment(), clear=True), \
                    patch.object(guard, "run", return_value=SHA), \
                    patch.object(guard, "api", side_effect=altered), self.assertRaises(ValueError):
                guard.source("v0.9.2")
        calls = 0
        def moved(path):
            nonlocal calls
            value = self.fake_api(path)
            if path == "branches/main":
                calls += 1
                if calls > 1:
                    value["commit"]["sha"] = OTHER_SHA
            return value
        with patch.dict(os.environ, environment(), clear=True), patch.object(guard, "run", return_value=SHA), \
                patch.object(guard, "api", side_effect=moved), patch.object(guard, "verified_ci", return_value=123), \
                self.assertRaises(ValueError):
            guard.source("v0.9.2")

    def test_invalid_input_does_not_reach_api(self):
        for tag in ("v0.9.2-beta", "v01.2.3", "--help", "v0.9.2\ninjected", "../../main"):
            with self.subTest(tag=tag), patch.object(guard, "api") as caller, self.assertRaises(ValueError):
                guard.source(tag)
            caller.assert_not_called()


class ArtifactTests(unittest.TestCase):
    def test_digest_rejects_missing_symlink_directory_empty_oversized_and_changed_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            artifact = root / "app.apk"
            artifact.write_bytes(b"apk")
            expected = hashlib.sha256(b"apk").hexdigest()
            guard.digest(artifact, expected)
            for value in (b"bad", b"ap", b""):
                artifact.write_bytes(value)
                with self.assertRaises(ValueError):
                    guard.digest(artifact, expected)
            artifact.write_bytes(b"apk")
            link = root / "link.apk"
            link.symlink_to(artifact)
            for path in (link, root, root / "missing"):
                with self.subTest(path=path), self.assertRaises((ValueError, OSError)):
                    guard.digest(path, expected)
            with patch.object(guard, "MAX_APK_SIZE", 2), self.assertRaises(ValueError):
                guard.digest(artifact, expected)
            for invalid in (None, "a" * 63, expected.upper(), "../escape"):
                with self.subTest(digest=invalid), self.assertRaises(ValueError):
                    guard.digest(artifact, invalid)

    def test_duplicate_manifest_fields_are_rejected(self):
        with self.assertRaises(ValueError):
            guard.parse_json('{"sha256":"a","sha256":"b"}')


class ProvenanceTests(unittest.TestCase):
    def test_certificate_must_bind_exact_identity_source_run_and_attempt(self):
        guard.validate_attestation_result(attestation(), SHA, 456, 2)
        for key in certificate():
            for value in (None, "forged"):
                invalid = {**certificate(), key: value}
                with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                    guard.validate_attestation_result(attestation(invalid), SHA, 456, 2)
        for result in ([], {}, [{"verificationResult": {"statement": {"predicate": certificate()}}}]):
            with self.assertRaises(ValueError):
                guard.validate_attestation_result(result, SHA, 456, 2)
        with self.assertRaises(ValueError):
            guard.validate_attestation_result(attestation(), SHA, 456, 3)

    def test_both_assets_use_local_bundle_and_strict_gh_policy(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "gglp-0.9.2.apk").write_bytes(b"apk")
            (directory / "update.json").write_text(json.dumps({
                "apkFileName": "gglp-0.9.2.apk", "sha256": hashlib.sha256(b"apk").hexdigest()}))
            (directory / "provenance.json").write_text("fixture bundle")
            with patch.object(guard, "run", return_value=json.dumps(attestation())) as runner:
                guard.provenance(directory, SHA, "456", "2")
            calls = [item.args for item in runner.call_args_list]
            self.assertEqual([Path(item[3]).name for item in calls], ["gglp-0.9.2.apk", "update.json"])
            for call in calls:
                for flag, value in (("--bundle", str(directory / "provenance.json")),
                                    ("--repo", guard.REPOSITORY), ("--source-ref", "refs/heads/main"),
                                    ("--source-digest", SHA), ("--signer-digest", SHA),
                                    ("--cert-identity", guard.WORKFLOW_IDENTITY), ("--format", "json")):
                    self.assertEqual(call[call.index(flag) + 1], value)
                self.assertIn("--deny-self-hosted-runners", call)
            with patch.object(guard, "run", side_effect=OSError("verification failed")), self.assertRaises(OSError):
                guard.provenance(directory, SHA, "456", "2")
            with patch.object(guard, "run", return_value=json.dumps(attestation({}))), self.assertRaises(ValueError):
                guard.provenance(directory, SHA, "456", "2")
            (directory / "update.json").write_text(json.dumps({"apkFileName": "../outside.apk"}))
            with patch.object(guard, "run") as runner, self.assertRaises(ValueError):
                guard.provenance(directory, SHA, "456", "2")
            runner.assert_not_called()


if __name__ == "__main__":
    unittest.main()
