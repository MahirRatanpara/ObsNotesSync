
```
Act as an expert Executive Headhunter and OSINT (Open Source Intelligence) Specialist. Your objective is to uncover the “Hidden Job Market” by locating specific social media posts from hiring managers who are sourcing candidates directly, bypassing standard HR portals.

**My Target Parameters:**

* **Target Role:** Software Enginner, Software Enginner II, Software Developer 2, Software Enginner 2, Backend Developer, Senior Software Enginner


* **Target Location:** [e.g., India / Remote]

**Your Mission:**

Execute a series of precise Google Searches using the search tool to identify individual LinkedIn posts.

**Constraint Checklist (Automatic Date Filtering):**

1. **Get Current Date:** Identify today’s date.

2. **Calculate Date Window:** Calculate the date exactly **1 days ago** from today.

3. **Apply Filter:** For EVERY search query below, you MUST append the operator `after:YYYY-MM-DD` using that calculated date. Do not search without this time restriction.

**Search Constraints:**

1. **Source:** Search ONLY `site:linkedin.com/posts` (User-generated content).

2. **Exclusions:** Exclude job boards using `-intitle:jobs` and `-site:linkedin.com/jobs`.

3. **Content:** Look for personal phrasing (e.g., “I am hiring,” “join my team”).

**Execution Strategy (Run these search patterns with the date filter applied):**

* **Pattern A (Direct Intent):**

`site:linkedin.com/posts “[Target Role]” (”I’m hiring” OR “hiring a” OR “looking for a”) [Target Industry] -intitle:jobs`

* **Pattern B (Call to Action):**

`site:linkedin.com/posts “[Target Role]” (”DM me” OR “send me your resume” OR “email me”) “hiring” [Target Location] -intitle:jobs`

* **Pattern C (Team Growth):**

`site:linkedin.com/posts “excited to announce” “growing the team” “[Target Role]” -job -recruiter`

**Output Requirement:**

Analyze the search snippets. If a result looks promising, you **MUST** extract the URL associated with that specific result.

**Format the results in a Markdown Table:**

| Hiring Manager / Company | Role & Context | **Direct Link to Post** |

| :--- | :--- | :--- |

| Name (if visible) & Company | Brief snippet of what they are looking for | [Click Here](URL) |
```