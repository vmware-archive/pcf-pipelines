# Upgrade Tile Pipeline

This pipeline is used to keep your PCF foundation up to date with the latest
patch versions of PCF software from Pivotal Network. They are used to upgrade
patch versions of Elastic Runtime, and other service tiles. You will need one
pipeline per tile in your foundation, to keep every tile up to date.

It is important to note that the pipeline does not try to upgrade major or
minor versions, only patch versions. For example, if a new release of a tile
is released going from either `--.n.--` to `--.n+1.--` or `n.--.--` to
`n+1.--.--` the pipeline will not upgrade to these tile versions. It will
upgrade from `--.--.n` to `--.--.n+1`.

## Usage

1. Download the upgrade-tile pipeline from [Pivnet](https://network.pivotal.io/products/pcf-automation).

2. (Optional) Configure Schedule.

   In the `pipeline.yml` there is a `schedule` resource preconfigured to trigger
   the pipeline in 30 minute intervals every day.

   There are five parameters that can be modified to provide more fine grain
   control over when the pipeline upgrades tiles.

   * `interval`: This controls how often the pipeline is triggered. Defaults to
   `30m`.

   * `start` and `stop`: This controls what times of the day the resource is
   allowed to trigger the pipeline. For example, if the pipeline should only
   run in the middle of the night this could be set to:

      ```
      start: "11:00 PM"
      stop: "1:00 AM"
      ```

      The above configuration would give a two hour window for the pipeline to
      check for new versions.

      Defaults to:

      ```
      start: "12:00 AM"
      stop: "11:59 PM"
      ```

   * `location`: This is the timezone for `start`, `stop`, and `days`. Defaults
   to `America/Los_Angeles`.

   * `days`: This controls what days of the week the resource is allowed to trigger
   the pipeline. Defaults to every day.

3. Configure your `params.yml` file.

   This file contains parameters for the pipeline and the secrets necessary to
   communicate with PivNet and OpsMan. Fill it out with the necessary values and
   store it in a safe place.

4. [Set the pipeline](http://concourse-ci.org/single-page.html#fly-set-pipeline), using your updated params.yml:

   ```
   fly -t lite set-pipeline -p upgrade-your-tile -c pipeline.yml -l params.yml
   ```

5. Unpause the pipeline. The pipeline should then start triggering automatically.

---

## Customizing the pipeline

#### <a name="gated-apply-changes"> Adding a gate to the `Apply-Changes` job

If your intent is to run `Apply-Changes` only manually or on a schedule for your tile upgrades, then you can update the `trigger` parameter for the `apply-changes` job by using the  [gated-apply-changes-job.yml](https://github.com/pivotal-cf/pcf-pipelines/blob/master/operations/gated-apply-changes-job.yml) patch operation.

For each one of your `upgrade-tile` pipelines, run the following [`yaml-patch`](https://github.com/pivotal-cf/yaml-patch) command before running the corresponding `fly set-pipeline` command:

```
cat upgrade-tile/pipeline.yml | yaml-patch -o /operations/gated-apply-changes-job.yml > new-pipeline.yml
```

For a mechanism to run the `Apply-Changes` job manually or on a scheduled basis, refer to the ["apply-updates"](https://github.com/pivotal-cf/pcf-pipelines/blob/master/apply-updates) pipeline.


## Troubleshooting

## Known Issues

#### Issue: #### 
Since the upgrade-tile pipeline pulls stemcells from PivNet, if any of your tiles are using non-ubuntu stemcells (CentOS, for example) you won't be able to use the upgrade-tile pipeline to upgrade your tile. 

#### Error message: ####
   ```
   could not resolve template vars: yaml: line 67: did not find expected key”
   ```

   **Solution:** Please use the PivNet release of the pipelines. You will run into this issue if you use the GitHub v0.21.1 version of the pcf-pipelines release. As a fix, navigate to the upgrade-tile pipeline and to `pipeline.yml`. Remove the quotes around `"((product_globs))"` on line 67. You should be able to fly the pipeline now.

