#!/bin/sh

echo "::group::Project Info"

version_core=$(cat Makefile | awk -F'= *' '/^VERSION.*=.*/ {print $2}')
library_name=$(cat Makefile | awk -F'= *' '/^LIBNAME.*=.*/ {print $2}')

# If a new tag is pushed
if [[ $GITHUB_REF == "refs/tags/*" ]]; then
  # Remove the 'v' prefix from the tag version
  tag_version="${GITHUB_REF#refs/tags/v}"
  # Check if version_core is the same as tag_version; if not, fail
  if [[ "${version_core}" != "${tag_version}" ]]; then
    echo "The version in the Makefile does not match the pushed tag version: ${version_core} != ${tag_version}"
    exit 1
  fi
fi

# If the build ID is not needed
if [[ "${INPUT_ADD_BUILD_ID}" == "never" ]] || [[ "${INPUT_ADD_BUILD_ID}" == "except_tag" && $GITHUB_REF == "refs/tags/*" ]]; then
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
    build_id=$(cat $GITHUB_EVENT_PATH | jq -r .pull_request.head.sha | cut -c1-6)
  else
    build_id=$(echo "$GITHUB_SHA" | cut -c1-6)
  fi

  # Set the version to the tag version plus the build identifier
  version="${version_core}+${build_id}"
fi
artifact_name="${library_name}@${version}"
artifact_path="./template"

# Use tee to write to the output file and stdout
echo "version_core=${version_core}" | tee -a $GITHUB_OUTPUT
echo "library_name=${library_name}" | tee -a $GITHUB_OUTPUT
echo "version=${version}" | tee -a $GITHUB_OUTPUT
echo "artifact_name=${artifact_name}" | tee -a $GITHUB_OUTPUT
echo "artifact_path=${artifact_path}" | tee -a $GITHUB_OUTPUT

echo "::endgroup::"
echo "::group::Build"

# Print build args and build
echo "build_args: ${INPUT_BUILD_ARGS}"
STD_OUTPUT=$(mktemp)

time_start=$(date +%s)

set +e
make VERSION=${version} ${INPUT_BUILD_ARGS} | tee $STD_OUTPUT
make_exit_code=${PIPESTATUS[0]}
set -e

time_end=$(date +%s)

# Print build time and exit code
echo "Build time: $(($time_end - $time_start)) seconds"
echo "Exit code: $make_exit_code"

STD_EDITED_OUTPUT=$(mktemp)
# Remove ANSI color codes from the output
# https://stackoverflow.com/a/18000433
sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" $STD_OUTPUT >$STD_EDITED_OUTPUT

if [ $make_exit_code -ne 0 ]; then
  echo "Build failed with exit code $make_exit_code"

  echo "
# 🛑 Build Failed
Build failed in $(($time_end - $time_start)) seconds
<details><summary>Error Output (Click to expand)</summary>   

\`\`\`
$(cat $STD_EDITED_OUTPUT)
\`\`\`

</details>" >>$GITHUB_STEP_SUMMARY
  exit $make_exit_code
else
  echo "
# ✅ Build Succeeded
Version: ${version}
Build time: $(($time_end - $time_start)) seconds
<details><summary>Build Output (Click to expand)</summary>

\`\`\`
$(cat $STD_EDITED_OUTPUT)
\`\`\`

</details>" >>$GITHUB_STEP_SUMMARY
fi

echo "::endgroup::"

# Unzip template if it exists
if [ -f "${artifact_name}.zip" ]; then
  echo "::group::Unzip Template"

  unzip ${artifact_name}.zip -d ${artifact_path}
  chmod -R a+rw ${artifact_path}

  echo "::endgroup::"
fi
