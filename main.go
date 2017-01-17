package main

import (
	"fmt"
	"os"
	"time"

	"github.com/c0-ops/the-tool/pipelines/upgrade-ert"
	"github.com/c0-ops/the-tool/utils"
	errwrap "github.com/pkg/errors"
	"github.com/urfave/cli"
)

// the-tool ert-upgrade
// --iaas-type blah

var Version = "v0.0.0"

func main() {
	app := cli.NewApp()
	app.Name = "the-tool"
	app.Usage = "generates versioned and prescribed concourse pipeline yamls"
	app.Commands = []cli.Command{
		{
			Name:    "upgrade-ert",
			Aliases: []string{"u-ert"},
			Usage:   "generates a pipeline which can be used to upgrade an existing ERT",
			Action: func(c *cli.Context) error {
				var err error
				fmt.Println("Generating pipeline yaml at: ./upgrade-ert.yml")
				fw, err := os.Create("./upgrade-ert.yml")
				defer fw.Close()

				if err = utils.HeaderDecorate(fw, upgradeert.PipelineYaml, fmt.Sprint(time.Now()), Version); err != nil {
					err = errwrap.Wrap(err, "HeaderDecorate failed")

				} else {
					fmt.Println("Finished generating pipeline yaml: ./upgrade-ert.yml")
				}
				return err
			},
		},
	}
	app.Run(os.Args)
}
