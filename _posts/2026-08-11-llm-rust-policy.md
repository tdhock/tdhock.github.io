---
layout: post
title: Rust LLM Policy
description: Requirements for disclosure in open-source contributions
---

Recently data.table added a LLM policy file, [AGENTS.md](https://github.com/Rdatatable/data.table/pull/7862).

That PR mentions the blog,
[rust-lang/rust is adopting an LLM policy](https://blog.rust-lang.org/inside-rust/2026/08/05/rust-langrust-is-adopting-an-llm-policy/).

These are similar to the documents I recently wrote:

- [R GSOC FAQ AI Policy](https://github.com/rstats-gsoc/gsoc2026/wiki/R-GSOC-FAQ#ai-policy)
- [animint2 CONTRIBUTING.md Avoid/declare AI code generation](https://github.com/animint/animint2/blob/master/.github/CONTRIBUTING.md#avoiddeclare-ai-code-generation)

Interestingly, the Rust blog emphasizes

- disclosure of AI generation in issue and PR comments (we want responses from a person, not a LLM)
- creating a community of experts, not a repo of artifacts

Other policies:

* Base R’s [note on using AI tools](https://www.r-project.org/bugs.html)
* Linux [AI Coding Assistants](https://docs.kernel.org/process/coding-assistants.html) says:
  * AI agents MUST NOT add Signed-off-by tags
  * AI agent can find and attempt fix bugs
  * AI agent must never send a bug report or patch; instead it must send to a person (reporter), who can report the issue/patch.
  * Minimize time a person needs to spend reviewing: "Indicate what could not be done. If the fix could not be built or tested, or if no reproducer could be produced, say so explicitly: maintainers currently waste too much time analyzing unverified reports and untested fixes."
* Linux [Tool-Generated Content](https://docs.kernel.org/process/generated-content.html) says
  * Understanding which portions of a contribution come from humans versus tools is helpful to maintain those resources and keep kernel development healthy.
  * These guidelines do not apply to tools that make trivial tweaks to preexisting content: spelling, rephrasing, completion, boilerplate, renaming, reformatting.
  * These guidelines apply when a meaningful amount of content in a kernel contribution was not written by a person in the Signed-off-by chain, but was instead created by a tool.
  * Detection of a problem and testing the fix for it is also part of the development process; if a tool was used to find a problem addressed by a change, that should be noted in the changelog. This not only gives credit where it is due, it also helps fellow developers find out about these tools.
  * If in doubt, choose transparency and assume these guidelines apply to your contribution.
  * [Developer’s Certificate of Origin](https://docs.kernel.org/process/submitting-patches.html#sign-your-work-the-developer-s-certificate-of-origin) (DCO)
  * If tools permit you to generate a contribution automatically, expect additional scrutiny in proportion to how much of it was generated.
    * Treat the contribution specially, for example, asking for extra testing, reviewing with extra scrutiny, or reviewing at a lower priority than human-generated content.
    * Ask for some other special steps, like asking the contributor to elaborate on how the tool or model was trained.
    * Ask the submitter to explain in more detail about the contribution so that the maintainer can be assured that the submitter fully understands how the code works.
    * Suggest a better prompt instead of suggesting specific code changes.
  * As with the output of any tooling, the result may be incorrect or inappropriate. You are expected to understand and to be able to defend everything you submit. If you are unable to do so, then do not submit the resulting changes. If you do so anyway, maintainers are entitled to reject your series without detailed review.
