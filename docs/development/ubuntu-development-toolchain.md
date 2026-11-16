# Ubuntu development toolchain (C/C++, CMake, Node.js and pnpm)

This guide installs a practical development toolchain on Ubuntu 26.04 LTS and related Ubuntu releases. It is suitable for native C/C++ projects such as SDKs and libraries, as well as JavaScript/TypeScript projects.

The commands use Ubuntu packages where practical. They do not add third-party PPAs.

## 1. Update APT

```bash
sudo apt update
sudo apt upgrade
```

## 2. C and C++ build tools

Install GCC/G++, Make, CMake, Ninja, Clang/LLVM, debugging tools and common build utilities:

```bash
sudo apt install -y \
  build-essential cmake ninja-build pkg-config ccache \
  clang clangd clang-format clang-tidy lld \
  gdb lldb valgrind \
  git git-lfs curl wget ca-certificates \
  unzip zip xz-utils jq ripgrep tree
```

What the main tools provide:

- `build-essential`: GCC, G++, Make and standard development headers.
- `cmake` and `ninja-build`: configure and build CMake projects.
- `clang`, `clangd`, `clang-format`, `clang-tidy`: LLVM compiler, language server, formatter and static analysis.
- `gdb` / `lldb`: native debuggers.
- `valgrind`: memory and runtime error diagnostics.
- `ccache`: caches compiler outputs to speed up repeated builds.
- `pkg-config`: discovers compiler/linker flags for installed libraries.

## 3. Python tooling

```bash
sudo apt install -y python3 python3-venv python3-pip pipx
```

Use virtual environments for project-specific Python dependencies rather than installing packages into the system Python.

## 4. Node.js and npm

Ubuntu 26.04 provides Node.js 22.x in its repositories. Install it with:

```bash
sudo apt install -y nodejs npm
```

Check the installation:

```bash
node --version
npm --version
```

If a project requires a different Node.js major version, use a Node version manager or the project's documented runtime instead of mixing several system-wide Node installations.

## 5. pnpm

The official pnpm installer supports Linux and installs the standalone pnpm executable. It does not require Node.js merely to run pnpm:

```bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

Close and reopen the terminal, or reload the shell profile if needed. Then verify:

```bash
pnpm --version
```

If the command is not found, check that the pnpm install directory is on `PATH`. The installer normally configures the shell profile; consult the official pnpm installation guide for shell-specific details.

## 6. Optional tools

Install these only when a project needs them:

```bash
sudo apt install -y \
  meson cmake-format cppcheck doxygen graphviz \
  shellcheck shfmt
```

- `meson`: alternative build system.
- `cppcheck`: additional C/C++ static analysis.
- `doxygen` and `graphviz`: API documentation and diagrams.
- `shellcheck` and `shfmt`: shell-script linting and formatting.

## 7. Verify the toolchain

Run:

```bash
gcc --version
g++ --version
clang --version
cmake --version
ninja --version
make --version
gdb --version
node --version
npm --version
pnpm --version
python3 --version
git --version
```

## 8. Quick CMake smoke test

This creates a temporary project under `/tmp`, configures it with Ninja, builds it and runs the executable:

```bash
tmpdir="$(mktemp -d)"
cd "$tmpdir"

cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(toolchain_check LANGUAGES CXX)
add_executable(toolchain_check main.cpp)
EOF

cat > main.cpp <<'EOF'
#include <iostream>

int main() {
    std::cout << "CMake + C++ toolchain works!\\n";
    return 0;
}
EOF

cmake -S . -B build -G Ninja
cmake --build build
./build/toolchain_check

cd /
rm -rf "$tmpdir"
```

Expected output:

```text
CMake + C++ toolchain works!
```

## Notes

- This is a general workstation toolchain, not a list of mandatory dependencies for every project.
- Install project-specific development libraries only when the project's build instructions require them.
- Prefer Ubuntu's APT packages for system libraries and headers.
- Do not run CMake builds with `sudo`; build as the normal user and use `sudo` only for system package installation.
- pnpm's official installer is documented at https://pnpm.io/installation/.
