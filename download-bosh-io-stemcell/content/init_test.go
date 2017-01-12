package content_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

func TestContentrange(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "tasks/future/download-bosh-io-stemcell/content")
}
