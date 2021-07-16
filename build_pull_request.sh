
# Exit on error
set -e

# unshallow since GitHub actions does a shallow clone
git fetch --unshallow
git fetch origin
#
command=$(git diff --name-only origin/master)
# Get all the modules that were changed
while read -r line; do
  module_name="${line%%/*}"
  if [[ ${module_name} != "buildSrc" && ${MODULES} != *"${module_name}"* ]]; then
    MODULES="${MODULES} ${module_name}"
  fi
done <<< "$command"
changed_modules=$MODULES
echo "Found changes in $changed_modules"

if [[ $changed_modules !=  "" ]]; then
  # Get a list of all available gradle tasks
  # group available from Gradle 5.1
  AVAILABLE_TASKS=$(./gradlew tasks --all)
  # Check if these modules have gradle tasks
  build_commands=""
  for module in $changed_modules
  do
    if [[ $AVAILABLE_TASKS =~ $module":" ]]; then
      build_commands=${build_commands}" :"${module}":jacocoTestDebugUnitTestReport"
    fi
  done
fi

if [[ $build_commands == "" ]]; then
    echo "Skip unit tests...."
fi

# Pass the commands to next step
echo "::set-env name=build_commands::$build_commands"
exit 0