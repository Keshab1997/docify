# Documents workspace improvements

This work is developed on `feat/documents-workspace`; `main` is not changed
until review and passing GitHub Actions checks. Existing guest mode, on-device
storage, the system fingerprint/PIN prompt, and opt-in Drive access stay intact.
No local SDK installation, builds, tests or analysis are used.

## Ordered implementation

1. **Safety**: preserve extensions, reject name conflicts, fail closed on phone
   authentication errors, protect document previews, and remember local deletions.
2. **Find and browse**: scoped search and type/star filters, recent files,
   favorites and tags, responsive folders, grid/list views, thumbnails and details.
3. **Manage and import**: multi-select actions, 30-day trash with undo/restore,
   import progress and duplicate-content choices, and friendly partial failures.
4. **Prepare applications**: pass saved files to existing tools and create local
   application kits with an attachment checklist and multi-file sharing.
5. **Backup visibility**: per-file pending/backed-up/failed state, selective retry,
   and truthful automatic-backup outcomes without new sign-in prompts.
6. **Optional text search**: user-triggered on-device OCR, never automatic uploads.

Each concern gets a focused conventional commit. Regression coverage is added
with the relevant change and executed only by GitHub Actions. Formatting patches
may be generated in Actions and applied as source edits in the workspace.

## Acceptance checklist

- [ ] Rename never changes format or replaces another document.
- [ ] Authentication errors and backgrounded previews never reveal documents.
- [ ] Deleted/trashed local files are not silently downloaded from Drive again.
- [ ] Search, filters, stars, tags and recents work without an account.
- [ ] Mobile, tablet and web use available space without hiding the add button.
- [ ] Selection supports move/share/trash and compatible tool actions.
- [ ] Trash is recoverable for 30 days and permanent deletion is explicit.
- [ ] Import reports individual failures, progress and duplicate choices.
- [ ] Tool shortcuts open with the selected documents already loaded.
- [ ] Application kits persist locally and show missing attachments.
- [ ] Backup badges and retries reflect actual outcomes, including partial failure.
- [ ] Optional OCR is local, opt-in and has a clear unsupported-platform fallback.
- [ ] GitHub Actions format, analysis, tests and web build pass.

## Compatibility notes

Existing document names and folder assignments are preserved. New local metadata
is additive; missing metadata never makes an existing file disappear. Trash and
local deletion markers do not delete the user's Google Drive copies. Web remains
a preview: document bytes currently live in memory and refresh clears those bytes;
no durable-web-storage claim is made by this change.
