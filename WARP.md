# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This is a fork of [modular/mojo-gpu-puzzles](https://github.com/modular/mojo-gpu-puzzles), an interactive educational project for learning GPU programming in Mojo🔥 through solving puzzles. The puzzles are hosted at [puzzles.modular.com](https://puzzles.modular.com).

The repository contains 34 GPU programming puzzles (p01-p34) that progress from basic GPU operations to advanced topics like tensor cores, custom PyTorch operations, and cluster programming.

## Project Structure

- `problems/` - Puzzle templates with tasks to complete (contains solution code with "FILL ME IN" comments)
- `problems-original/` - Clean puzzle templates without solutions (reference/backup)
- `solutions/` - Complete solutions and test harness
- `book/` - mdBook documentation served at puzzles.modular.com
- `scripts/` - Utility scripts for GPU detection and specifications

### Puzzle Types

1. **Pure Mojo puzzles (p01-p16, p23-p34)**: Run with `mojo problems/pXX/pXX.mojo`
2. **Mojo packages with Python (p17-p19)**: Require building `.mojopkg` first, then run with Python
3. **Python + PyTorch custom ops (p20-p22)**: Python scripts using custom Mojo kernels via PyTorch

Some puzzles have `_layout_tensor` variants that use Mojo's `LayoutTensor` API instead of raw pointers.

## Package Management

**Primary: pixi** (recommended and required for some puzzles)
- Handles Mojo/MAX from conda, PyPI packages, GPU dependencies
- Manages multiple GPU vendor environments (nvidia/amd/apple)

**Secondary: uv**
- Lighter alternative but doesn't support all puzzles
- Requires GPU-specific extras: `uv pip install -e ".[nvidia]"` or `".[amd]"`

## Common Commands

### Running Puzzles

```bash
# Pure Mojo puzzles
pixi run pXX              # e.g., pixi run p01
mojo problems/pXX/pXX.mojo

# Mojo packages (p17-p19)
pixi run p17              # Handles packaging + Python execution
# Manual: mojo package problems/p17/op -o problems/p17/op.mojopkg && python problems/p17/p17.py

# Python puzzles (p20-p22)
pixi run p20
# Manual: python problems/p20/p20.py
```

### Testing

```bash
# Run all puzzle solutions
pixi run tests            # Executes solutions/run.sh

# Test specific puzzle
pixi run tests pXX        # e.g., pixi run tests p05

# Manually run solution
mojo solutions/pXX/pXX.mojo
python solutions/pXX/pXX.py
```

### Code Quality

```bash
# Format code
pixi run format           # Formats problems/ and solutions/

# Check formatting (CI)
pixi run format-check     # Validates formatting without changes
```

### GPU Debugging (NVIDIA only)

```bash
# Individual sanitizers
pixi run memcheck pXX     # Detect memory errors
pixi run racecheck pXX    # Detect race conditions
pixi run synccheck pXX    # Detect synchronization errors
pixi run initcheck pXX    # Detect uninitialized memory access

# Run all sanitizers
pixi run sanitizers pXX

# Manual invocation
pixi run compute-sanitizer --tool memcheck mojo solutions/pXX/pXX.mojo
```

### GPU Information

```bash
# Basic GPU info (NVIDIA)
pixi run gpu-info

# Complete architectural specs (all vendors)
pixi run gpu-specs        # Works on NVIDIA/AMD/Apple Silicon
```

### Documentation

```bash
# Build and serve the puzzle book locally
pixi run book             # Opens browser to http://localhost:3000

# Build without serving
pixi run build-book

# Clean build artifacts
pixi run clean
```

### Visualisations

```bash
# Generate puzzle visualisations
pixi run vizXX            # e.g., pixi run viz01
pixi run thread_indexing  # Thread indexing visualisation
pixi run rooflineviz      # Roofline model visualisation

# Generate all animations
pixi run generate-animations

# Clean visualisation artifacts
pixi run clean-animations
```

### Cleanup

```bash
pixi run clean-profiles   # Remove profiling artifacts (*.sqlite, *.nsys-rep, etc.)
pixi run clean-all        # Clean animations + profiles
```

## Architecture

### GPU Abstraction Layers

The codebase demonstrates three integration approaches:

1. **Low-level GPU (p01-p16)**: Direct GPU programming with `gpu` module
   - `gpu.thread_idx`, `gpu.block_idx`, `gpu.grid_dim`
   - `DeviceContext` for buffer management
   - Manual kernel launches with `enqueue_function_checked`

2. **MAX Graph (p17-p19)**: Graph-based custom operations
   - Compile Mojo kernels to `.mojopkg` packages
   - Register operations with `@compiler.register`
   - Integrate with MAX's graph execution engine

3. **PyTorch Integration (p20-p22)**: PyTorch custom operations
   - Same Mojo kernels, different Python binding
   - Uses `max.torch.CustomOpLibrary`
   - Seamless PyTorch tensor integration

### Platform Support

**GPU Compute Requirements:**
- p16, p19, p22, p28, p29, p33: Require NVIDIA Compute ≥8.0 (Ampere: RTX 30xx, A100+)
- p34: Requires NVIDIA Compute ≥9.0 (Hopper: H100+)

**Platform-specific limitations:**
- AMD: p09, p10, p30-p34 not supported
- Apple Silicon: p09, p10, p20-p22, p29-p34 not supported

The test harness (`solutions/run.sh`) automatically detects platform and skips unsupported puzzles.

### Key Concepts by Puzzle Range

- **p01-p08**: Thread/block indexing, memory access patterns, shared memory
- **p09-p16**: Atomics, reductions, matrix operations, tensor cores
- **p17-p19**: Custom operations in MAX Graph
- **p20-p22**: PyTorch integration and custom autograd
- **p23-p33**: Advanced GPU patterns (warp primitives, cooperative groups, async)
- **p34**: Cluster programming (Hopper H100+)

## Development Workflow

### Working on Puzzles

1. Edit puzzle file in `problems/pXX/`
2. Test your solution: `pixi run pXX` or `mojo problems/pXX/pXX.mojo`
3. Compare with reference: `just pdiff pXX` (shows diff against `problems-original/`)
4. Verify against official solution in `solutions/pXX/`

### Format Before Committing

```bash
pixi run format
```

The CI pipeline checks formatting and runs all tests on NVIDIA GPU runners.

## Using `uv` (Alternative)

For users preferring `uv` over `pixi`:

```bash
# Setup
uv venv && source .venv/bin/activate
uv pip install -e ".[nvidia]"  # or ".[amd]"

# Run puzzles using poe tasks
uv run poe p01
uv run poe tests
uv run poe gpu-specs
```

Note: Some features (mdbook, animations, sanitizers) only work with `pixi`.

## Justfile Commands

The repository includes a `justfile` for convenient command shortcuts:

```bash
# List all available just commands
just --list

# Show all available pixi tasks
just pixi-tasks

# Show diff for a puzzle against its original template
just pdiff p04                  # Compare p04.mojo
just pdiff p04_layout_tensor    # Compare p04_layout_tensor.mojo

# List all puzzles
just puzzles

# Run a puzzle
just run p04                    # Equivalent to: pixi run p04

# Test a specific puzzle solution
just test p04                   # Equivalent to: pixi run tests p04

# Test all solutions
just test-all                   # Equivalent to: pixi run tests

# Format code
just format                     # Equivalent to: pixi run format

# Check formatting
just format-check               # Equivalent to: pixi run format-check

# Show GPU specs
just gpu-specs                  # Equivalent to: pixi run gpu-specs

# Build and serve book
just book                       # Equivalent to: pixi run book

# Cleanup
just clean-profiles             # Remove profiling artifacts
just clean-all                  # Clean all generated files
```

## Important Notes

- This is a **fork** of the upstream repository - upstream changes in modular/mojo-gpu-puzzles should be reviewed for incorporation
- `problems/` directory contains solutions mixed with templates (look for "FILL ME IN" and "✅ Solution code" comments)
- `problems-original/` maintains clean templates without solutions
- GPU is required to run puzzles - CPU fallback not supported for kernel execution
- Some puzzles generate profiling/debugging files (*.sqlite, *.nsys-rep) - use `pixi run clean-profiles` to remove them
