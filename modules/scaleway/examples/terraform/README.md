<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| helm | ~> 2.0 |
| kubectl | ~> 1.0 |
| kubernetes | ~> 2.0 |

## Providers

No provider.

## Modules

| Name | Source | Version |
|------|--------|---------|
| kapsule | particuleio/kapsule/scaleway |  |
| kapsule-addons | ../.. |  |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster-name | n/a | `string` | `"cluster"` | no |
| scaleway | n/a | `any` | `{}` | no |

## Outputs

No output.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
