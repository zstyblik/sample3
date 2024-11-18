# dpetv2

## Application

Application is a simple Python script which gets weather forecast from
[OpenWeathermap] API for given city(by default Prague, Czech Rep.), generates
simple HTML page from [Jinja2] template, and stores data and HTML page on S3.

Application is capable of running either as AWS Lambda function or in Docker
container. `Dockerfile` is included, but hasn't been tested beyond localhost.
Also, it's not being built as part of pipeline, because it currently isn't used
for anything.

Dependencies can be found in `app/requirements/`. Requirements are split in
order to save CI minutes, because there is no reason to install everything in
order to lint the source code. Ideally, lint dependencies would be split even
further, but then there is a practical side of things and the current state is
fine for now.

![weather_app_demo][weather_app_demo]

### Environment variables

Mandatory variables:

* `WEATHER_API_KEY` - OpenWeathermap API key
* `WEATHER_S3_BUCKET` - Name of S3 bucket where data will be stored
* `WEATHER_SM_SECRET_NAME` - Name of Secrets manager secret which contains API
  key, but it might be used to store other variables, eg. `prod/weather/secrets`

Note that either `WEATHER_SM_SECRET_NAME` or `WEATHER_API_KEY` must be provided.

Other variables:

* `WEATHER_TOWN` - Name of town, eg. `prague`
* `WEATHER_COUNTRY` - Name of country, eg. `cz`
* `WEATHER_API_URL` - OpenWeathermap API URL, eg. `https://api.openweathermap.org`

## Architecture in brief

Architecture is as follows:

* CloudFront in order to serve HTML page
* S3 for storage
* Lamba function for data processing
* EventBridge rule in order to periodically trigger Lambda function
* Secrets Manager in order to store API key

Anything capable of scheduling and running(ECS, EKS, ...) Docker container
would be backup in case of Lambda wouldn't work.

Alternatives are S3 without CloudFront, ELB, EC2 with public IP address - there
are probably more. While S3 alone is capable of hosting and serving static HTML
files, it doesn't provide HTTPS which could and would be problematic due to
mixed content(images from OpenWeathermap are served over HTTPS). ELB has its
uses, however you have to pay for it whethere there is a traffic coming through
or not. Also, something has to serve that traffic. To use API Gateway, while
most likely possible, seemend like an abuse.

Secrets Manager is utilized in order to securely store API key.

## Terraform

* modules would normally be in a separate repository and versioned
* environments are separate, because you might use different accounts or even
  multiple providers
* terraform workspaces might actually be nice for DEV/review
* cleanup of DEV/review is, in my opinion, a bit unstable as it is
* production terraform fmt, validate and plan are available even in branches,
  because you don't want to find (problem) out when you're about to deploy into
  production. Unpopular question, but - separate pipeline?

## TODOs/problems

* Python - more unit tests
* Python - it might be nice to show historical data.
* HTML - design is nonexistent.
* HTML - better layout since one or two iterations weren't enough.
* gitlab - workaround for `git tag --push` which triggers pipeline was
  initially hard to figure out. This brought another set of problems which were
  resolved later on(at least for now).
* gitlab - script which creates new git tag might need more work.
* gitlab - it'd be nice to propagate git tag further down the line. Store new
  version(tag) into file and pass it down as an artifact, read as necessary?
* gitlab - terraform is no longer supported by gitlab, therefore "custom"
  solution is used instead. Also, there was a worry about version compatibility
  since gitlab provides, used to provide, only specific version of terraform.
* gitlab - "environment" is in need of improvement, eg. auto stop, on_stop,
  URL(if possible) etc.
* gitlab - spit some parts off into different files and maybe even parent-child
  pipelines(?), because `.gitlab-ci.yml` has gained some weight.
* how much should be in terraform for deploy depends. Sooner or later it will
  be too much and `terraform plan` will take too long, eg. everything around
  CloudFront takes long time, or AWS API limits will be reached.
* deployment of application should and could be verified by triggering Lambda
  and then waiting for data either to appear on S3 and/or check
  `Last-Modified`. Check through CDN should be done as well, if it is
  provisioned(CDN might not be provisioned in case of MR).

I probably forgot to add somethng.


![dpetv2_main_pipeline][dpetv2_main_pipeline]
![dpetv2_mr_pipeline][dpetv2_mr_pipeline]
![dpetv2_mr_pipeline_tests][dpetv2_mr_pipeline_tests]

[OpenWeathermap]: https://openweathermap.org/
[Jinja2]: https://pypi.org/project/Jinja2/
[weather_app_demo]: ../assets/weather_app_demo.png?raw=true
[dpetv2_main_pipeline]: ../assets/dpetv2_main_pipeline.png?raw=true
[dpetv2_mr_pipeline]: ../assets/dpetv2_mr_pipeline.png?raw=true
[dpetv2_mr_pipeline_tests]: ../assets/dpetv2_mr_pipeline_tests.png?raw=true
