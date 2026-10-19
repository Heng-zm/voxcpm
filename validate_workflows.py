import os
import sys
import yaml

WORKFLOWS_DIR = os.path.join(".github", "workflows")

def validate_workflow_file(filepath):
    print(f"\n[VALIDATING] {filepath}")
    if not os.path.exists(filepath):
        print(f"  [FAIL] File does not exist: {filepath}")
        return False
        
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            data = yaml.safe_load(content)
    except Exception as e:
        print(f"  [FAIL] YAML parsing error: {e}")
        return False
        
    if not isinstance(data, dict):
        print("  [FAIL] Root YAML must be a mapping (dict).")
        return False
        
    # Check essential keys
    if "name" not in data:
        print("  [FAIL] Missing 'name' property.")
        return False
    print(f"  [+] Workflow Name: {data['name']}")
    
    if "on" not in data and True not in data: # YAML 'on' can parse as boolean True in older specs
        print("  [FAIL] Missing 'on' trigger definitions.")
        return False
    print("  [+] Triggers configured.")
    
    if "jobs" not in data or not isinstance(data["jobs"], dict):
        print("  [FAIL] Missing or invalid 'jobs' dictionary.")
        return False
    print(f"  [+] Jobs defined: {list(data['jobs'].keys())}")
    
    # Check for hardcoded private keys or passwords
    forbidden_terms = ["BEGIN PRIVATE KEY", "BEGIN RSA PRIVATE KEY", "password: \"", "secret: \""]
    for term in forbidden_terms:
        if term in content:
            print(f"  [FAIL] Potential hardcoded credential found: {term}")
            return False
            
    print("  [+] Security check: No hardcoded credentials detected.")
    print(f"  [PASS] {filepath} is syntactically and structurally valid.")
    return True

def run_workflow_validations():
    print("==================================================")
    print("VALIDATING GITHUB ACTIONS WORKFLOWS")
    print("==================================================")
    
    expected_workflows = [
        os.path.join(WORKFLOWS_DIR, "ios-ci.yml"),
        os.path.join(WORKFLOWS_DIR, "backend-ci.yml"),
        os.path.join(WORKFLOWS_DIR, "release.yml"),
        os.path.join(WORKFLOWS_DIR, "build-iphone-ipa.yml")
    ]
    
    all_valid = True
    for wf in expected_workflows:
        if not validate_workflow_file(wf):
            all_valid = False
            
    if all_valid:
        print("\n[SUCCESS] All GitHub Actions workflow files passed validation.")
        return 0
    else:
        print("\n[FAIL] Workflow validation encountered errors.")
        return 1

if __name__ == "__main__":
    sys.exit(run_workflow_validations())
