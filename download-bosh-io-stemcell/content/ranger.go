package content

import (
	"errors"
	"fmt"
)

type Ranger struct {
	numHunks int
}

func NewRanger(hunks int) Ranger {
	return Ranger{
		numHunks: hunks,
	}
}

func (r Ranger) BuildRange(contentLength int64) ([]string, error) {
	if contentLength == 0 {
		return []string{}, errors.New("content length cannot be zero")
	}

	var ranges []string
	hunkSize := contentLength / int64(r.numHunks)
	if hunkSize == 0 {
		hunkSize = 2
	}

	iterations := (contentLength / hunkSize)
	remainder := contentLength % int64(hunkSize)

	for i := int64(0); i < int64(iterations); i++ {
		lowerByte := i * hunkSize
		upperByte := ((i + 1) * hunkSize) - 1
		if i == int64(iterations-1) {
			upperByte += remainder
		}
		bytes := fmt.Sprintf("%d-%d", lowerByte, upperByte)
		ranges = append(ranges, bytes)
	}

	return ranges, nil
}
