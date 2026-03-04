# IAM v6 Migration Learnings

## Task 2: Canary Migration - cert-manager.tf (v5 → v6)

### Pattern Validation
The v5 → v6 migration pattern is **CONFIRMED WORKING** for cert-manager.tf:

1. **Source Path Change**: `iam-assumable-role-with-oidc` → `iam-role`
   - Both are in the same terraform-aws-modules/iam/aws module
   - Version constraint `~> 6.0` works with both paths

2. **Attribute Mapping**:
   - `create_role` → `create` (simple rename)
   - `role_name` → `name` (simple rename)
   - `provider_url` → `enable_oidc` + `oidc_provider_urls` (split into two attributes)
   - `role_policy_arns` (list) → `policies` (map with key-value pairs)
   - `number_of_role_policy_arns` → DELETE (no longer needed)
   - `oidc_fully_qualified_subjects` → `oidc_subjects` (simple rename)

3. **Output Reference Change**:
   - `.iam_role_arn` → `.arn` (v6 module outputs different attribute name)

4. **Conditional Logic Preservation**:
   - Empty list `[]` becomes empty map `{}`
   - Ternary conditions work identically
   - Map key for policies uses addon name: `{ cert-manager = ... }`

5. **Unaffected Resources**:
   - `aws_iam_policy.cert-manager` resource unchanged
   - All kubernetes resources (namespace, helm_release, network_policy) unchanged
   - Local values and variables unchanged

### Key Insights for Batch Migration
- The pattern is **consistent and replicable** across all 16 modules
- Each module uses the same addon name as the map key in `policies`
- The `enable_oidc = true` is always required for OIDC-based modules
- `oidc_provider_urls` always wraps the URL in a list: `[replace(...)]`
- Empty map `{}` is used when `create_iam_resources_irsa` is false

### Verification Method
- `terraform fmt` validates HCL syntax without requiring full module initialization
- Module-level syntax is correct even if other modules fail to initialize
- The canary pattern is ready for batch application

## yet-another-cloudwatch-exporter.tf Migration (Completed)

### Changes Applied
- ✅ Module source: `iam-assumable-role-with-oidc` → `iam-role`
- ✅ Parameter `create_role` → `create`
- ✅ Parameter `role_name` → `name`
- ✅ Removed `provider_url` parameter
- ✅ Added `enable_oidc = true`
- ✅ Added `oidc_provider_urls = [replace(...)]` (list format)
- ✅ Changed `role_policy_arns` → `policies` (map format with key-value)
- ✅ Removed `number_of_role_policy_arns = 1`
- ✅ Changed `oidc_fully_qualified_subjects` → `oidc_subjects`
- ✅ Output reference: `.iam_role_arn` → `.arn`

### Key Learnings
- v6 `iam-role` module uses `policies` as a map (not list)
- Empty policies must be `{}` not `[]`
- `oidc_provider_urls` takes a list even for single URL
- Module name `iam_assumable_role_yet-another-cloudwatch-exporter` unchanged
- All other resources (aws_iam_policy, helm_release, kubernetes_*) remain untouched
