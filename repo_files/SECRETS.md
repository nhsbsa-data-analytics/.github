# Configuring secrets detection

The NHSBSA takes security seriously. We require:

* contributors to install and configure secrets detection tooling before committing code
* maintainers risk assess potential for sensitive data leaks and configure detection tooling accordingly

We use a dual-layer approach - check before code is pushed (`pre-commit` hook) and check when code arrives in GitHub (GitHub Action).

## `pre-commit`

Install the following:

* [`gitleaks`](https://github.com/gitleaks/gitleaks/releases) is a secret detection tool to help prevent accidental commit of sensitive data in a local development environment Git repository.
* [`pre-commit`](https://pre-commit.com/) is a framework for managing and maintaining multi-language `pre-commit` hooks

Although aimed at NHSBSA colleagues, the guide [Setting up a `pre-commit hook` to run `gitleaks`](docs/pre-commit-gitleaks.md) may help external contributors also.

## Pre-commit hook

A `pre-commit` hook for `gitleaks` is defined in [`.pre-commit-config.yaml`](repo_files/.pre-commit-config.yaml). This should be placed in the root directory of your repository.

You can test the `pre-commit` hook is working by attempting to add and commit the [`gitleaks_tests` file](test/gitleaks_test).

## Maintainers

Copy the contents of the `repo_files` folder from this repo into all existing and new repos. It contains a GitHub Actions workflow file and `pre-commit` hook for `gitleaks`.

### New rules

Any additional rules needed, identified from a sensitive data risk assessment for example, must be added to [`gitleaks.toml`](gitleaks/gitleaks.toml). This ensures that the new rules will be used in `pre-commit` checks by all repos.

Whenever a new rule is added it should be tested by

* adding sensitive data to one of your existing source files
* attempting to commit the file

### Existing repos should scan history

If you maintain a repo that has not had `gitleaks` set-up since it was created, you should scan the history.

* Add `gitleaks.json` to the `.gitignore` file
* Open a command terminal in your repository directory and run command

```bash
gitleaks detect -r gitleaks.json
```

If `gitleaks` detects any secrets, you can find details in the `gitleaks.json` file

__If you detect a secret, you must immediately follow the remediation plan from your risk assessment and take steps to remove the secret from wherever they are used. Additionally, where possible, a new rule should be added to the `gitleaks` TOML file.__

## GitHub Action

This repo contains a callable workflow to run `gitleaks` ([`org-gitleaks-check.yml`](.github/workflows/org-gitleaks-check.yml). All repos should have the workflow [`gitleaks.yml`](.github/workflows/gitleaks.yml), which calls the former.

__IMPORTANT!__ Private repos require a `gitleaks` license. If you do not know how to find and set this, email <dall@nhsbsa.nhs.uk> for help.

## Comments on this policy

If you have suggestions on how this policy could be improved, please submit a pull request.
