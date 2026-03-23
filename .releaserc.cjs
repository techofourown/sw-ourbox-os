module.exports = {
  branches: ['main'],
  tagFormat: 'v${version}',
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    [
      '@semantic-release/exec',
      {
        prepareCmd:
          'python3 tools/release-control/advance-approved-snapshot.py v${nextRelease.version}',
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: ['release/approved-upstream-inputs.json'],
        message:
          'chore(release): advance approved snapshot to v${nextRelease.version}\n\n' +
          'Auto-advance approved-upstream-inputs snapshot as part of\n' +
          'the v${nextRelease.version} release.',
      },
    ],
    '@semantic-release/github',
  ],
};
