# Contributing

Thanks for taking the time. This repo is the companion to a YouTube episode, so the main goal is that someone can follow the video and the docs and get the same result. Fixes that make that easier are the most welcome.

## Good contributions

- A setup step that didn't work for you, and what fixed it.
- A region, Azure CLI or Power Platform change that needed a different command, and the new command.
- A bug in the plug-in or a script, with the steps to reproduce it.
- Clearer docs or comments.
- Hardening, for example pinning the exact workspace host or a Bicep version of the network.

Bigger changes, like a new operation or a different data platform, are best discussed in an issue first, so we agree on the shape before you spend the time.

## Before you open a pull request

1. **Build it.** `cd plugin/DatabricksPrivatePlugin` then `dotnet build -c Release`: no errors and no new warnings. Every public member has an XML doc comment, a missing one shows up as warning CS1591.
2. **Test it in a demo environment**, with public access off on the workspace, and run every operation from the app once.
3. **Scrub it.** No tenant, subscription or environment IDs, client ids, cluster ids, workspace URLs, IP addresses from your network, email addresses or real names in code, docs, screenshots or commit messages. Use placeholders like `<your-org>`.
4. **Keep the guardrails.** Never log a token, never add a client secret or a personal access token, never widen the host check.
5. **Update the docs** that your change touches and add a line to `CHANGELOG.md`.

## Writing style for docs

Plain, friendly English, like explaining to a colleague. Short sentences. No em dashes.

## Security issues

Please don't open a public issue for a security problem. See [SECURITY.md](SECURITY.md).

By contributing you agree that your work is released under the [MIT License](LICENSE).
