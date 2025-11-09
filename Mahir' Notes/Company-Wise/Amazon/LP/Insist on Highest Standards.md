
# Story-1

**S (Situation):**

In our regulatory reporting pipelines, different teams performed data validation in an ad-hoc manner.

Each workflow implemented its **own custom checks**, often duplicated, inconsistent, and sometimes incomplete.

This caused frequent **late-stage data issues**, escalations close to reporting deadlines, and manual fixes by engineers at the last minute.



**T (Task):**

I felt the validation quality was **below the standard required** for high-confidence regulatory submissions.

I wanted to introduce a **consistent, automated validation layer** that would ensure data accuracy _before_ downstream processing — without slowing execution or increasing operational load.



**A (Action):**

- I proposed building a **centralized Checks & Controls Framework** that could run validation rules at scale in a standardised way.

- To avoid tightly coupling rules into code, I designed it so **business users could define validation logic dynamically** using configurations exposed via **Spring Boot REST APIs**.

- I built:

- A **schema-driven rule engine** supporting thresholds, conditional logic, and cross-system data consistency checks.

- A **distributed processing layer in Spark** to handle validation of **hundreds of GBs** efficiently.

- Real-time **alerting and dashboards** so data issues could be caught early and corrected quickly.


- I then worked with data stewards and compliance teams to **migrate existing manual checks** into the new platform and trained teams on usage.




**R (Result):**

- Validation coverage became **consistent and fully traceable**, eliminating ambiguity in data quality decisions.

- Pre-processing errors were detected **hours earlier**, reducing last-minute escalation incidents significantly.

- Large-scale datasets (hundreds of GBs) were validated **within minutes** using distributed execution.

- This framework was later adopted across **multiple regulatory workflows**, becoming a **standardized quality gate** in our data pipeline ecosystem.
