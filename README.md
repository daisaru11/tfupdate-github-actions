# tfupdate-github-actions

Github Actions for [tfupdate](https://github.com/minamijoyo/tfupdate).

This action runs tfupdate, and create Pull Requests if new versions of terraform or providers are found.


## Usage

```
on:
  schedule:
    - cron:  '0 0 * * *'

jobs:
  test_terraform_job:
    runs-on: ubuntu-latest
    name: Update terraform versions
    steps:
    - name: "Checkout"
      uses: actions/checkout@v1
    - name: tfupdate
      uses: daisaru11/tfupdate-github-actions@v1
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        tfupdate_subcommand: terraform
        tfupdate_path: './workspaces'

  test_provider_job:
    runs-on: ubuntu-latest
    name: Update provider versions
    steps:
    - name: "Checkout"
      uses: actions/checkout@v1
    - name: tfupdate
      uses: daisaru11/tfupdate-github-actions@v1
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        tfupdate_subcommand: provider
        tfupdate_path: './workspaces'
        tfupdate_provider_name: aws
```

You can see examples of Pull Requests to be created [here](https://github.com/daisaru11/tfupdate-github-actions-example/pulls).
