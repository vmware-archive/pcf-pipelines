package pcf_pipelines_test

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	yaml "gopkg.in/yaml.v2"

	"github.com/concourse/atc"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("pcf-pipelines", func() {
	placeholderRegexp := regexp.MustCompile("{{[a-zA-Z0-9-_]+}}")

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatalf("failed to get working dir: %s", err)
	}

	baseDir := filepath.Base(cwd)

	var pipelinePaths []string
	err = filepath.Walk(cwd, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if filepath.Base(path) == "pipeline.yml" {
			relPipelinePath, err := filepath.Rel(cwd, path)
			if err != nil {
				return err
			}
			pipelinePaths = append(pipelinePaths, relPipelinePath)
		}

		return nil
	})
	if err != nil {
		log.Fatalf("failed to walk: %s", err)
	}

	for _, path := range pipelinePaths {
		pipelinePath := path

		Context(fmt.Sprintf("pipeline at %s", pipelinePath), func() {
			var config atc.Config

			BeforeEach(func() {
				configBytes, err := ioutil.ReadFile(pipelinePath)
				Expect(err).NotTo(HaveOccurred())

				cleanConfigBytes := placeholderRegexp.ReplaceAll(configBytes, []byte("example"))
				err = yaml.Unmarshal(cleanConfigBytes, &config)
				Expect(err).NotTo(HaveOccurred())
			})

			It("specifies all and only the params that the pipeline's tasks expect", func() {
				for _, job := range config.Jobs {
					for _, task := range allTasksInPlan(&job.Plan, []atc.PlanConfig{}) {
						var configParams []string
						for k := range task.Params {
							configParams = append(configParams, k)
						}

						if strings.HasPrefix(task.TaskConfigPath, baseDir) {
							taskPath := strings.TrimPrefix(task.TaskConfigPath, baseDir+"/")
							relpath, err := filepath.Rel(cwd, filepath.Join(cwd, taskPath))
							Expect(err).NotTo(HaveOccurred())

							bs, err := ioutil.ReadFile(relpath)
							Expect(err).NotTo(HaveOccurred())

							taskConfig := atc.TaskConfig{}
							err = yaml.Unmarshal(bs, &taskConfig)
							Expect(err).NotTo(HaveOccurred())

							var taskParams []string
							for k := range taskConfig.Params {
								taskParams = append(taskParams, k)
							}

							for _, expected := range taskParams {
								Expect(configParams).To(ContainElement(expected), fmt.Sprintf("Found error in the following pipeline:\n    %s\n\nin reference to the following task:\n    %s\n", pipelinePath, taskPath))
							}

							var extras []string
							for _, configParam := range configParams {
								found := false

								for _, taskParam := range taskParams {
									if configParam == taskParam {
										found = true
										break
									}
								}

								if found {
									continue
								}

								extras = append(extras, configParam)
							}

							Expect(extras).To(BeEmpty(), fmt.Sprintf("Found error in the following pipeline:\n    %s\n\nin reference to the following task:\n    %s\n", pipelinePath, taskPath))
						}
					}
				}
			})
		})
	}
})

func allTasksInPlan(seq *atc.PlanSequence, tasks []atc.PlanConfig) []atc.PlanConfig {
	for _, planConfig := range *seq {
		if planConfig.Aggregate != nil {
			tasks = append(tasks, allTasksInPlan(planConfig.Aggregate, tasks)...)
		}
		if planConfig.Do != nil {
			tasks = append(tasks, allTasksInPlan(planConfig.Do, tasks)...)
		}
		if planConfig.Task != "" {
			tasks = append(tasks, planConfig)
		}
	}

	return tasks
}

func taskConfigsForJob(job atc.JobConfig) []atc.PlanConfig {
	tasks := []atc.PlanConfig{}

	for _, planConfig := range job.Plan {
		if planConfig.Task != "" {
			tasks = append(tasks, planConfig)
		}
	}

	return tasks
}
