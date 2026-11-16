# Mesa

Guides for Mesa, OpenGL, Vulkan, Zink, and GPU driver troubleshooting will be indexed here.

Useful diagnostics (install the relevant diagnostic tools with your distribution's package manager if needed):

```bash
glxinfo -B
vulkaninfo --summary
```

Record the GPU model, active kernel driver, Mesa version, and whether the issue occurs outside sandboxed applications.
