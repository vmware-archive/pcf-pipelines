#!/usr/bin/env bats

export TASK_PATH=tasks/extract-terraform

setup() {
  mkdir -p $TASK_PATH/terraform-bin
  mkdir -p $TASK_PATH/terraform-zip
  touch $TASK_PATH/terraform-zip/terraform
  zip -j $TASK_PATH/terraform-zip/terraform.zip $TASK_PATH/terraform-zip/terraform
  rm $TASK_PATH/terraform-zip/terraform
}

teardown() {
  rm -rf $TASK_PATH/terraform-bin
  rm -rf $TASK_PATH/terraform-zip
}

@test "givenTerraformZip_verifyTerraformBinaryIsAvalable" {
  pushd $TASK_PATH
    source task.sh
  popd
  ./$TASK_PATH/terraform-bin/terraform
  [ $? -eq 0 ]
}
