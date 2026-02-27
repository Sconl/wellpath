# WellPath — Technical Architecture Document (TAD)

Version: 1.0
Status: Web-First MVP Architecture
Owner: Engineering

---

# 1. Architectural Overview

WellPath is a web-first application built using Flutter Web for the frontend and Firebase as the backend platform.

The system follows a client–serverless architecture:

* Frontend: Flutter Web (single codebase, future-ready for mobile)
* Backend Services: Firebase (Authentication, Firestore, Cloud Functions, Hosting, Cloud Messaging)
* Hosting: Firebase Hosting

The architecture is intentionally simple to minimize operational overhead while maintaining transactional safety and scalability.

---

# 2. High-Level System Components

## 2.1 Client Layer (Flutter Web)

Responsibilities:

* UI rendering (responsive layout)
* Role-based navigation (User vs Trainer)
* Form validation (non-authoritative)
* Firestore read operations
* Calling secured Cloud Functions
* Local state management

The client is considered untrusted. All critical validation and transactional logic is handled server-side.

---

## 2.2 Authentication Layer (Firebase Authentication)

Method:

* Email / Password (MVP)

Role Handling:

* Custom claims define role: `user` or `trainer`
* Claims assigned via Admin SDK or privileged Cloud Function

Security Principle:
Authentication establishes identity. Authorization is enforced via Firestore Security Rules and Cloud Functions.

---

## 2.3 Database Layer (Cloud Firestore)

Firestore is used for:

* User profiles
* Trainer profiles
* Availability slots
* Bookings
* Wellness logs

Firestore was selected because:

* Real-time updates (trainer booking changes)
* Built-in offline persistence
* Scalable document model
* Tight integration with Firebase Auth

---

# 3. Data Model Design

## 3.1 Collections Overview

users/{userId}

* role
* name
* email
* createdAt

trainers/{trainerId}

* name
* specialties
* bio
* photoUrl
* location
* createdAt

availability/{slotId}

* trainerId
* startTime
* endTime
* status (available | booked | cancelled)

bookings/{bookingId}

* trainerId
* userId
* slotId
* status (pending | confirmed | cancelled)
* createdAt

wellnessLogs/{logId}

* userId
* type (workout | water | sleep)
* value
* timestamp

---

# 4. Booking Transaction Architecture

Booking is the most critical transactional flow in the system.

## 4.1 Design Principles

* Prevent double booking
* Enforce atomicity
* Ensure idempotency
* Avoid client-side booking writes

## 4.2 Flow

1. User selects available slot
2. Client calls a callable Cloud Function: createBooking
3. Function executes Firestore transaction:

   * Read slot
   * Verify status == available
   * Update slot status to booked
   * Create booking document
4. Return success/failure

All slot state changes occur inside a transaction.

---

# 5. Wellness Logging Architecture

Wellness logs are lower risk than bookings and may be written directly from client, subject to security rules.

Rules enforce:

* User can only write logs where userId == request.auth.uid
* No cross-user writes allowed

Firestore offline persistence ensures logs created offline will sync automatically.

---

# 6. Security Architecture

Security is enforced at three layers:

1. Authentication (identity)
2. Firestore Security Rules (authorization)
3. Cloud Functions (transactional validation)

Key principles:

* Users cannot modify trainer data
* Trainers cannot modify other trainers' slots
* Bookings cannot be manually edited by client
* Role claims validated in rules

Sensitive operations are server-mediated.

---

# 7. Notification Architecture

Primary mechanism: Firebase Cloud Messaging (Web Push)

Events triggering notifications:

* Booking confirmation
* Booking cancellation
* Daily wellness reminder

Implementation:

* Booking-related notifications triggered from Cloud Functions
* Daily reminder triggered via scheduled Cloud Function (Pub/Sub scheduler)

Fallback strategy:
If push is unsupported, optional email notification integration (future enhancement).

---

# 8. Hosting and Deployment

Frontend Deployment:

* Flutter Web build output deployed to Firebase Hosting

Backend Deployment:

* Cloud Functions deployed via Firebase CLI
* Firestore rules deployed via CLI

Environment Strategy:

* Separate Firebase projects for dev and production
* Environment configuration stored securely

---

# 9. Performance Considerations

* Indexed queries for trainer lookup
* Pagination for trainer lists
* Avoid large document nesting
* Keep booking transaction reads minimal

---

# 10. Scalability Strategy

The architecture supports:

* Horizontal scaling via Firestore auto-scaling
* Stateless Cloud Functions
* Migration to mobile builds without backend redesign

Potential future enhancements:

* Geo-queries for location filtering
* Payment integration service
* Dedicated analytics pipeline

---

# 11. Failure Handling Strategy

Booking Failure Cases:

* Slot already booked
* Network timeout
* Function execution failure

Mitigation:

* Clear error messages returned to client
* Retry-safe idempotent transaction logic

Offline Mode:

* Wellness logs queue locally
* Booking disabled when offline (to prevent race conflicts)

---

# 12. Architectural Trade-Offs

Decision: Firestore instead of relational DB
Reason: Faster development, real-time sync, native Firebase integration.

Decision: Serverless backend instead of custom Node server
Reason: Reduced operational overhead, automatic scaling.

Decision: Web-first instead of mobile-first
Reason: Faster iteration, easier pilot distribution.

---

# 13. Architectural Principles

1. Keep the client thin
2. Centralize transactional logic
3. Enforce least privilege
4. Avoid premature optimization
5. Build for validation before expansion

---

# 14. Readiness Criteria

Architecture is considered production-ready for MVP when:

* All booking flows pass transactional tests
* Security rules block unauthorized writes
* Notifications trigger reliably
* Deployment process is repeatable

This document defines the structural foundation of the WellPath MVP system.
