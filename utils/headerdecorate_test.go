package utils_test

import (
	"bytes"
	"fmt"
	"time"

	. "github.com/c0-ops/the-tool/utils"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	errwrap "github.com/pkg/errors"
)

type fakeErrWriter struct {
	Err error
}

func (s *fakeErrWriter) Write(p []byte) (n int, err error) {
	return 0, s.Err
}

var _ = Describe("HeaderDecorate", func() {
	Context("when decoration is un-successful", func() {
		var controlErr = fmt.Errorf("my fake error")
		var fakeWriter *fakeErrWriter
		var err error
		BeforeEach(func() {
			fakeWriter = &fakeErrWriter{
				Err: controlErr,
			}
			err = HeaderDecorate(fakeWriter, "", "", "")
		})

		It("should return an error", func() {
			Ω(err).Should(HaveOccurred())
			Ω(errwrap.Cause(err)).Should(Equal(controlErr))
		})
	})
	Context("when called with a writer and a yaml string", func() {
		var writer *bytes.Buffer
		var controlYaml = "blah"
		var controlVersion = "v0.0.0"
		var controlDate = fmt.Sprint(time.Now())

		BeforeEach(func() {
			writer = bytes.NewBuffer(nil)
			HeaderDecorate(writer, controlYaml, controlDate, controlVersion)
		})

		It("should decorate the yaml string with a header containing timestamp and version", func() {
			Ω(writer.String()).Should(ContainSubstring(controlYaml))
			Ω(writer.String()).Should(ContainSubstring(controlVersion))
			Ω(writer.String()).Should(ContainSubstring(controlDate))
		})
	})
})
