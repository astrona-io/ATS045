---
draft: true
exam_objectives:
  - Admission Control
---
# Admission Control

This section covers admission control. It explains where admission sits in a request, Pod Security Admission and validating admission policy, and admission webhooks with their failure behavior and exceptions.

The section has one module, Admission Policy And Extension Trust. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Place admission in the request path and tell it apart from authorization
- Enforce a Pod Security level with namespace labels
- Write a validating admission policy and a binding with the right action and scope
- Explain how failure policy, selectors and exceptions decide real coverage
- Test a rule with a server-side dry run

## Contents

| Item | What it is |
| --- | --- |
| The Admission Chain And Built-In Controllers | Reading part |
| Pod Security Admission And Validating Admission Policy | Reading part |
| Admission Webhooks, Failure And Exceptions | Reading part |
| Summary | Reading part |
| Enforce A Pod Standard And Write A Validation Policy | Graded module lab (intermediate) |
| Close The Admission Gaps In Starfleet | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
