# How This Course Is Made

You will trust a course more when you know how it is built. This page tells you how the content is written and checked, who is behind it, and how you can help make it better.

## How the content is written

The course aims at **Kubernetes 1.35**, and every tool is pinned to one version, for example **Istio 1.31.1** and **podinfo 6.15.0**. When a page says how a tool behaves, it means that version. Each playground installs or preloads exactly that version for you.

Facts come from real sources. They are checked against the official Kubernetes documentation and the reference pages of each tool. Each page explains what you need on the page itself, so you do not have to leave the course to look something up.

No command output is invented. When a page describes the result of a command, it describes it in words and says what to look for. Scan results are a special case: the list of known vulnerabilities changes every day, so the pages teach you how to read and filter a scan, not an exact count.

The graded labs check behaviour. A grader sends real requests between workloads, asks the API server whether an object would be admitted, and reads the same objects you do. Many graders also reject the change that only hides the problem, such as switching mTLS back to plain text, or setting a policy to only warn instead of deny. Each lab has a reference solution that `astrona test` runs against its own grader.

> [!WARNING]
> **The labs are not yet tested.** This version of the course was built from documentation and was checked statically: the lab and playground configurations validate, the scripts parse, and the YAML loads. No playground or lab has been booted and no grader has been run. Report any lab that fails to start, or that grades a correct answer as wrong.

The pages are written in plain English, for people who are not native English speakers and have no university degree. Words are written out in full, and each technical term gets a short, plain definition the first time it appears. The pages use the real technical terms, not metaphors, because those are the words you meet in the product, the error messages and the exam.

Finally, large parts of this course are drafted and edited with the help of AI tools. A maintainer reviews every change before it is published, and the technical checks above apply to all content, however it was written.

An exam objective can change. Maintainers record the date used for the curriculum map and revise the material when needed.

## Maintainers

A small group of people builds and looks after the course. The core maintainer is **Paris Nakita Kejser** ([@parisnakitakejser](https://github.com/parisnakitakejser)).

Every person who has changed the course is listed on the GitHub contributors page:
[github.com/astrona-io/ATS045/graphs/contributors](https://github.com/astrona-io/ATS045/graphs/contributors)

## Found a mistake? Report it

Even with these checks, mistakes slip through. If a command fails, a page says something wrong, or a lab grades a correct answer as wrong, please tell us. A good report takes four steps:

1. Open a new issue on GitHub: [github.com/astrona-io/ATS045/issues](https://github.com/astrona-io/ATS045/issues).
2. Say which page or lab it is (the file path is the easiest, for example `sections/section-010/module-01/labs/lab-01`).
3. Paste the command you ran and what you saw. Leave out passwords, tokens, private keys, signing keys or anything else private.
4. Say what you expected to happen instead.

Want to fix it yourself? Pull requests are welcome on the same repository.

## License

The course is published under the [Apache License 2.0](https://github.com/astrona-io/ATS045/blob/main/LICENSE). You are welcome to use it, share it and build on it under the terms of that license. Exam objectives belong to their respective owners; the lessons and practice questions are independently written.
