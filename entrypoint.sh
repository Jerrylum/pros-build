#!/bin/sh

echo "::group::Build Info"

time_start=$SECONDS

# Use make -p to get make's internal database and extract variables with flexible pattern
make_output=$(make -p)
version_core=$(echo "$make_output" | awk -F'= *' '/^VERSION .*/ {print $2}')
library_name=$(echo "$make_output" | awk -F'= *' '/^LIBNAME .*/ {print $2}')

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
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    GITHUB_SHA=$(cat $GITHUB_EVENT_PATH | jq -r .pull_request.head.sha)
  fi
  build_id=${GITHUB_SHA:0:6}

  # Set the version to the tag version plus the build identifier
  version="${version_core}+${build_id}"
fi
artifact_name="${library_name}@${version}"
artifact_path="/${artifact_name}"

# Use tee to write to the output file and stdout
echo "version_core=${version_core}" | tee -a $GITHUB_OUTPUT
echo "library_name=${library_name}" | tee -a $GITHUB_OUTPUT
echo "version=${version}" | tee -a $GITHUB_OUTPUT
echo "artifact_name=${artifact_name}" | tee -a $GITHUB_OUTPUT
echo "artifact_path=${artifact_path}" | tee -a $GITHUB_OUTPUT

time_end=$SECONDS
echo "Time taken: $((time_end - time_start)) seconds"

echo "::endgroup::"
echo "::group::Build"

# TODO: Add LICENSE, add README

time_start=$SECONDS

echo "version: ${version}"
echo "build_args: ${build_args}"

make VERSION=${version} ${build_args}

time_end=$SECONDS

echo "Build time: $((time_end - time_start)) seconds"

echo "::endgroup::"

echo "::group::Unzip Template"

unzip ${artifact_name}.zip -d ${artifact_path}

echo "::endgroup::"
