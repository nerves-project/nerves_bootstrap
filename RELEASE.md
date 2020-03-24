# Nerves Bootstrap Release Procedure

1. Create a branch/PR for the Bootstrap release (e.g. `0.5.x`)
1. Remove the `-dev` from `mix.exs` file on `nerves_bootstrap` (e.g.`0.5.0-dev`
   to `0.5.0`)
1. Update the `mix nerves.new` Mix task to use the latest `nerves`,
    `nerves_runtime`, and `nerves_bootstrap`
1. Review commits since previous release and make sure `CHANGELOG.md` is
    accurate
1. Obtain review approval from at least one other Nerves team member
1. Merge the release PR into `master` (with `--no-ff`) and tag the merge commit
   as `vX.Y.Z`
1. Run `mix archive.build` to build the archive.
1. Run `mix hex.publish` to update hex.pm. This is the main way that people
   should be obtaining the bootstrap archive.
1. Checkout the
    [nerves-project/archives](https://github.com/nerves-project/archives)
    repository
1. Copy `nerves_bootstrap-x.y.z.ez` to the archives repository
1. Copy the new bootstrap archive to `nerves_bootstrap.ez` as well and commit.
   This will be referenced by Nerves users with old instructions or old Nerve
   archive versions.
1. Publish a release of `nerves_bootstrap` on GitHub with the notes in the
   `CHANGELOG.md`
1. On the `master` branch, bump the revision to the next planned release number
   and append `-dev` (e.g. `0.5.1-dev` or `0.6.0-dev` after a `0.5.0` release)
