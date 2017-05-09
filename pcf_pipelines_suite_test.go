package pcf_pipelines_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

func TestPcfPipelines(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PcfPipelines Suite")
}
