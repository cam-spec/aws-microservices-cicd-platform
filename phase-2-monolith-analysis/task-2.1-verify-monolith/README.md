\## Task 2.1 — Verify monolithic application availability



\### Objective

Confirm the monolithic web application is publicly reachable via the EC2 public IPv4 address.



\### Steps performed

\- Opened the \*\*EC2 console\*\* in \*\*us-east-1\*\*.

\- Located the instance named \*\*MonolithicAppServer\*\* and confirmed it was \*\*Running\*\*.

\- Verified security group inbound access included \*\*HTTP (80)\*\*.

\- Accessed the application using: `http://<PublicIPv4>`.



\### Result

The \*\*Monolithic Coffee Suppliers\*\* application loaded successfully in the browser.



\### Evidence

!\[Task 2.1 Evidence](task-2.1-monolith-home.png)



