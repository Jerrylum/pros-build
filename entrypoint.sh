#!/bin/sh -l

version_core=$(awk -F'=' '/^VERSION:=/{print $2}' Makefile)
library_name=$(awk -F'=' '/^LIBNAME:=/{print $2}' Makefile)

# If a new tag is pushed
if [[ $GITHUB_REF == refs/tags/* ]]; then
  # Remove the 'v' prefix from the tag version
  tag_version="${GITHUB_REF#refs/tags/v}"
  # Check if version_core is the same as tag_version; if not, fail
  if [[ "${version_core}" != "${tag_version}" ]]; then
    echo "The version in the Makefile does not match the pushed tag version: ${version_core} != ${tag_version}"
    exit 1
  fi

  # Set the version to the version core without the 'v' prefix and the build identifier
  version=${version_core}
else
  # Obtain build identifier by head SHA if it is not empty; otherwise, use $GITHUB_SHA
  # $GITHUB_SHA might be the merge commit SHA, which is not preferred
  # See: https://stackoverflow.com/questions/68061051/get-commit-sha-in-github-actions
  # This should also work for forked pull requests
  if [[ -n "${{ github.event.pull_request.head.sha }}" ]]; then
    SHA="${{ github.event.pull_request.head.sha }}"
  else
    SHA="${GITHUB_SHA}"
  fi
  build_id=${SHA:0:6}

  # Set the version to the tag version plus the build identifier
  version="${version_core}+${build_id}"
fi
artifact_name="${library_name}@${version}"

# Use tee to write to the output file and stdout
echo "version_core=${version_core}" | tee -a $GITHUB_OUTPUT
echo "library_name=${library_name}" | tee -a $GITHUB_OUTPUT
echo "version=${version}" | tee -a $GITHUB_OUTPUT
echo "artifact_name=${artifact_name}" | tee -a $GITHUB_OUTPUT

# Run the build command
echo "Running build command: pros make all template VERSION=${version} ${build_args}"
pros make all template VERSION=${version} ${build_args}
