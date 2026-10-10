This directory's skill file is copied unmodified from the Leonxlnx "Taste Skill"
repository (its default frontend design skill, upstream commit 717446e, 2026-10-09),
licensed under the MIT License: https://github.com/Leonxlnx/taste-skill

Purpose: frontend design guidance for landing pages, portfolios and redesigns,
so generated pages do not look generic. It contains no scripts.

Reviewed before adding, with SkillSpector v2.12.0 (static analysis) plus a manual
source read. Score 46/100, severity MEDIUM, recommendation CAUTION, which is under
this repository's CI gate of 50. Each finding was traced to its source line:

- The two HIGH "hidden instructions" hits match an example HTML placeholder comment
  that the skill tells the agent to leave inside generated pages when no real image
  exists. It is page content, not a directive aimed at the agent. False positive.
- The MEDIUM "autonomy" hit refers to the skill's three design-dial defaults, which
  the user overrides in conversation rather than by editing the file. Harmless.
- The three MEDIUM "unpinned package runner" hits are the standard shadcn/ui install
  command in the appendix, which only matters if you ask for a shadcn-based project.
- Static coverage was reported as partial. Every file was checked for zero-width,
  bidirectional and other invisible Unicode characters: none found. The non-ASCII
  characters present are visible punctuation and math symbols.
- No network calls, file reads, credential access, persistence or memory
  instructions anywhere in the file.
