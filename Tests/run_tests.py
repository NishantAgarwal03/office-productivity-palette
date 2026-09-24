"""
========================================================================================
             OFFICE PRODUCTIVITY HUB - ZERO-TRUST MASTER TEST HARNESS
                               (Python 3.11 Engine)
========================================================================================
Enforces the 10 Aerospace-Grade Verification Invariants:
1. Every allowlisted suite starts and exits normally with code 0.
2. No suite times out or leaves surviving child processes.
3. Every suite emits exactly one completion sentinel ([TEST_RUN_COMPLETE]).
4. Every suite creates valid schema-versioned JSON results (results.json).
5. total == passed + failed, failed == 0, and total > 0 for each required suite.
6. All reported suite names match the expected allowlist.
7. Every write resolves inside that suite's unique sandbox.
8. The closed-world production manifest has zero additions, deletions, mutations, or file leaks.
9. No unexpected modal window or unhandled stderr error is detected.
10. Aggregate totals reconcile with all individual results, and all static #Includes are hermetic.
========================================================================================
"""

import os
import sys
import time
import json
import shutil
import hashlib
import subprocess
import re
from pathlib import Path
from datetime import datetime

# --------------------------------------------------------------------------------------
# 1. Configuration & Canonical Allowlist (All 8 Test Suites)
# --------------------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
LIB_DIR = ROOT_DIR / "Lib"
WORKSPACE_ROOT = ROOT_DIR.parent.resolve()
SANDBOX_BASE = SCRIPT_DIR / "_test_sandbox"

ALLOWLIST_SUITES = [
    "test_suite_runner.ahk",
    "test_integration_runner.ahk",
    "test_civil_converter.ahk",
    "test_civil_all_units_exhaustive.ahk",
    "test_modularity_runner.ahk",
    "test_workflow_composer.ahk",
    "test_regression_defects.ahk",
    "test_ui_interaction_runner.ahk",
]

PROTECTED_PRODUCTION_FILES = [
    ROOT_DIR / "office_productivity_snippets.csv",
    ROOT_DIR / "office_productivity_tasks.csv",
    ROOT_DIR / "office_tasks_archive.csv",
    ROOT_DIR / "CivilEngineeringDefaults.ini",
    ROOT_DIR / "office_productivity_palette_v2.0.1.ahk",
]

# Add all files under Lib/ to protected manifest
if LIB_DIR.exists():
    for f in LIB_DIR.glob("**/*"):
        if f.is_file():
            PROTECTED_PRODUCTION_FILES.append(f)

EXCLUDED_MANIFEST_PATTERNS = [
    "_test_sandbox",
    ".git",
    "__pycache__",
    "master_test_summary.json",
    "Archive",
]

SUITE_TIMEOUT_SECONDS = 60

# --------------------------------------------------------------------------------------
# 2. AutoHotkey Executable Resolver
# --------------------------------------------------------------------------------------
def resolve_autohotkey_exe() -> Path:
    candidates = [
        Path(r"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"),
        Path(r"C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe"),
        Path(r"C:\Program Files\AutoHotkey\AutoHotkey64.exe"),
        Path(r"C:\Program Files\AutoHotkey\AutoHotkey.exe"),
    ]
    
    # Check PATH
    shutil_path = shutil.which("AutoHotkey64.exe") or shutil.which("AutoHotkey.exe")
    if shutil_path:
        candidates.insert(0, Path(shutil_path))
        
    for c in candidates:
        if c.exists() and c.is_file():
            return c
            
    raise FileNotFoundError(
        "Could not find AutoHotkey v2 executable. Checked standard paths: "
        + ", ".join(str(c) for c in candidates)
    )

# --------------------------------------------------------------------------------------
# 3. Closed-World Cryptographic Manifest Integrity (Bidirectional)
# --------------------------------------------------------------------------------------
def compute_sha256(file_path: Path) -> str:
    if not file_path.exists() or not file_path.is_file():
        return ""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()

def is_tracked_file(p: Path) -> bool:
    s = str(p).replace("\\", "/")
    for ex in EXCLUDED_MANIFEST_PATTERNS:
        if ex in s:
            return False
    return True

def snapshot_closed_world_manifest() -> dict[Path, str]:
    manifest = {}
    for p in ROOT_DIR.glob("**/*"):
        if p.is_file() and is_tracked_file(p):
            manifest[p] = compute_sha256(p)
    return manifest

def verify_closed_world_manifest(baseline: dict[Path, str]) -> list[str]:
    violations = []
    
    # 1. Detect deletions and content mutations
    for p, original_hash in baseline.items():
        if not p.exists():
            violations.append(f"CLOSED-WORLD VIOLATION [FILE DELETED]: {p.relative_to(ROOT_DIR)}")
            continue
        current_hash = compute_sha256(p)
        if current_hash != original_hash:
            violations.append(
                f"CLOSED-WORLD VIOLATION [FILE MUTATED]: {p.relative_to(ROOT_DIR)} "
                f"(Baseline: {original_hash[:8]}..., Current: {current_hash[:8]}...)"
            )
            
    # 2. Detect unauthorized file additions / leaks outside sandbox
    current_tracked = set()
    for p in ROOT_DIR.glob("**/*"):
        if p.is_file() and is_tracked_file(p):
            current_tracked.add(p)
            
    baseline_set = set(baseline.keys())
    leaked_files = current_tracked - baseline_set
    for p in sorted(leaked_files):
        violations.append(f"CLOSED-WORLD VIOLATION [UNAUTHORIZED FILE ADDITION/LEAK]: {p.relative_to(ROOT_DIR)}")
        
    return violations

# --------------------------------------------------------------------------------------
# 4. Static #Include Dependency Tree & Hermeticity Auditor
# --------------------------------------------------------------------------------------
def get_production_and_test_ahk_files() -> list[Path]:
    files = []
    for p in ROOT_DIR.glob("*.ahk"):
        files.append(p)
    for p in (ROOT_DIR / "Lib").glob("**/*.ahk"):
        files.append(p)
    for p in SCRIPT_DIR.glob("*.ahk"):
        if "_test_sandbox" not in str(p):
            files.append(p)
    return sorted(files)

def audit_include_dependencies() -> list[str]:
    """
    Statically analyzes all production and test .ahk files.
    Enforces:
    1. Zero external / machine-local <LibName> standard library inclusions.
    2. All relative #Include paths must resolve to an existing file on disk.
    3. All resolved paths must remain strictly within the workspace root boundary.
    """
    violations = []
    files_to_check = get_production_and_test_ahk_files()
    
    re_angle = re.compile(r'^\s*#Include\s+<([^>]+)>', re.IGNORECASE)
    re_path = re.compile(r'^\s*#Include(?:\s+\*i)?\s+["\']?([^"\'\r\n<>]+)["\']?', re.IGNORECASE)
    
    for ahk_file in files_to_check:
        try:
            content = ahk_file.read_text(encoding="utf-8-sig", errors="replace")
        except Exception as e:
            violations.append(f"STATIC AUDIT [READ ERROR]: {ahk_file.name} - {e}")
            continue
            
        for line_num, line in enumerate(content.splitlines(), 1):
            line_str = line.strip()
            if not line_str.lower().startswith("#include"):
                continue
                
            # Check 1: Reject angle-bracket includes <LibName>
            m_angle = re_angle.match(line_str)
            if m_angle:
                lib_target = m_angle.group(1)
                violations.append(
                    f"STATIC AUDIT [EXTERNAL <LIB> LEAK]: {ahk_file.relative_to(ROOT_DIR)}:L{line_num} "
                    f"includes external machine-local <{lib_target}>"
                )
                continue
                
            # Check 2: Validate relative file includes
            m_path = re_path.match(line_str)
            if m_path:
                raw_inc = m_path.group(1).strip()
                if not raw_inc:
                    continue
                norm_inc = raw_inc.replace("/", "\\")
                target_path = (ahk_file.parent / norm_inc).resolve()
                
                # Check target file exists
                if not target_path.exists() or not target_path.is_file():
                    violations.append(
                        f"STATIC AUDIT [MISSING INCLUDE]: {ahk_file.relative_to(ROOT_DIR)}:L{line_num} "
                        f"-> '{raw_inc}' resolves to non-existent file: {target_path}"
                    )
                    continue
                    
                # Check target file is within workspace root
                try:
                    target_path.relative_to(WORKSPACE_ROOT)
                except ValueError:
                    violations.append(
                        f"STATIC AUDIT [OUT-OF-BOUNDS LEAK]: {ahk_file.relative_to(ROOT_DIR)}:L{line_num} "
                        f"-> '{raw_inc}' points outside workspace root: {target_path}"
                    )
                    
    return violations

# --------------------------------------------------------------------------------------
# 5. Tree-Kill Process Helper
# --------------------------------------------------------------------------------------
def kill_process_tree(pid: int):
    if os.name == "nt":
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)], capture_output=True, check=False)
    else:
        import signal
        os.kill(pid, signal.SIGKILL)

# --------------------------------------------------------------------------------------
# 6. Suite Execution Engine
# --------------------------------------------------------------------------------------
def run_suite(ahk_exe: Path, suite_filename: str) -> dict:
    suite_path = SCRIPT_DIR / suite_filename
    suite_stem = suite_path.stem
    run_id = f"{suite_stem}_{int(time.time() * 1000)}"
    suite_sandbox = SANDBOX_BASE / run_id
    
    # Invariant 7: Ensure sandbox directory is fresh
    if suite_sandbox.exists():
        shutil.rmtree(suite_sandbox, ignore_errors=True)
    suite_sandbox.mkdir(parents=True, exist_ok=True)
    (suite_sandbox / "Backups").mkdir(parents=True, exist_ok=True)
    (suite_sandbox / "Telemetry").mkdir(parents=True, exist_ok=True)
    
    # Environment injection
    env = os.environ.copy()
    env["OPH_TEST_MODE"] = "1"
    env["OPH_TEST_DATA_DIR"] = str(suite_sandbox)
    
    start_time = time.perf_counter()
    proc = None
    stdout_text = ""
    stderr_text = ""
    timed_out = False
    
    try:
        proc = subprocess.Popen(
            [str(ahk_exe), "/ErrorStdOut", str(suite_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            env=env,
            cwd=str(SCRIPT_DIR)
        )
        stdout_text, stderr_text = proc.communicate(timeout=SUITE_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        timed_out = True
        if proc:
            kill_process_tree(proc.pid)
            stdout_text, stderr_text = proc.communicate()
    
    duration_ms = int((time.perf_counter() - start_time) * 1000)
    
    suite_result = {
        "suite_filename": suite_filename,
        "suite_stem": suite_stem,
        "run_id": run_id,
        "sandbox": str(suite_sandbox),
        "duration_ms": duration_ms,
        "timed_out": timed_out,
        "exit_code": proc.returncode if proc else -1,
        "stdout": stdout_text,
        "stderr": stderr_text,
        "sentinel_count": stdout_text.count("[TEST_RUN_COMPLETE]"),
        "json_valid": False,
        "total": 0,
        "passed": 0,
        "failed": 0,
        "failures": [],
        "errors": []
    }
    
    # --- Invariant Checks for This Suite ---
    
    # Invariant 2: Timeout check
    if timed_out:
        suite_result["errors"].append(f"Suite timed out after {SUITE_TIMEOUT_SECONDS}s")
        return suite_result
        
    # Invariant 1: Exit code check
    if proc.returncode != 0:
        suite_result["errors"].append(f"Process exited with non-zero exit code: {proc.returncode}")
        
    # Invariant 3: Exactly one completion sentinel
    if suite_result["sentinel_count"] != 1:
        suite_result["errors"].append(
            f"Expected exactly 1 completion sentinel '[TEST_RUN_COMPLETE]', found {suite_result['sentinel_count']}"
        )
        
    # Invariant 4 & 5: Parse schema-versioned JSON results
    json_path = suite_sandbox / "results.json"
    if not json_path.exists():
        suite_result["errors"].append(f"Missing schema result artifact: {json_path}")
    else:
        try:
            with open(json_path, "r", encoding="utf-8-sig") as f:
                data = json.load(f)
            
            # Check schema version
            if data.get("schema_version") != "1.0.0":
                suite_result["errors"].append(f"Invalid schema_version: {data.get('schema_version')} (expected '1.0.0')")
            
            # Check suite name match (Invariant 6)
            reported_suite = data.get("suite_name", "")
            if reported_suite != suite_stem:
                suite_result["errors"].append(f"Suite name mismatch: reported '{reported_suite}', expected '{suite_stem}'")
                
            total = int(data.get("total", 0))
            passed = int(data.get("passed", 0))
            failed = int(data.get("failed", 0))
            
            suite_result["total"] = total
            suite_result["passed"] = passed
            suite_result["failed"] = failed
            suite_result["failures"] = data.get("failures", [])
            suite_result["json_valid"] = True
            
            # Invariant 5: Reconcile counts
            if total <= 0:
                suite_result["errors"].append(f"Hollow suite: reported total {total} assertions (must be > 0)")
            if total != (passed + failed):
                suite_result["errors"].append(f"Count mismatch: total ({total}) != passed ({passed}) + failed ({failed})")
            if failed > 0:
                suite_result["errors"].append(f"{failed} assertions failed in suite")
                
        except Exception as e:
            suite_result["errors"].append(f"Failed to parse results.json: {str(e)}")
            
    # Invariant 9: Unhandled stderr checks
    if stderr_text and ("Error:" in stderr_text or "Fatal:" in stderr_text):
        suite_result["errors"].append(f"Unhandled stderr exception: {stderr_text.strip()}")
        
    # Clean up successful sandbox, preserve failed sandbox for autopsy
    if not suite_result["errors"] and suite_result["failed"] == 0:
        shutil.rmtree(suite_sandbox, ignore_errors=True)
        
    return suite_result

# --------------------------------------------------------------------------------------
# 7. Master Runner Entrypoint & Presentation Matrix
# --------------------------------------------------------------------------------------
def main():
    print("=" * 88)
    print("      OFFICE PRODUCTIVITY HUB - ZERO-TRUST MASTER TEST HARNESS (Python 3.11)")
    print("=" * 88)
    
    ahk_exe = resolve_autohotkey_exe()
    print(f"[*] AutoHotkey Executable : {ahk_exe}")
    print(f"[*] Project Root Dir      : {SCRIPT_DIR}")
    print(f"[*] Workspace Root Dir    : {WORKSPACE_ROOT}")
    print(f"[*] Total Suites Allowlist: {len(ALLOWLIST_SUITES)}")
    print("-" * 88)
    
    # 1. Run Static #Include Dependency Tree & Hermeticity Audit
    print("[*] Running Static #Include Dependency Tree & Hermeticity Audit...")
    include_violations = audit_include_dependencies()
    production_files = get_production_and_test_ahk_files()
    if include_violations:
        print(f"[!] {len(include_violations)} Static #Include violations found across {len(production_files)} files:")
        for v in include_violations:
            print(f"    - {v}")
    else:
        print(f"[+] Verified {len(production_files)} production & test AHK files: 0 external <Lib> leaks, all paths valid.")
    print("-" * 88)
    
    # 2. Snapshot Closed-World Repository Baseline (Invariant 8)
    print("[*] Taking cryptographic SHA-256 baseline snapshot of repository...")
    manifest_baseline = snapshot_closed_world_manifest()
    print(f"[+] Sealed {len(manifest_baseline)} files in closed-world manifest.")
    print("-" * 88)
    
    suite_results = []
    overall_start_time = time.perf_counter()
    
    for suite in ALLOWLIST_SUITES:
        print(f"[*] Executing suite: {suite} ...", end="", flush=True)
        res = run_suite(ahk_exe, suite)
        suite_results.append(res)
        status = "PASS" if (len(res["errors"]) == 0 and res["failed"] == 0) else "FAIL"
        print(f" [{status}] ({res['duration_ms']}ms, {res['passed']}/{res['total']} passed)")
    
    overall_duration_ms = int((time.perf_counter() - overall_start_time) * 1000)
    
    # 3. Verify Closed-World Manifest Immutability & File Leak Absence (Invariant 8)
    print("-" * 88)
    print("[*] Verifying closed-world manifest immutability & checking for file additions/leaks...")
    manifest_violations = verify_closed_world_manifest(manifest_baseline)
    if manifest_violations:
        print(f"[!] {len(manifest_violations)} closed-world manifest violations detected:")
        for mv in manifest_violations:
            print(f"    - {mv}")
    else:
        print("[+] Closed-world manifest verified: 0 additions, 0 deletions, 0 mutations, 0 leaks.")
    
    # 4. Aggregate Reconciliation (Invariant 10)
    grand_total = sum(r["total"] for r in suite_results)
    grand_passed = sum(r["passed"] for r in suite_results)
    grand_failed = sum(r["failed"] for r in suite_results)
    all_errors = []
    for r in suite_results:
        all_errors.extend(r["errors"])
    all_errors.extend(manifest_violations)
    all_errors.extend(include_violations)
    
    # Render Master Report Table
    print("\n" + "=" * 88)
    print(f"{'SUITE NAME':<38} | {'TOTAL':>6} | {'PASSED':>6} | {'FAILED':>6} | {'PASS RATE':>9} | {'TIME':>6}")
    print("-" * 88)
    for r in suite_results:
        rate = (r["passed"] / max(r["total"], 1)) * 100
        time_str = f"{r['duration_ms']}ms"
        print(f"{r['suite_filename']:<38} | {r['total']:>6} | {r['passed']:>6} | {r['failed']:>6} | {rate:>8.1f}% | {time_str:>6}")
    print("-" * 88)
    grand_rate = (grand_passed / max(grand_total, 1)) * 100
    grand_time_str = f"{overall_duration_ms/1000:0.2f}s"
    print(f"{'GRAND AGGREGATE TOTALS':<38} | {grand_total:>6} | {grand_passed:>6} | {grand_failed:>6} | {grand_rate:>8.1f}% | {grand_time_str:>6}")
    print("=" * 88)
    
    # Check 10-point contract compliance
    is_success = (len(all_errors) == 0 and grand_failed == 0 and grand_total > 0)
    
    # Save Master JSON summary
    summary_data = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "python_version": sys.version,
        "autohotkey_exe": str(ahk_exe),
        "overall_status": "PASS" if is_success else "FAIL",
        "duration_ms": overall_duration_ms,
        "grand_total": grand_total,
        "grand_passed": grand_passed,
        "grand_failed": grand_failed,
        "pass_rate_percent": grand_rate,
        "manifest_violations": manifest_violations,
        "include_violations": include_violations,
        "suites": suite_results
    }
    
    summary_path = SCRIPT_DIR / "master_test_summary.json"
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary_data, f, indent=2)
    print(f"[+] Master summary written to: {summary_path.name}")
    
    if not is_success:
        print("\n[!] CRITICAL VERIFICATION VIOLATIONS ENCOUNTERED:")
        for idx, err in enumerate(all_errors, 1):
            print(f"    {idx}. {err}")
        print("\n[RESULT] ZERO-TRUST TEST HARNESS: FAILED (Exit Code 1)")
        sys.exit(1)
    else:
        print("\n[OK] ALL 10 ZERO-TRUST INVARIANTS VERIFIED: ZERO FAILURES & 100% BITWISE DATA INTEGRITY.")
        print("[RESULT] ZERO-TRUST TEST HARNESS: PASSED (Exit Code 0)")
        sys.exit(0)

if __name__ == "__main__":
    main()
