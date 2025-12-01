# Setting up a `pre-commit` hook to run gitleaks

Pre-commit hooks are scripts that execute before a code commit is finalised. Their purpose is to perform some action whenever a commit is made. This takes place before the actual commit is added, and depending on the hook result, may block the commit being made. Hooks can be set up to validate the code, check for formatting errors, ensure that tests pass, and perform various other checks you can define. Here we are just using it to run a `gitleaks` check on all files included in a commit.

This guide is intended as a 'how-to' for aligning with the [guidance in the DDaT playbook](https://nhsbsa.github.io/nhsbsa-digital-playbook/development/coding-secrets-detection/). See also our [SECRETS page](../SECRETS.md).

## `pre-commit` installation

### AVD environment

1. (Once only) Create a new `conda` environment with the `pre-commit` package. Can name it whatever you like, I use `dev`.

```bash
conda create -n dev -c conda-forge python=3.11 pre-commit
```

The following steps should be repeated on _all_ repos.

2. Activate the new environment.

```bash
conda activate dev
```

3. Make `pre-commit` active. This tells `git` to run any defined `pre-commit` hooks on every commit. The hooks will be defined in a YAML config, called `pre-commit-config.yaml`, which is placed in each `git` repo - see "Congifuration" below.

```bash
pre-commit install
```

4. Deactivate the `conda` environment.

```bash
conda deactivate
```

You do not need to activate the environment for `pre-commit` to run in future. If you need to temporarily disable `pre-commit` (for example, to test the GitHub action for `gitleaks` is working correctly), you can run

```bash
conda activate dev
pre-commit uninstall
```

then turn it back on with

```bash
pre-commit install
```

An alternative method is to get steps 2-4 to be done automatically, whenever you create or clone a new repo.

1. Ensure you are in the environment with the `pre-commit` package available.

```bash
conda activate dev
```

2. Create a template git repo.

```bash
git config --global init.templateDir ~/.git-template
```

3. Install `pre-commit` in the template repo

```bash
pre-commit init-templatedir ~/.git-template
```

Note that this will not apply to existing repos, only new ones created by either `git init` or `git clone`. However, you can easily copy the hook from the template repo (make sure you are in your repo first).

```bash
cp ~/.git-template/hooks/pre-commit .git/hooks/pre-commit
```

The result of the above will be that pre-commit will run if there is a `pre-commit-config.yaml` file in the repo. If there is not, then it will silently allow commits. If you want to ensure you do not forget to add the config, add a warning.

1. Open the template repo hook.

```bash
code ~/.git-template/hooks/pre-commit
```

2. Add the following directly after the `#!/usr/bin/env bash`. You can leave the `exit 0` if you prefer to allow commits when there is no config file by default, or use `exit 1` to prevent them by default.

```bash
# --- START CUSTOM WARNING ---
if [ ! -f .pre-commit-config.yaml ]; then
    # Bold Red text for visibility on Light and Dark themes
    echo -e "\033[1;31m[WARNING] No .pre-commit-config.yaml found in this repository.\033[0m"
    echo -e "\033[1;31m          Pre-commit checks are NOT active.\033[0m"
    
    # Exit successfully (0) so the commit proceeds, or fail (1) if you want to block it
    exit 0
fi
# --- END CUSTOM WARNING ---
```


### Laptop

Getting `pre-commit` installed on laptop is not as straightforward as on AVD.

- MS Store python - The Microsoft Store version of python is what is installed on laptops. This is a poor version for development. The issue here seems to be the 256 character limit on file paths. The solution was to use `conda` to create a dedicated virtual environment with it's own python (just like done on the AVD).
- Installing `conda` - Above issue lead to the need to install `conda` on my laptop. I tried several methods, but the one that finally worked was to install [`miniforge`](https://github.com/conda-forge/miniforge?tab=readme-ov-file#miniforge3). Unfortunately, without further setup that I did not feel like trying (as may not be possible as non-admin) this means using the command line interface that comes with `miniforge`. This is worse to use than git bash, but at least it works for this use case, and is not needed other than starting/stopping `pre-commit`.

Once you have got some form of `conda` running, follow the same steps as as for AVD.


## `gitleaks` installation

1. Go to the [Gitleaks Releases Page](https://github.com/gitleaks/gitleaks/releases).
2. Download the latest windows archive (e.g., gitleaks_8.30.0_windows_x64.zip) - you may need to click the 'Show all asses' link.
3. Extract the zip.
4. Place it in a folder of your choice (e.g., `C:\ProgramData`).
5. Add the full path to your user `PATH` environment variable (e.g. `C:\ProgramData\gitleaks_8.30.0_windows_x64`). You can do this by searching for "env" in the Windows search and choosing the "Edit environment variables for your account" option, then finding and clicking "Edit" for the `PATH` variable.

This will make `gitleaks` globally available for you.


## Configuration

Each repo that you wish to have the `pre-commit` hook run for requires a file named `pre-commit-config.yaml`. This file can contain any number of hooks. For our use case of running `gitleaks` we use

```yaml
repos:
-   repo: local
    hooks:
    - id: gitleaks
      name: Detect hardcoded secrets
      description: Detect hardcoded secrets using Gitleaks with centralised NHSBSA config
      entry: >
        bash -c '
        mkdir -p .github-config &&
        curl -f -s https://raw.githubusercontent.com/nhsbsa-data-analytics/.github/main/gitleaks.toml -o .github-config/gitleaks.toml &&
        curl -f -s https://raw.githubusercontent.com/nhsbsa-data-analytics/.github/main/gitleaks-nhsbsa.toml -o .github-config/gitleaks-nhsbsa.toml &&
        gitleaks protect --config=".github-config/gitleaks.toml" --verbose --redact --staged;
        EXIT_CODE=$?;
        rm -rf .github-config;
        exit $EXIT_CODE'
      language: system
      pass_filenames: false

```

This can be copied from the `repo_files` folder of the organisation's [.github repo](https://github.com/nhsbsa-data-analytics/.github).

This hook will initiate the following actions every time you run `git commit ...`:

1. Create a temporary folder `.github-config`.
2. Download the `gitleaks` definition files (TOMLs) from our `.github` repo.
3. Run `gitleaks` using those definitions.
4. Save the output of the run.
5. Delete the temporary folder.
6. Finally, output the `gitleaks` messages.

If the hook passes, it means no secrets were detected and the commit is allowed. If the hook fails, it means some secrets were discovered - `gitleaks` will output details of the leaks and also prevent the commit from actually happening. Resolve accordingly before trying to commit again.


## Examples of usage

The nice thing about `pre-commit` hooks is that once setup, they run automatically. So you just use git as you usually would.

### Fail scenario

We try to add a file `gitleaks_tests` with content

```r
NHS number:

1234567890       

DB creds:

DB_DALP_USERNAME = "ABCDE"     
DB_DALP_PASSWORD = "qwertyuiop"
```

Commit it (`-am` means add all files and use given message)

```bash
git commit -am "Expect to fail"
```

The output is

```
Detect hardcoded secrets.................................................Failed
- hook id: gitleaks
- exit code: 1

○
    │╲
    │ ○
    ○ ░
    ░    gitleaks

Finding:     REDACTED
Secret:      REDACTED
RuleID:      nhs-number
Entropy:     3.321928
Tags:        [secret pii nhs]
File:        gitleaks_tests
Line:        4
Fingerprint: gitleaks_tests:nhs-number:4

Finding:     DB_DALP_USERNAME = "REDACTED"
Secret:      REDACTED
RuleID:      database-connection-strings
Entropy:     2.321928
Tags:        [secret credential database]
File:        gitleaks_tests
Line:        19
Fingerprint: gitleaks_tests:database-connection-strings:19

Finding:     DB_DALP_PASSWORD = "REDACTED"
Secret:      REDACTED
RuleID:      database-connection-strings
Entropy:     3.321928
Tags:        [secret credential database]
File:        gitleaks_tests
Line:        20
Fingerprint: gitleaks_tests:database-connection-strings:20

12:34PM INF 0 commits scanned.
12:34PM INF scanned ~88 bytes (88 bytes) in 121ms
12:34PM WRN leaks found: 3
```

This gives you details of all potential leaks, so you can easily see why they were flagged and where they are in your code. For how to allow a false positive, see "Allowing fallse positives below".

### Success scenario

When no potential secrets are found the output will show the check passed, along with the normal output from making a commit, since the commit was allowed.

```
Detect hardcoded secrets.................................................Passed
[gitleaks-update 2ca6879] Expect to pass
 1 file changed, 3 insertions(+)
```

### Unstaged files

Because the `gitleaks` command is set to run only on files to be committed, it will temporarily stash unstaged files, run the check and then pop the stash to restore the unstaged files. It looks like

```
[WARNING] Unstaged files detected.
[INFO] Stashing unstaged files to C:\Users\MAMCP\.cache\pre-commit\patch1764593063-8128.
Detect hardcoded secrets.............................(no files to check)Skipped
[INFO] Restored changes from C:\Users\MAMCP\.cache\pre-commit\patch1764593063-8128.
[gitleaks-update 277fab8] Empty commit
```

### Allowing false positives below

It is possible that your code includes something that matches a `gitleaks` rule, but is not a leaked secret. These can be selectively allowed. You can use the `#gitleaks:allow` comment on the line.

```r
fake_nhs_number = 1234567890  #gitleaks:allow
```

An [alternative, but experimental, method](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#gitleaksignore) is to use a `.gitleaksignore` file and add the Fingerprint from the `gitleaks` detection output (e.g. `gitleaks_tests:nhs-number:4`, given as the Fingerprint for the first secret detected in the fail scenario above).

The allow comment is the better method if you have one or a few isolated cases. But if you had something like a lot of fake data for tests, then the ignore file may be better.
