# bats (Bash Automated Testing System) (bats)

Installs bats-core, bats-support, bats-assert, and bats-mock for shell script testing.

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/features/bats:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| batsVersion | bats-core version to install. Accepts with or without a leading 'v' (e.g. '1.13.0' or 'v1.13.0'). | string | 1.13.0 |
| batsSupportVersion | bats-support version to install. Accepts with or without a leading 'v'. | string | 0.3.0 |
| batsAssertVersion | bats-assert version to install. Accepts with or without a leading 'v'. | string | 2.2.4 |
| batsMockVersion | bats-mock version to install. Accepts with or without a leading 'v'. | string | 1.2.5 |
