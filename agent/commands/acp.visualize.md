# Command: visualize

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.visualize` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@acp-visualize NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active

---

**Purpose**: Generate and open interactive HTML visualizer for progress.yaml
**Category**: Visualization
**Frequency**: As Needed

---

## What This Command Does

This command opens the interactive progress visualizer in your default browser, automatically loading the current project's progress.yaml file for visualization.

**Features**:
- Visual milestone progress bars
- Interactive task lists
- Statistics dashboard
- Dark/light mode toggle
- Responsive design

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists
- [ ] `agent/scripts/progress-visualizer.html` exists
- [ ] Default browser configured

---

## Steps

### 1. Check for Visualizer

Verify visualizer file exists:

**Actions**:
- Check if `agent/scripts/progress-visualizer.html` exists
- If missing, report error and suggest running `@acp.version-update`

**Expected Outcome**: Visualizer file found

### 2. Start Visualizer Server

Run the visualizer script:

**Actions**:
```bash
./agent/scripts/acp.visualize.sh
```

**What it does**:
- Automatically loads `agent/progress.yaml`
- Embeds data directly into HTML (no file picker needed)
- Starts local HTTP server on available port (default: 8001)
- Opens browser automatically
- Keeps server running for refresh capability

**Expected Outcome**: Browser opens with progress data already loaded

### 3. Refresh as Needed

Keep server running and refresh browser after updating progress.yaml:

**Actions**:
- Make changes to progress.yaml
- Click "🔄 Refresh" button in visualizer
- Or press F5 in browser

**Expected Outcome**: Visualizer updates with latest data

---

## Verification

- [ ] Visualizer file exists
- [ ] Browser opens automatically
- [ ] Visualizer loads without errors
- [ ] Progress data displays correctly
- [ ] All milestones visible
- [ ] All tasks visible
- [ ] Statistics accurate

---

## Expected Output

### Browser Window

Interactive visualizer showing:
- Overall progress statistics
- Milestone cards with progress bars
- Expandable task lists
- Status indicators
- Estimate vs actual comparisons

### Console Output
```
✓ Opening progress visualizer...
✓ Browser opened
✓ Load agent/progress.yaml in the visualizer

Visualizer features:
- 📊 Visual milestone progress
- 📋 Interactive task lists
- 📈 Statistics dashboard
- 🎨 Dark/light mode
```

---

## Examples

### Example 1: Basic Usage

**Invocation**: `@acp.visualize`

**Result**: Opens visualizer in browser, user loads progress.yaml

### Example 2: After Completing Tasks

**Context**: Just completed several tasks, want to see progress

**Invocation**: `@acp.visualize`

**Result**: Opens visualizer showing updated progress with completed tasks

---

## Related Commands

- [`@acp.status`](acp.status.md) - Text-based status display
- [`@acp.report`](acp.report.md) - Generate session report
- [`@acp.sync`](acp.sync.md) - Sync documentation

---

## Troubleshooting

### Issue 1: Visualizer file not found

**Symptom**: Error "progress-visualizer.html not found"

**Solution**: Run `@acp.version-update` to get latest ACP files

### Issue 2: Browser doesn't open

**Symptom**: No browser window appears

**Solution**: Manually open `agent/scripts/progress-visualizer.html` in your browser

### Issue 3: YAML parsing error

**Symptom**: Visualizer shows parsing error

**Solution**: Validate progress.yaml with `@acp.validate`. Ensure it's valid YAML.

---

## Notes

- Visualizer works offline (except js-yaml CDN)
- Data stays in browser (not sent to server)
- Can share via URL hash (data encoded in URL)
- Print-friendly for presentations
- Responsive design works on mobile
- Dark/light mode preference saved

---

**Namespace**: acp
**Command**: visualize
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active
**Compatibility**: ACP 3.9.0+
**Author**: ACP Project
