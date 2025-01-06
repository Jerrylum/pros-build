# PROS Build Template

A GitHub Action for building PROS templates. This action uses a Docker container with the PROS CLI and ARM GCC toolchain to build your PROS project.

## Features

- Builds PROS templates using PROS CLI 3.5.4 and ARM GCC toolchain 13.3
- Supports version string customization with build IDs
- Automatically validates version numbers when building from tags
- Provides useful outputs for further workflow steps
- Fast image pull time (6s)

## Usage

Add the following step to your GitHub Actions workflow:

```yaml
- name: Build template
  id: build
  uses: jerrylum/pros-build@v1.0.0
  with:
    build_args: "quick template -j" # -j enables multi-threading
```

If you want to copy files such as `README.md` and `LICENSE` to the artifact before uploading, you can add the following steps after the build step:

```yaml

- name: Copy files to artifact directory
  run: |
    echo "${{ steps.build.outputs.version }}" > "${{ env.INCLUDE_DIR }}/VERSION"
    cp README.md "${{ env.INCLUDE_DIR }}"
    cp LICENSE "${{ env.INCLUDE_DIR }}"
  env:
    INCLUDE_DIR: ${{ steps.build.outputs.artifact_path }}/include/my-library
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `add_build_id` | When to include build ID in version string | No | `except_tag` |
| `build_id` | Override the default build ID | No | `""` |
| `build_args` | Arguments passed to `make` command | No | `quick` |

### `add_build_id` Options
- `always`: Always add build ID to version string
- `except_tag`: Add build ID except when building from a tag
- `never`: Never add build ID to version string

## Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `version_core` | Version from Makefile | `1.0.0` |
| `library_name` | Library name from Makefile | `pros-template` |
| `version` | Full version string | `1.0.0+123456` |
| `artifact_name` | Name of built artifact | `pros-template@1.0.0+123456` |
| `artifact_path` | Path to built artifact | `./template` |
| `make_exit_code` | Exit code from make command | `0` |

### Artifact Path

The artifact path is the path to the built artifact. This should be the "template" directory under the `GITHUB_WORKSPACE`. Note that it only exists when building a template by including `template` in the `build_args`.

### Exit Code

The exit code from the make command is provided as an output. This can be used to determine if the build was successful.

## Example Workflow

```yaml
name: Build Template

on:
  push:
    branches: "**"
    tags:
      - "v*" # Trigger on version tags
  pull_request:
    branches: "**"
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build template
        id: build
        uses: jerrylum/pros-build@v1.0.0
        with:
          build_args: "quick template -j" # -j enables multi-threading

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          if-no-files-found: error
          name: ${{ steps.build.outputs.artifact_name }}
          path: ${{ steps.build.outputs.artifact_path }}
```

## Version Handling

When building from a tag (e.g., `v1.0.0`), the action will verify that the version in your Makefile matches the tag version (without the 'v' prefix). This ensures consistency between your tags and actual release versions.

The build ID (when enabled) is determined as follows:
1. Uses custom `build_id` if provided
2. Uses PR number and PR head commit SHA (first 6 characters) for pull requests, for example `pr123-123456`
3. Falls back to workflow commit SHA (first 6 characters)

## Release Workflow

It is recommended to push a tag before releasing a new version. This approach allows you to run the build action on the tag, ensuring that the build is successful and the artifact is ready before creating a release. Follow these steps for a smooth release process:

1. **Push a Tag**: Create and push a tag that corresponds to the new version you want to release. This will trigger the build action to run on the tagged commit.

2. **Verify Build**: Ensure that the build action completes successfully. The action will validate that the version in your Makefile matches the tag version, and it will produce an artifact.

3. **Create a Release**: Once the build is verified, create a new release in GitHub using the artifact generated from the tagged build. This ensures that the release is consistent with the code and build outputs.
