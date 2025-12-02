# `.github`

## About this repo

This repo is a central place to store organisation wide files such as callable workflows and standard templates to be used in other repos.

## Current contents

### `gitleaks` related files

- A callable workflow, ([`org-gitleaks-check.yml`](.github/workflows/org-gitleaks-check.yml), to run a `gitleaks` check on pushed code.
- A workflow, ([`gitleaks.yml`](.github/workflows/gitleaks.yml), that calls `org-gitleaks-check.yml`, to be used in all our repos.
    - This file appears both in `.github/workflows` and `repo_files/.github/workflows`, as this repo itself uses it; the `repo_files` folder is designed so that it's content can be copied straight into another repo.
- `.gitleaksignore` contains fingerprints of false positives found by `gitleaks`, which are ignored
- A `pre-commit` hook to run `gitleaks` locally whenever a commit is attempted, [`.pre-commit-config.yaml`](.pre-commit-config.yaml).
    - This file appears both in this repos root and in `repo_files`, as this repo itself uses it; the `repo_files` folder is designed so that it's content can be copied straight into another repo.
- A guide, [Setting up a `pre-commit hook` to run `gitleaks`](docs/pre-commit-gitleaks.md).
- A `gitleaks` folder, containing rules definitions:
    - [`gitleaks-nhsbsa.toml`](gitleaks/gitleaks-nhsbsa.toml) - standard NHSBSA rules file
    - [`gitleaks.toml`](gitleaks/gitleaks.toml) - additional rules file that extends the standard rules
- Bash scripts to
    - scan all repos in organisation and output CSV of `gitleaks` usage, [`check_gitleaks_usage.sh`](scripts/check_gitleaks_usage.sh), with
        - `repo_name`
        - `visibility`, Private or Public
        - `has_gitleaks_workflow`, does repo contain a workflow with name containing "gitleaks"?
        - `has_gitleaks_secret`, does repo have a secret for `gitleaks` license?
    - add a secret containing the `gitleaks` license to all private repos, [`set_gitleaks_secret.sh`](scripts/set_gitleaks_secret.sh) - 
- A `gitleaks_tests` file in `test` folder, with a few fake NHS numbers that can be used as a test that `gitleaks` is set up correctly.

### `repo_files`

The contents of this folder are designed to be copied into all repos within the organisation. If any new workflows or general files become useful globally, then here is a good place to store them.

#### Contents

- A workflow, ([`gitleaks.yml`](repo_files/.github/workflows/gitleaks.yml), that calls ([`org-gitleaks-check.yml`](.github/workflows/org-gitleaks-check.yml), to be used in all organisation repos.
- A `pre-commit` hook to run `gitleaks` locally whenever a commit is attempted, [`.pre-commit-config.yaml`](repo_files/.pre-commit-config.yaml).
- Standard NHSBSA repo documentation.
    - [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
    - [CONTRIBUTING.md](CONTRIBUTING.md)
    - [LICENSE.md](LICENSE.md)
    - [SECRETS.md](SECRETS.md)
    - [SECURITY.md](SECURITY.md)
    - Note that there is no standard `README.md` included, as different repos will need different `README`s

## Contributions

We operate a [code of conduct](CODE_OF_CONDUCT.md) for all contributors.

See our [contributing guide](CONTRIBUTING.md) for guidance on how to contribute.

## License

Released under the [Apache 2 license](LICENCE.txt).
