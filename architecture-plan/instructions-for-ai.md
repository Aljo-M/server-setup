# Instructions for AI Assistant

This document outlines how the AI assistant should interact with the architecture plan documentation.

## Purpose of the Architecture Plan

The architecture plan in `readme.md` is a living document that will guide the development of our Next.js frontend and ASP.NET Core backend project. It is structured to cover all key aspects of the architecture, from project overview to future enhancements.

## How to Use the Architecture Plan

- **Follow the Table of Contents:** The `readme.md` file is organized with a Table of Contents to easily navigate to specific sections.
- **Work Through Checkboxes:** Each section contains checkboxes `[ ]` or `[x]` to track progress.
  - Use `replace_in_file` to update checkboxes from `[ ]` to `[x]` as sections are completed or detailed.
- **Fill in Placeholders:** Many sections contain placeholders like:
  > _E.g., Next.js 14.x_
  > Replace these placeholders with concrete decisions and details as they are defined.
- **Add Detail and Depth:** Expand on the points in each section with specific details relevant to the project.
- **Use Mermaid Diagrams:** System diagrams and other visual aids can be added using Mermaid syntax within the markdown.

## Journaling Requests

- **Create a Journal:** Maintain a `journal.md` file in the `architecture-plan` folder.
- **Document Each Request:** For every request from the user related to the architecture plan, add a short description in the `journal.md` file.
- **Format of Journal Entries:** Each entry should include:
  - Date and Time: e.g., `2025-04-18 19:45 Europe/Ljubljana`
  - Request Description: A concise summary of the user's request.

## Example Workflow

1. **User Request:** "Update the Next.js version in the architecture plan to Next.js 15."
2. **AI Action:**
   - Update `architecture-plan/readme.md` using `replace_in_file` to change the Next.js version placeholder.
   - Add an entry to `architecture-plan/journal.md` documenting the request.

## Keeping Documentation Up-to-Date

- Regularly review and update the `readme.md` to reflect the current architecture and decisions.
- Ensure all changes are tracked in the `journal.md`.

By following these instructions, the AI assistant can effectively manage and contribute to the architecture plan documentation.
