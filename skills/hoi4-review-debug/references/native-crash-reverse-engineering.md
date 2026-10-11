# Native crash reverse engineering

Use this workflow only for crash and compatibility diagnosis of a lawfully
controlled game copy, dump, and mod setup. It is an operational safety baseline,
not legal advice. Applicable law, licence terms, employment or school policy,
and the facts of the requested act can change the result.

## Evidence and consent ladder

Do not treat one broad permission as approval for every later stage. Explain
what the next stage will access, change, or disclose, then obtain explicit
consent at each gate.

### Stage 0: logs and supplied evidence

Read the crash package, fresh logs, metadata, mod source, enabled dependency
source, and the user's exact pre-crash actions. Hash original dumps and binaries
before analysis. This stage does not authorize launching the game, installing
tools, attaching a debugger, or reverse engineering native code.

### Stage 1: minimum necessary WinDbg analysis

After consent, inspect the supplied dump read-only with the existing WinDbg or
CDB installation. Record the exception context, stack, modules, relevant
registers, nearby memory, RTTI/vtables, and only enough disassembly to identify
the affected engine class or mod-facing contract.

Classify confidence:

- **High:** the faulting instruction and operands, native object/class chain,
  specific script or data object, and an independent contradiction or
  concurrency/lifetime fact all agree.
- **Medium:** the native class and call path are credible, but the exact script
  object or corrupting writer is not identified.
- **Low:** the theory rests on the last log line, module presence, an export
  offset, or a generic access violation.

Stop at high confidence unless another narrowly stated question remains. At
medium or low confidence, report what is missing and ask whether the user
authorizes Stage 2. Do not silently broaden the analysis.

### Stage 2: maximum lawful static diagnosis

After separate consent and the legal/terms check below:

1. Detect an existing compatible Ghidra and JDK before downloading anything.
2. Acquire verified tools only if needed and separately authorized.
3. Analyze only the executable and modules needed for the crash question.
4. Map dump module base plus RVA into the matching binary.
5. Use strings, xrefs, RTTI, vtables, call graphs, decompiler output, structure
   recovery, and nearby constructors/destructors to reconstruct the relevant
   object path and lifetime.
6. Map the native path back to current script objects using identifiers,
   category ownership, token lengths, source strings, and dependency content.
7. Compare all active threads, locks, and parallel evaluators before concluding
   that a bad pointer was produced by the current thread.
8. Preserve notes as offsets, pseudocode summaries, and evidence statements.
   Do not publish substantial decompiled expression or unrelated proprietary
   implementation details.

"Maximum lawful" means the deepest analysis necessary for the compatibility
question, not unrestricted exploration. Never bypass DRM, anti-cheat, account
controls, authentication, encryption, or other access controls; extract
secrets; patch the executable; redistribute binaries; or investigate unrelated
features.

If confidence remains below high, state the unresolved writer, lifetime, or
reproduction question and ask for separate Stage 3 authorization.

### Stage 3: authorized dynamic diagnosis

This stage launches or attaches to a live process and can expose more user data.
Before it begins:

- reconfirm the governing jurisdiction and current platform/EULA terms;
- obtain explicit authorization to launch the game and attach a debugger;
- use offline single-player, the target mod, and only exact dependencies;
- back up saves, profiles, playsets, and launch options;
- exclude multiplayer, anti-cheat, DRM bypass, and third-party confidential
  data;
- tell the user that full dumps can contain paths, account names, chat text,
  document fragments, and other process memory; keep them local unless the user
  separately approves transfer.

Check current Steam and game terms before automating a launch. If automated
interaction is prohibited or unclear, have the user launch the lawful copy
manually and attach the debugger only after the process is running.

Choose the least invasive probe that can answer the open question:

- Create a full user-mode dump at the relevant state with WinDbg `.dump /ma`,
  or configure a local Windows Error Reporting dump for the target executable.
- Put a hardware data breakpoint such as `ba w4 <address>` or
  `ba w8 <address>` on the suspicious field. Match access width and alignment,
  and remember that x86/x64 hardware breakpoint slots are scarce.
- For heap objects whose addresses change, first break on the identified
  allocator, constructor, script-object creation path, or lookup; recover the
  object address and field offset for that run, then install the data
  breakpoint.
- Record module base/RVA, object allocation and destruction, thread, lock
  ownership, old/new field values, and the script object active at each hit.

Do not patch instructions or data to force a result. Reproduce the smallest
scenario, stop when the cause is established, hash the new evidence, and
restore any settings changed for the test.

## Tool acquisition and safety

Version numbers are time-sensitive. On 2026-07-24, the current verified Ghidra
release was 12.1.2 and its release documentation required a 64-bit JDK 21.
The official SHA-256 for that release archive was
`b62e81a0390618466c019c60d8c2f796ced2509c4c1aea4a37644a77272cf99d`;
this value identifies 12.1.2 only and must not be reused for a later release.
At execution time, resolve the latest stable official Ghidra release and follow
that release's JDK requirement; for a JDK 21 requirement, select the latest
Eclipse Temurin 21 LTS GA build for the user's OS and architecture. Never use a
GitHub-generated "Source code" archive as the Ghidra release package.

Official sources:

- Ghidra releases: <https://github.com/NationalSecurityAgency/ghidra/releases>
- Ghidra repository and installation requirements:
  <https://github.com/NationalSecurityAgency/ghidra>
- Eclipse Temurin releases: <https://adoptium.net/temurin/releases/>
- Adoptium release API: <https://api.adoptium.net/>

For every download:

1. Ask for download/install consent and prefer a portable archive where
   practical.
2. Resolve the final URL under the official publisher's domain or official
   GitHub release, and reject mirrors, ads, nightly builds, and early-access
   builds unless the user specifically requested one.
3. Record version, URL, byte size, UTC time, and SHA-256.
4. Verify the published checksum. For a Windows installer, also require a valid
   Authenticode signature from the expected publisher.
5. Scan the file with the installed antivirus. Inspect archive entries for
   absolute paths, `..` traversal, links escaping the destination, and
   unexpected launchable files before extraction.
6. Extract into a new isolated directory. Do not overwrite an existing tool
   installation and do not load third-party Ghidra extensions.
7. Stop on a missing/mismatched checksum, invalid signature, unexpected
   redirect, or antivirus finding. Report it instead of executing.

Keep the analyzed binary, Ghidra project, dumps, and reports local. Do not
upload them to public malware scanners, cloud decompilers, or repositories
without separate permission and a rights/privacy review.

## Jurisdiction routing

Language chooses the language of the question; it does not establish the
governing law. Ask every user where the analysis will occur and which country's
or territory's law applies. For English, explicitly ask which English-speaking
country and, for the United States, which state. For Chinese, offer Mainland
China, Taiwan, Hong Kong, Macau, or another jurisdiction. Ask equivalent
country/territory questions in Japanese and Russian.

Reusable questions:

- English: "Which country or territory's law applies where this analysis will
  be performed? If it is the United States, which state?"
- Simplified Chinese: "请确认本次分析实际进行地及适用法域：中国大陆、台湾、香港、
  澳门或其他国家/地区？若为其他地区，请说明国家及州/省。"
- Traditional Chinese: "請確認本次分析實際進行地及適用法域：中國大陸、臺灣、
  香港、澳門或其他國家／地區？若為其他地區，請說明國家及州／省。"
- Japanese: "この解析を実際に行う国・地域と、適用される法域を教えて
  ください。米国の場合は州も指定してください。"
- Russian: "Укажите страну или территорию, где будет выполняться анализ,
  и применимую юрисдикцию. Для США также укажите штат."

Also confirm lawful possession or licence, private/noncommercial crash or
interoperability purpose, applicable workplace/school policy, current platform
and game terms, and whether technical protection measures are involved. Use
facts already established in the session; ask only for missing or changed facts.

### Live legal and terms check

Before native disassembly, decompilation, or live debugging, perform a fresh
web search for the actual jurisdiction and intended operation. This reference
does not maintain legal URLs, domain allowlists, country-by-country legal
conclusions, or a period during which an old check is presumed current.

1. Search in the relevant jurisdiction's language for current primary law and
   official guidance on the particular act: program observation/testing,
   error correction, interoperability, decompilation, or debugger attachment.
   Discover the responsible legislature, official legislation database, or
   competent authority at execution time; verify the publisher and applicable
   territory rather than relying on a domain suffix or a search snippet.
2. Read the current consolidated text and relevant conditions. Check effective
   dates, amendments, local implementation, and any applicable copyright,
   technical-protection, contract, trade-secret, or access restrictions. Do not
   treat a remembered article number, old translation, or archived page as
   confirmation of the current rule.
3. Discover and read the current game publisher's EULA and the distribution
   platform's terms, including Steam's terms when the copy uses Steam. Check
   the requested diagnosis and any proposed automated interaction separately.
   A statutory exception, contract term, platform rule, and user authorization
   are separate considerations; one does not automatically settle the others.
4. In the task's report, record jurisdiction, intended act, sources actually
   consulted, source revision/effective date when available, access date, and
   the narrow conclusion or unresolved issue. Cite the URLs found in this
   lookup there; do not copy them into the skill, plugin manifest, or a fixed
   list of required websites. A research citation is not a standing network
   dependency or an endorsement of this community-maintained skill.
5. If browsing is unavailable or current applicability cannot be established,
   state the missing evidence and pause the dependent native analysis. Continue
   authorized Stage 0 log/source inspection where it does not depend on that
   conclusion; do not invent permission or substitute model memory for a check.

Recheck when the jurisdiction, scope, relevant law/terms, or facts change during
the task. Keep all findings specific to the proposed operation; this workflow
does not provide a blanket legal clearance for reverse engineering.

## Field-tested native-analysis lesson

In one HOI4 crash, the final `error.log` entry concerned equipment-variant
creation, but the native stack was evaluating decision AI. The access violation
occurred in a fixed-length string comparison for an `event_target:` token. RTTI
and object traversal led through country AI, decision status, decision,
decision category, compound triggers, a meta trigger, and a tag trigger. A
register held ASCII-shaped garbage where the captured object memory held a
valid country tag. Other worker threads were evaluating the same category and
contending on the same lock.

The category identity and token length mapped the object to one dependency
decision containing repeated dynamic tag meta-triggers. This supported an
engine lifetime/concurrency defect, with that dependency decision as a trigger
surface. The target mod did not define or override the decision; its other
errors could at most be timing amplifiers. Equipment errors remained real but
separate defects.

General rules:

- The last log line is temporal correlation, not a crash cause.
- Follow the faulting operands and native object chain, then map it to script.
- Compare register state with captured object memory; a callee that cannot
  produce the observed corruption points to stale, raced, or freed state.
- Inspect all threads and locks before blaming the current evaluator.
- Use RTTI, vtables, string lengths, identifiers, and category ownership
  together; no single clue is enough.
- Separate direct engine cause, script trigger surface, timing amplifier, and
  unrelated log defects.
- Report confidence explicitly and escalate only when the next stage can
  resolve a named missing fact.
