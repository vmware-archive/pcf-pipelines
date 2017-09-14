# Upgrade Tile Pipeline

This pipeline is used to keep your PCF foundation up to date with the latest
patch versions of PCF software from Pivotal Network. They can upgrade Ops
Manager, Elastic Runtime, other tiles, and buildpacks. You will need one
pipeline per tile in your foundation, to keep every tile up to date.

It is important to note that the pipeline does not try to upgrade major or
minor versions, only patch versions. For example, if a new release of a tile
is released going from either `--.n.--` to `--.n+1.--` or `n.--.--` to
`n+1.--.--` the pipeline will not upgrade to these tile versions. It will
upgrade from `--.--.n` to `--.--.n+1`.

## Usage

1. Configure Schedule.

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

2. Configure your `params.yml` file.

This file contains parameters for the pipeline and the secrets necessary to
communicate with PivNet, OpsMan, and Git (if not using the PivNet resource
for `pcf-pipelines`). Fill it out with the necessary values and store it in
a safe place.

3. Apply `operations/use-pivnet-release.yml` to the `pipeline.yml` file to
switch the `pcf-pipelines` resource from using the git resource to the PivNet
release.

```
cat upgrade-tile/pipeline.yml | yaml-patch -o operations/use-pivnet-release.yml > upgrade-tile/pipeline_with_pivnet.yml
```


4. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated params.yml:

```
fly -t lite set-pipeline -p upgrade-your-tile -c upgrade-tile/pipeline_with_pivnet.yml -l upgrade-tile/params.yml
```

5. Unpause the pipeline. The pipeline should then start triggering automatically.
