# ACP Package Browser

This directory contains the GitHub Pages site for browsing ACP packages.

## Features

- 🔍 **Search** - Find packages by keyword
- ⭐ **Sort** - By stars, recently updated, or name
- 📦 **Package Info** - View version, description, author, stars
- 📋 **Copy Install Command** - One-click copy to clipboard
- 🔗 **GitHub Links** - Direct links to repositories

## Local Development

Open `index.html` in your browser:

```bash
open docs/index.html
# or
python3 -m http.server 8000 --directory docs
# then visit http://localhost:8000
```

## Deployment

This site is automatically deployed to GitHub Pages from the `docs/` directory.

**URL**: https://prmichaelsen.github.io/agent-context-protocol/

## How It Works

1. User enters search term
2. Searches GitHub API for repositories with:
   - Name prefix: `acp-{query}`
   - Topic: `acp-package`
3. Fetches `package.yaml` from each repository
4. Filters to only show repos with valid `package.yaml`
5. Displays package info with install command

## API Rate Limits

- **Unauthenticated**: 60 requests/hour
- **Authenticated**: 5000 requests/hour

The browser uses unauthenticated requests for simplicity.

## Adding Your Package

To make your package discoverable:

1. **Create package** with `@acp.package-create`
2. **Add topic** `acp-package` to your GitHub repository
3. **Publish** with `@acp.package-publish`
4. **Wait** for GitHub to index (can take a few hours)

Your package will then appear in search results!
