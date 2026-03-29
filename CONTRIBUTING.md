# Contributing to Accessibility Scan Workshop

Thank you for contributing to this workshop. Follow these guidelines to maintain
consistency across all labs.

## How to Contribute

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/your-change`
3. Make your changes following the style guide below
4. Test locally with `bundle exec jekyll serve`
5. Submit a pull request

## Lab Authoring Style Guide

### Voice and Tone

- Use second-person voice ("you", "your")
- Use present tense and active voice
- Keep instructions direct and concise
- Avoid jargon without explanation

### Lab Document Structure

Every lab follows this structure:

```markdown
---
permalink: /labs/lab-XX
title: "Lab XX: Title"
description: "Brief description"
---

# Lab XX: Title

| | |
|---|---|
| **Duration** | XX min |
| **Level** | Beginner / Intermediate / Advanced |
| **Prerequisites** | Lab NN |

## Learning Objectives

- Objective 1
- Objective 2

## Exercises

### Exercise X.1: Title

Step-by-step instructions...

## Verification Checkpoint

- [ ] Check 1
- [ ] Check 2

## Next Steps

Proceed to [Lab NN: Title](lab-NN.md).
```

### Code Blocks

- Always specify the language: ````powershell`, ````bash`, ````json`, etc.
- Show expected output in separate blocks when relevant
- Use `> [!NOTE]` for informational callouts
- Use `> [!TIP]` for helpful suggestions
- Use `> [!WARNING]` for caution notices

### Screenshots

- Store in `images/lab-XX/` directories
- Name format: `lab-XX-descriptive-name.png`
- Reference format: `![Alt text](../images/lab-XX/filename.png)`
- Every screenshot directory has a `README.md` inventory
- Alt text must be descriptive for accessibility

### Cross-References

- Use relative links between labs: `[Lab 01](lab-01.md)`
- Use relative links for images: `../images/lab-XX/filename.png`

### Delivery Tier Annotations

Mark exercises that require Azure with:

```markdown
> [!NOTE]
> This exercise requires an Azure subscription (full-day tier only).
```
