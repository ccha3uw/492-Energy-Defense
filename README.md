# GridGuard AI — Energy Sector Cybersecurity Defense

**Course:** INFO 498B — Agentic Cybersecurity with AI & LLMs | University of Washington  
**Team:** Arona Cho, Cloe Cha, Paulina Teran, Ryan Kelleher  
**My Role:** PM & Team Lead

---

## Overview

GridGuard AI is an agentic defense system for energy-sector cybersecurity professionals 
to detect threats in real time and manage access across critical infrastructure.

I led product strategy, stakeholder research, and roadmap decisions across 5 demo cycles — 
including direct interviews with Puget Sound Energy cyber defense employees to validate 
role-based workflow design.

---

## Product Decisions & Outcomes

**Stakeholder research → unified interface**  
Interviews with Puget Sound Energy revealed that splitting analysts across multiple tools 
was a top pain point. We redesigned around role-based interfaces (SOC Analyst, Security 
Engineer, System Administrator) to keep workflows consolidated.

**Model accuracy tradeoff → hybrid approach**  
After testing Qwen 0.6B/1.5B against Mistral 7B, smaller models hit ~45-60% detection 
accuracy vs. ~92% with Mistral — unacceptable for the use case. We pivoted to a hybrid 
rule-based + LLM architecture to balance speed and accuracy, and documented the tradeoff 
honestly in our final thesis.

**48-hour continuous deployment**  
Deployed on Hetzner cloud, processed 287 events, maintained 95.8% uptime, with 99.1% 
event processing success rate via automatic LLM fallback to rule-based analysis.

---

## Key Results

- 92% detection accuracy for known attack patterns (Mistral 7B)
- 95% recognition rate for injected brute-force and port scan attempts  
- <5 second mean time to detection per event
- 95.8% uptime over 48-hour continuous deployment

---

## What We Built

- Synthetic event generator (login, firewall, patch update events with realistic attack patterns)
- AI agent using Ollama (Mistral 7B) with automatic fallback to rule-based analysis
- Risk scoring engine with severity classification (Low → Critical)
- Role-based web dashboard for real-time monitoring and case review
- PostgreSQL backend with 4-table schema storing all security events and analyses

---

## Tech Stack

Python · FastAPI · PostgreSQL · Docker · Ollama (Mistral 7B) · Hetzner Cloud · Cursor · v0

---

## Deliverables

- [Final Paper](https://docs.google.com/document/d/1MLB-avnSvTWLlgeR6PMvMUAh4qnEAzf8bnf2sfPYxO8/edit?tab=t.0#heading=h.knpcf56rqc9h)  
- [Final Slides](https://www.figma.com/slides/TCuRCrIIHQBrGQtWCKIysC/492-Final?node-id=1-250&t=dXKeeceEVuEa7HF4-1)

---

**INFO 498B — Agentic Cybersecurity with AI & LLMs · University of Washington · Fall Quarter 2025**
