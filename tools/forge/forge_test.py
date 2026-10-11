import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.forge import forge


def fake(returncode, stdout="", stderr=""):
    def runner(cmd):
        return subprocess.CompletedProcess(list(cmd), returncode, stdout, stderr)

    return runner


def found(_name):
    return "/usr/bin/tool"


def missing(_name):
    return None


class DiskTest(unittest.TestCase):
    def test_thresholds(self):
        root = Path(".")
        self.assertEqual(forge.check_disk(root, 5 * 10**9).status, "fail")
        self.assertEqual(forge.check_disk(root, 12 * 10**9).status, "warn")
        self.assertEqual(forge.check_disk(root, 40 * 10**9).status, "ok")


class DockerTest(unittest.TestCase):
    def test_missing_docker(self):
        result = forge.check_docker(fake(0), which=missing)
        self.assertEqual(result.status, "fail")
        self.assertIn("not installed", result.detail)

    def test_permission_denied_explains_docker_group(self):
        runner = fake(1, stderr="permission denied while trying to connect")
        result = forge.check_docker(runner, which=found)
        self.assertEqual(result.status, "fail")
        self.assertIn("usermod", result.fix)

    def test_running_daemon(self):
        result = forge.check_docker(fake(0, stdout="29.1.3\n"), which=found)
        self.assertEqual(result.status, "ok")
        self.assertIn("29.1.3", result.detail)


class HostOsTest(unittest.TestCase):
    def test_same_os_as_build_image(self):
        text = 'ID=ubuntu\nVERSION_ID="24.04"\nPRETTY_NAME="Ubuntu 24.04 LTS"\n'
        self.assertEqual(forge.check_host_os(text).status, "ok")

    def test_newer_host_points_to_dev_sh(self):
        text = 'ID=ubuntu\nVERSION_ID="26.04"\nPRETTY_NAME="Ubuntu 26.04 LTS"\n'
        result = forge.check_host_os(text)
        self.assertEqual(result.status, "warn")
        self.assertIn("dev.sh", result.fix)


class RepoTest(unittest.TestCase):
    def test_detects_a_checkout(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.assertEqual(forge.check_repo(root).status, "fail")
            (root / "MODULE.bazel").write_text("")
            (root / ".bazelversion").write_text("8.8.1\n")
            result = forge.check_repo(root)
            self.assertEqual(result.status, "ok")
            self.assertIn("8.8.1", result.detail)


if __name__ == "__main__":
    unittest.main()
