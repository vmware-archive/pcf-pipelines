package main_test

import (
	"testing"

	"github.com/onsi/gomega/gexec"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestDownloadBoshIoStemcell(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "download-bosh-io-stemcell")
}

var (
	pathToMain string
)

var _ = BeforeSuite(func() {
	var err error
	pathToMain, err = gexec.Build("github.com/c0-ops/concourse-tasks-bundle/download-bosh-io-stemcell")
	Expect(err).NotTo(HaveOccurred())
})

var _ = AfterSuite(func() {
	gexec.CleanupBuildArtifacts()
})
