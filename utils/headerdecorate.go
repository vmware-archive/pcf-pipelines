package utils

import (
	"fmt"
	"io"

	errwrap "github.com/pkg/errors"
)

func HeaderDecorate(writer io.Writer, pipelineYaml string, dateString string, versionString string) error {
	var err error
	if _, err = fmt.Fprint(writer, fmt.Sprintf("# generated on: %v \n", dateString)); err != nil {
		return errwrap.Wrap(err, "Fprint failed to decorate with date")
	}

	if _, err = fmt.Fprint(writer, fmt.Sprintf("# generated with: the-tool upgrade-ert version - %v \n", versionString)); err != nil {
		return errwrap.Wrap(err, "Fprint failed to decorate with version")
	}

	if _, err = fmt.Fprint(writer, pipelineYaml); err != nil {
		return errwrap.Wrap(err, "Fprint failed to add the pipeline yaml")
	}
	return nil
}
