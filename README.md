# OTEL (OpenTelemetry) Bash

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

`otel-bash` is a bash library to instrument, debug and trace bash scripts automatically with OpenTelemetry.

## Prerequisites
- Bash `3.2+` or `4.x`
- [`otel-cli` v1](https://github.com/serkan-ozal/otel-cli)

## Setup

1. Add `otel-bash` in the beginning (for ex. just after bash she-bang `#!/bin/bash`) of your script 

  - Source `otel-bash.sh` in your script:
    ```bash
    . "${OTEL_BASH_PATH}/otel_bash.sh"
    # or
    # source "${OTEL_BASH_PATH}/otel_bash.sh"
    ```

  - or get the **latest** version of the `otel-bash` from remote:
    ```bash
    . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/master/otel_bash.sh)"
    # or if your bash supports process substitution (version "4.x")
    # . <(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/master/otel_bash.sh)
    ```

  - or get specific version (`v<version>`) of the `otel-bash` from remote (For example, `v0.0.1` for the `0.0.1` version of the `otel-bash`):
    ```bash
    . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/v0.0.1/otel_bash.sh)"
    # or if your bash supports process substitution (version "4.x")
    # . <(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/v0.0.1/otel_bash.sh)
    ```

2. Run your script by configuring OTLP `HTTP/JSON` endpoint

  ```bash
  OTEL_EXPORTER_OTLP_ENDPOINT=<OTLP_ENDPOINT_URL> ./<your-script>.sh
  ```

  - ### Run With Jaeger

    - Run Jaeger as OTLP HTTP/JSON endpoint active:
      ```bash
      docker run -d --name jaeger -p 4318:4318 -p 16686:16686 jaegertracing/all-in-one:1.47
      ```

    - Make sure that Jaeger works by opening Jaeger UI at [http://localhost:16686](http://localhost:16686)

    - Run your script with Jaeger OTLP HTTP/JSON endpoint config:
      ```bash
      OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 ../<your-script>.sh
      ```

    - Search your traces in Jaeger UI
      ![Search Traces](./examples/release-process/images/search-trace.png)

    - And see your trace in Jaeger UI
      ![See Trace](./examples/release-process/images/see-trace.png)

  - ### Run With OTEL SaaS Vendors

    - Run your script with your OTEL Saas vendor OTLP HTTP/JSON endpoint and API authentication token configs: 
      ```bash
      OTEL_EXPORTER_OTLP_ENDPOINT=<YOUR-OTEL-VENDOR-OTLP-ENDPOINT> \
      OTEL_EXPORTER_OTLP_HEADERS=<YOUR-OTEL-VENDOR-API-AUTH-HEADER-NAME>=<YOUR-OTEL-VENDOR-API-AUTH-TOKEN> \
      ./<your-script>.sh
      ```

## Configuration

| Environment Variable                                                 | Mandatory | Choices                                              | Default Value | Description                                    | Example                                                               |
|----------------------------------------------------------------------|-----------|------------------------------------------------------|---------------|------------------------------------------------|-----------------------------------------------------------------------|
| `OTEL_EXPORTER_OTLP_ENDPOINT=<otlp-endpoint-url>`                    | YES       |                                                      |               | OTEL Exporter OTLP endpoint                    | `OTEL_EXPORTER_OTLP_ENDPOINT=https://collector.otel.io`               |
| `OTEL_EXPORTER_OTLP_HEADERS=<api-auth-header-name>=<api-auth-token>` | NO        |                                                      |               | OTEL Exporter OTLP endpoint API auth token     | `OTEL_EXPORTER_OTLP_HEADERS=x-vendor-api-key=abcdefgh-12345678`       |
| `TRACEPARENT=<traceparent-header>`                                   | NO        |                                                      |               | Traceparent header in W3C trace context format | `TRACEPARENT=00-84b54e9330faae5350f0dd8673c98146-279fa73bc935cc05-01` |
| `OTEL_CLI_SERVER_PORT=<port-no>`                                     | NO        |                                                      | `7777`        | OTEL CLI server port to start on               | `OTEL_CLI_SERVER_PORT=1234`                                           |
| `OTEL_BASH_LOG_LEVEL=<log-level>`                                    | NO        | - `DEBUG` <br> - `INFO` <br> - `WARN` <br> - `ERROR` | `WARN`        | Configure log level                            | `OTEL_BASH_LOG_LEVEL=DEBUG`                                           | 

## Examples

You can find examples under `examples` directory:
- [`Release Process` example](./examples/release-process/README.md)

## Roadmap

- Export traces to `otel-cli` over local HTTP call instead of running `otel-cli` process to reduce `otel-cli` overhead

## Issues and Feedback

[![Issues](https://img.shields.io/github/issues/serkan-ozal/otel-bash.svg)](https://github.com/serkan-ozal/otel-bash/issues?q=is%3Aopen+is%3Aissue)
[![Closed issues](https://img.shields.io/github/issues-closed/serkan-ozal/otel-bash.svg)](https://github.com/serkan-ozal/otel-bash/issues?q=is%3Aissue+is%3Aclosed)

Please use [GitHub Issues](https://github.com/serkan-ozal/otel-bash/issues) for any bug report, feature request and support.

## Contribution

[![Pull requests](https://img.shields.io/github/issues-pr/serkan-ozal/otel-bash.svg)](https://github.com/serkan-ozal/otel-bash/pulls?q=is%3Aopen+is%3Apr)
[![Closed pull requests](https://img.shields.io/github/issues-pr-closed/serkan-ozal/otel-bash.svg)](https://github.com/serkan-ozal/otel-bash/pulls?q=is%3Apr+is%3Aclosed)
[![Contributors](https://img.shields.io/github/contributors/serkan-ozal/otel-bash.svg)]()

If you would like to contribute, please
- Fork the repository on GitHub and clone your fork.
- Create a branch for your changes and make your changes on it.
- Send a pull request by explaining clearly what is your contribution.

> Tip:
> Please check the existing pull requests for similar contributions and
> consider submit an issue to discuss the proposed feature before writing code.

## License

Licensed under [Apache License 2.0](LICENSE).
