# Contributing

Thank you for your interest in contributing to bnfn-preview! This document outlines the guidelines for contributing to this project.

## Code of Conduct

Please note that this project follows the Zig Code of Conduct. By participating, you are expected to uphold this code.

## How to Contribute

### 1. Fork the Repository

- Click the "Fork" button in the top-right corner of this page
- Clone your forked repository locally

### 2. Set Up Your Development Environment

- Ensure you have Zig compiler installed (version 0.16.0 or later)
- Navigate to the project directory

### 3. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 4. Make Changes

- Write clean, idiomatic Zig code
- Follow the existing code style
- Ensure your code compiles without warnings

### 5. Test Your Changes

```bash
zig build
```

### 6. Commit Your Changes

```bash
git add <file>
git commit -m "Add your descriptive commit message"
```

### 7. Push and Submit a Pull Request

```bash
git push origin feature/your-feature-name
```

- Navigate to your forked repository
- Click "Compare & pull request"
- Fill in the pull request template
- Submit the pull request

## Code Review Process

- All pull requests are reviewed by maintainers
- Changes must pass CI checks (if any)
- Discussion may be requested if needed

## Project Structure

- `src/`: Source code files
- `zig-out/`: Build output directory
- `zig-cache/`: Zig cache directory

## License

This project is licensed under the MIT License.

## Questions?

If you have any questions about contributing, please:
1. Open an issue in the repository
2. Reach out to the maintainers via the issue tracker
3. Check the existing issues for similar topics

## Attribution

Thank you for contributing to this project! Your efforts help make Zig development more accessible and powerful.