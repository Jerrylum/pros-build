#!/bin/sh

echo "::group::Project Info"

time_start=$(date +%s)

version_core=$(cat Makefile | awk -F'= *' '/^VERSION.*=.*/ {print $2}')
library_name=$(cat Makefile | awk -F'= *' '/^LIBNAME.*=.*/ {print $2}')

is_tag_push=${GITHUB_REF#refs/tags/}
pull_request_head_sha=$1
echo "pull_request_head_sha: ${pull_request_head_sha}"

# If a new tag is pushed
if [[ $is_tag_push != "" ]]; then
  # Remove the 'v' prefix from the tag version
  tag_version="${GITHUB_REF#refs/tags/v}"
  # Check if version_core is the same as tag_version; if not, fail
  if [[ "${version_core}" != "${tag_version}" ]]; then
    echo "The version in the Makefile does not match the pushed tag version: ${version_core} != ${tag_version}"
    exit 1
  fi
fi

# If the build ID is not needed
if [[ "${INPUT_ADD_BUILD_ID}" == "never" ]] || [[ "${INPUT_ADD_BUILD_ID}" == "except_tag" && ${is_tag_push} != "" ]]; then
  # Set the version to the version core without the 'v' prefix and the build identifier
  version=${version_core}
else
  # Obtain build identifier by head SHA if it is not empty; otherwise, use $GITHUB_SHA
  # $GITHUB_SHA might be the merge commit SHA, which is not preferred
  # See: https://stackoverflow.com/questions/68061051/get-commit-sha-in-github-actions
  # This should also work for forked pull requests
  if [[ "${INPUT_BUILD_ID}" != "" ]]; then
    build_id=${INPUT_BUILD_ID}
  elif [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    build_id=$(cat $GITHUB_EVENT_PATH | jq -r .pull_request.head.sha)
    build_id=${build_id:0:6}
  else
    build_id=${GITHUB_SHA:0:6}
  fi

  # Set the version to the tag version plus the build identifier
  version="${version_core}+${build_id}"
fi
artifact_name="${library_name}@${version}"
artifact_path="./${artifact_name}"

# Use tee to write to the output file and stdout
echo "version_core=${version_core}" | tee -a $GITHUB_OUTPUT
echo "library_name=${library_name}" | tee -a $GITHUB_OUTPUT
echo "version=${version}" | tee -a $GITHUB_OUTPUT
echo "artifact_name=${artifact_name}" | tee -a $GITHUB_OUTPUT
echo "artifact_path=${artifact_path}" | tee -a $GITHUB_OUTPUT

time_end=$(date +%s)

echo "Time taken: $(($time_end - $time_start)) seconds"

echo "::endgroup::"
echo "::group::Build"

time_start=$(date +%s)

echo "build_args: ${INPUT_BUILD_ARGS}"

make VERSION=${version} ${INPUT_BUILD_ARGS}

time_end=$(date +%s)

echo "Build time: $(($time_end - $time_start)) seconds"

echo "::endgroup::"

echo "::group::Unzip Template"

unzip ${artifact_name}.zip -d ${artifact_path}
chmod -R a+rw ${artifact_path}

echo "::endgroup::"
