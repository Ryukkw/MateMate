# Origin of the code

MateMate is an independently maintained distribution based on FirstMate by Kun Chen.
All 524 tracked files from the local upstream checkout at commit
`40c50ea8843c5b6a5351db8352675537252b653e` were imported on 2026-09-09.
The MIT license and copyright notice are preserved in `LICENSE`.

Original project: https://github.com/kunchenguid/firstmate

The original README is saved at `docs/FIRSTMATE-UPSTREAM.md`. The original three
GitHub Actions workflows are saved under `docs/upstream-workflows/` for reference,
rather than automatically applying the upstream maintainer's CI/PR policies.
Runtime scripts, skills, Pi extensions, documentation and tests are included
directly in this repository. There is no submodule or installer clone of FirstMate.

Internal fm-* command names and firstmate protocol identifiers are retained for
compatibility. The user-facing distribution is MateMate. Its origin is
https://github.com/Ryukkw/MateMate and updates should come from that repository.

Pi, Herdr, Treehouse, No Mistakes and AXI packages remain separately installed
third-party dependencies with their own licenses. Their source code and Git
history are not part of this import. The original FirstMate Git history is also
not imported: MateMate tracks a complete source snapshot and its own changes.
