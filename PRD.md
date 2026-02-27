# WellPath — Product Requirements Document (PRD)

Version: 2.0
Status: MVP Definition (Web-First)
Owner: Product / Engineering

---

# 1. Executive Summary

WellPath is a web-first fitness marketplace and personal wellness tracking platform built using Flutter (Web) and Firebase.

The purpose of this MVP is to validate three core assumptions:

1. Users are willing to discover and book local trainers through a browser-based platform.
2. Trainers are willing to publish availability and manage bookings digitally.
3. Users will consistently log simple wellness data when friction is low and reminders are present.

This MVP intentionally excludes advanced features such as payments, social networking, AI analytics, and wearable integrations. The objective is to validate real usage behavior with the smallest viable system before expanding functionality.

---

# 2. Problem Statement

In many local markets, fitness discovery and booking are informal and fragmented. Users rely on messaging apps, calls, or social media to schedule sessions. Meanwhile, personal wellness tracking is handled separately through unrelated global applications.

This creates three inefficiencies:

* Scheduling friction and double-booking risks
* Lack of structured availability visibility
* Disconnection between personal tracking and real-world training sessions

WellPath addresses these inefficiencies through a unified web platform that combines trainer discovery, booking, and lightweight wellness tracking.

---

# 3. Why Web-First

The MVP is web-first for the following reasons:

* Lower barrier to entry for users and trainers (no installation required)
* Faster iteration and deployment
* Easier pilot testing and sharing via URL
* Reduced distribution friction compared to app store deployment

The architecture remains compatible with future Android and iOS builds using the same Flutter codebase.

---

# 4. Target Users

## 4.1 Primary Users

1. Individual Users

   * Age: 18–45
   * Access to a modern browser (mobile or desktop)
   * Interested in booking trainers and tracking basic wellness data

2. Trainers

   * Independent or gym-affiliated
   * Need structured availability management
   * Want predictable scheduling and digital visibility

## 4.2 Excluded for MVP

* Enterprise gym management dashboards
* Corporate wellness administrators
* Medical practitioners

The MVP focuses strictly on Users and Trainers.

---

# 5. Geographic Scope

Initial pilot target: Mombasa.

Rationale:

* Controlled early adoption
* Easier onboarding of first trainers
* Manageable validation environment

The system is architecturally location-agnostic and supports future expansion.

---

# 6. MVP Feature Set (Strict Scope)

The MVP consists of exactly three functional pillars.

## 6.1 Feature 1 — Discovery and Booking

### User Capabilities

* Browse trainer listings
* View trainer profile (photo, specialties, description)
* View available time slots
* Book an available slot
* Receive booking confirmation notification (browser push or email fallback)

### Trainer Capabilities

* Publish availability slots
* View booking requests
* Confirm or cancel bookings

### System Requirements

* Booking must be atomic
* Double booking must be prevented
* Booking creation must occur via Cloud Function
* Slot locking must be transactionally enforced

### Out of Scope

* Payment processing
* Recurring bookings
* In-app messaging

---

## 6.2 Feature 2 — Personal Wellness Logging

Users can log three data types only:

1. Workout (duration + optional type)
2. Water intake (numeric)
3. Sleep hours (numeric)

### Dashboard View

* Weekly totals
* Basic goal tracking (one goal per type optional)

### Design Principle

Logging must be fast and minimal. The interaction should take less than 10 seconds.

---

## 6.3 Feature 3 — Notifications and Reminders

The system provides:

* Booking confirmation notifications (web push where supported)
* Daily reminder to log wellness data (opt-in)

If browser push is not supported, fallback mechanisms may include email notifications.

---

# 7. Roles and Permissions (MVP)

Two active roles:

1. User
2. Trainer

A system-level Admin role exists for moderation and support but is not a primary UI persona.

Permissions are enforced through Firebase Authentication custom claims and Firestore security rules.

---

# 8. Non-Functional Requirements

## Performance

* Core page loads under 2 seconds on standard broadband/mobile network
* Booking transaction response under 2 seconds

## Reliability

* Booking operations must be transaction-safe
* Wellness logs must persist reliably even with intermittent connectivity

## Security

* Role-based access enforcement
* All transactional validation handled server-side
* Firestore rules must prevent unauthorized writes

## Scalability

* Firestore indexed queries for trainer discovery
* Architecture must support eventual mobile builds without structural refactor

## Compatibility

* Modern browsers (Chrome, Edge, Firefox)
* Responsive layout for mobile web

---

# 9. Success Metrics (MVP Validation)

The MVP is validated if during pilot phase:

1. At least 10 distinct users complete bookings
2. At least 5 trainers actively publish availability
3. At least 30% of users log wellness data 3+ times per week
4. Zero double-booking incidents

Qualitative validation:

* Positive usability feedback from at least 5 pilot participants

---

# 10. Assumptions

* Users are comfortable signing up with email/password
* Trainers will manually manage availability
* Browser push notifications are supported for a majority of users
* Web-first approach reduces friction in pilot adoption

---

# 11. Risks and Mitigations

Risk: Browser push inconsistencies
Mitigation: Implement email fallback notifications.

Risk: Low trainer adoption
Mitigation: Pre-onboard pilot trainers before public testing.

Risk: Booking race conditions
Mitigation: Transactional locking via Cloud Functions.

Risk: Scope creep
Mitigation: Strict adherence to this PRD.

---

# 12. Explicit Non-Goals (MVP)

The following are intentionally excluded:

* Payment integration
* Messaging system
* Social feed or community features
* Advanced analytics dashboards
* AI-based recommendations
* Wearable device integration
* Multi-branch gym management

---

# 13. Exit Criteria for MVP Completion

The MVP is complete when:

* All three core features function end-to-end on web
* Security rules pass validation testing
* Booking transactions are proven safe
* System is deployable via Firebase Hosting
* Test plan has been executed and documented

---

# 14. Long-Term Direction (Context Only)

Post-validation expansion may include:

* Payment processing integration
* Native mobile deployment (Android/iOS)
* Corporate wellness dashboards
* Advanced trainer tools
* Regional scaling

Expansion will occur only after behavioral validation of the core system.

---

# 15. Guiding Principle

This MVP prioritizes validation over feature accumulation.

Every feature must:

* Directly validate a core assumption
* Be measurable
* Avoid unnecessary architectural complexity

WellPath is designed to launch lean, validate quickly, and evolve deliberately.
