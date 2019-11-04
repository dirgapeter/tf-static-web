# AWS S3 Static Web Hosting module

[Inspired by this module](https://github.com/ringods/terraform-website-s3-cloudfront-route53), but split up in different modules and added various security and other settings (e.g. encryption, access logging, versioning, ...).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bucket\_name | The name of the bucket. | string | `"static-web"` | no |
| deployer\_groups | The IAM groups that will get the policy assigned to deploy to the s3 bucket | list(string) | `[]` | no |
| deployer\_users | The IAM users that will get the policy assigned to deploy to the s3 bucket | list(string) | `[]` | no |
| environment | Environment of the project. Also used as a prefix in names of related resources. | string | n/a | yes |
| logging\_prefix | A prefix in names for logging bucket | string | `"logs/"` | no |
| manage\_log\_bucket | Defines whether this module should generate and manage its own s3 bucket for logging | bool | `"true"` | no |
| project | Name of the project. Also used as a prefix in names of related resources. | string | n/a | yes |
| tags | Optional Tags | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| origin\_access\_identity |  |
| website\_bucket |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
