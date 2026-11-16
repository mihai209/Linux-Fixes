# Linux Fixes

A community-maintained knowledge base of documented Linux problems, troubleshooting steps, and verified solutions.

The goal is simple: turn real troubleshooting experiences into clear, reusable Markdown documentation that helps other Linux users.

## Contents

Browse [docs/](docs/) for troubleshooting guides, or use [INDEX.md](INDEX.md).

- Applications
- Package managers
- Desktop environments
- Graphics and display servers
- Hardware
- Networking
- System administration

## Interactive Linux System Assistant

Want to inspect your Linux system and choose which tools or diagnostics you need? Run the interactive assistant directly from your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/mihai209/Linux-Fixes/main/scripts/linux-assistant.sh | bash
```

Copy the command above, paste it into a terminal, and press Enter. The assistant detects system information and hardware, then offers optional categories such as driver recommendations, development tools (C/C++, CMake, Node.js, pnpm), Zsh with Atuin command-history search, multimedia diagnostics, network tools, and system utilities.

**You stay in control:** the script asks before installing packages or running driver installation commands. Review the script before running it if you want to inspect exactly what it does: [scripts/linux-assistant.sh](scripts/linux-assistant.sh).

## Documentation standards

Every guide should distinguish between observed symptoms, environment, confirmed root cause, workaround, verified solution, and unresolved items.

Do not present guesses as confirmed fixes. Redact usernames, hostnames, serial numbers, tokens, IP addresses, and other private information from logs before publishing.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and use [the problem template](templates/problem-template.md).

## License

MIT. See [LICENSE](LICENSE).
