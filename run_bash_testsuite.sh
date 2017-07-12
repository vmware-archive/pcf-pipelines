#!/bin/bash

set -u

# path to tests is the root directory to
# start a recursive search for test files
if [[ $# != 1 ]]; then
   echo "usage: $0 <path-to-tests>"
   exit 1
fi

# search for convention
# test files should have suffix '_test'
TEST_DIR=$1
TESTFILES=$(find "${TEST_DIR}" -name "*_test.sh")
EXITCODE=0
SUCCESS=0
FAILURE=1
Should="ToBe"
ShouldNot="ToNotBe"
temp_file=$(mktemp)

function setred {
   printf '\033[1;31m'
}

function setgreen {
   printf '\033[40;38;5;82m'
}

function setdefault {
   printf '\033[0m'
}

function Expect () {
   if [[ $# != 3 ]]; then
      echo "you are not calling Expect properly"
      echo "it requires 3 args you gave $#"
      return ${FAILURE} 
   fi
   local positivePath=$2
   local testCase=$1
   local expectedValue=$3

   if [[ ${positivePath} == ${Should} ]]; then
      if [[ ${testCase} != ${expectedValue} ]]; then
         echo "${testCase} should match ${expectedValue}"
         return ${FAILURE}
      fi
   else 
      if [[ ${testCase} == ${expectedValue} ]]; then
         echo "${testCase} should not match ${expectedValue}"
         return ${FAILURE}
      fi
   fi

   return ${SUCCESS}
} >> ${temp_file}



echo 
echo "-------------------------------------------"
echo "running bash test suite"
# using the convention of each test file should have a 
# function file excluding '_test' suffix
for test in ${TESTFILES}; do
  (
    source ${test//_test.sh/.sh}
    source ${test}
    EXITCODE=0
    # convention for function names is
    # functions with prefix 'Test' will be executed
    # and the output will pass/fail the pipeline
    for testFunc in $(typeset -f | grep '^Test.*()' | awk '{print $1}'); do
      if eval "${testFunc} >> ${temp_file}"; then
        setgreen
        printf "."
        setdefault
      else
        EXITCODE=1
        setred
        echo "(test failed !!!!! )"
        echo ${testFunc}
        cat ${temp_file}
        echo
        echo "----------------------------------------------------"
        echo
        setdefault
      fi
      rm ${temp_file}
    done
    exit $EXITCODE
  )
  EXITCODE=$?
done

if [[ ${EXITCODE} == 0 ]];then
   setgreen
   echo
   echo "Test Suite Passed"
   setdefault
else
   setred
   echo
   echo "Test Suite Failed"
   setdefault
fi
exit ${EXITCODE}
