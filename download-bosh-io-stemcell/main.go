package main

import (
	"archive/zip"
	"bytes"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"

	"github.com/c0-ops/concourse-tasks-bundle/download-bosh-io-stemcell/content"
	"github.com/cheggaaa/pb"

	yaml "gopkg.in/yaml.v2"
)

var (
	productFile string
	productName string
	iaasType    string
	downloadDir string
	Version     string
)

const routines = 20

type metadata struct {
	Criteria criteria `yaml:"stemcell_criteria"`
}

type criteria struct {
	Version string
	OS      string
}

var iaasStemcellPrefix = map[string]string{
	"aws":       "aws-xen-hvm",
	"openstack": "openstack-kvm",
	"vcloud":    "vcloud-esxi",
	"vsphere":   "vsphere-esxi",
	"azure":     "azure-hyperv",
	"gcp":       "google-kvm",
}

func main() {
	flag.StringVar(&productFile, "product-file", "", "product file to extract stemcell version from")
	flag.StringVar(&productName, "product-name", "", "product name")
	flag.StringVar(&iaasType, "iaas-type", "", "iaas of stemcell")
	flag.StringVar(&downloadDir, "download-dir", "", "directory to place downloaded stemcell in")

	flag.Parse()

	_, ok := iaasStemcellPrefix[iaasType]
	if !ok {
		log.Fatalf("Invalid IaaS: %s\n", iaasType)
	}

	logger := log.New(os.Stdout, "", log.LstdFlags)

	logger.Printf("Extracting 'metadata/%s.yml' from '%s'...\n", productName, productFile)
	zReader, err := zip.OpenReader(productFile)
	if err != nil {
		log.Fatalln(err)
	}

	tempYAML := bytes.NewBuffer([]byte{})

	for _, f := range zReader.File {
		if f.Name != fmt.Sprintf("metadata/%s.yml", productName) {
			continue
		}

		fh, err := f.Open()
		if err != nil {
			log.Fatalln(err)
		}

		_, err = io.Copy(tempYAML, fh)
		if err != nil {
			log.Fatalln(err)
		}
	}

	var meta metadata
	err = yaml.Unmarshal(tempYAML.Bytes(), &meta)
	if err != nil {
		log.Fatalln(err)
	}

	rawSuffix := ""
	if iaasType == "openstack" {
		rawSuffix = "-raw"
	}

	stemcellURL := fmt.Sprintf("https://bosh.io/d/stemcells/bosh-%s-%s-go_agent%s?v=%s", iaasStemcellPrefix[iaasType], meta.Criteria.OS, rawSuffix, meta.Criteria.Version)

	stemcell, err := os.Create(fmt.Sprintf("%s/bosh-stemcell-%s-%s-%s-go_agent%s.tgz", downloadDir, meta.Criteria.Version, iaasStemcellPrefix[iaasType], meta.Criteria.OS, rawSuffix))
	if err != nil {
		log.Fatalln(err)
	}

	defer stemcell.Close()

	resp, err := http.Head(stemcellURL)
	if err != nil {
		log.Fatalln(err)
	}

	stemcellURL = resp.Request.URL.String()

	ranger := content.NewRanger(routines)
	ranges, err := ranger.BuildRange(resp.ContentLength)
	if err != nil {
		log.Fatalln(err)
	}

	logger.Printf("Downloading stemcell from '%s'...\n", stemcellURL)

	var wg sync.WaitGroup
	bar := pb.New(int(resp.ContentLength))
	bar.ShowTimeLeft = false
	bar.Start()
	for _, r := range ranges {
		wg.Add(1)
		go func(byteRange string) {
			defer wg.Done()
			req, err := http.NewRequest("GET", stemcellURL, nil)
			if err != nil {
				log.Fatalln(err)
			}

			byteRangeHeader := fmt.Sprintf("bytes=%s", byteRange)
			req.Header.Add("Range", byteRangeHeader)

			resp, err := http.DefaultClient.Do(req)
			if err != nil {
				log.Fatalln(err)
			}

			defer resp.Body.Close()

			respBytes, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				log.Fatalln(err)
			}

			offset, err := strconv.Atoi(strings.Split(byteRange, "-")[0])
			if err != nil {
				log.Fatalln(err)
			}

			bytesWritten, err := stemcell.WriteAt(respBytes, int64(offset))
			if err != nil {
				log.Fatalln(err)
			}

			bar.Add(bytesWritten)
		}(r)
	}

	wg.Wait()
	bar.Finish()

	logger.Println("Done.")
}
