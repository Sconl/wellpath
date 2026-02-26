# WellPath

WellPath is a minimal, high‑leverage fitness marketplace and personal wellness tracking application built with Flutter and Firebase.

This repository contains the Android-first MVP of the product, along with its supporting Firebase backend configuration.

The goal of this project is not to build a feature-heavy fitness application, but to intentionally ship the smallest system that can validate real value for both users and trainers.

---

# Product Scope (MVP)

This MVP focuses strictly on three core capabilities. Each was selected based on leverage, implementation feasibility, and long-term architectural viability.

## 1. Discovery and Booking

Users can:

* Discover nearby gyms
* View trainer profiles
* View available time slots
* Book a session
* Receive booking confirmation via push notification

Why this matters:
Discovery and booking form the commercial backbone of the platform. If users cannot find trainers and schedule sessions reliably, the marketplace has no economic value. This feature proves that the system can facilitate real-world transactions between users and service providers.

Booking validation is handled server-side to ensure atomicity and prevent double booking.

---

## 2. Personal Wellness Logging and Dashboard

Users can log three simple wellness data points:

* Workout (duration and type)
* Water intake
* Sleep hours

The dashboard presents:

* Weekly totals
* Basic goal progress

Why this matters:
Tracking creates retention. Without personal data and visible progress, the product becomes a transactional booking tool only. These three data points were selected because they are high-signal and low-friction, making daily engagement realistic.

The system intentionally avoids complex health metrics at this stage.

---

## 3. Notifications and Reminders

The system sends:

* Booking confirmation notifications
* Daily reminders to log wellness data (opt-in)

Why this matters:
Notifications close the engagement loop. A booking without confirmation reduces trust. A tracking tool without reminders loses consistency. This feature increases reliability and retention without adding product complexity.

---

# Architecture Overview

The architecture is intentionally simple, scalable, and aligned with rapid iteration.

## Frontend

* Flutter (Android-first)
* Riverpod for state management
* Feature-first structure

Project structure:

```
lib/
  core/
  features/
    discovery_booking/
    tracking/
    notifications/
  main.dart
```

Why Flutter:
Flutter enables cross-platform development while allowing the MVP to focus on Android first. It provides consistent UI rendering and strong Firebase integration.

Why Riverpod:
State management becomes critical once authentication, bookings, and real-time updates are involved. Riverpod provides predictable state handling and scalability without excessive boilerplate.

---

## Backend (Firebase as a Service)

The backend uses Firebase services to minimize infrastructure management while maintaining production-grade capabilities.

Services used:

* Firebase Authentication
* Cloud Firestore
* Cloud Functions (Node.js)
* Firebase Cloud Messaging (FCM)
* Firebase Storage

System flow:

```
Flutter App
     ↓
Firebase Authentication
     ↓
Cloud Firestore
     ↓
Cloud Functions (for critical logic)
     ↓
Firebase Cloud Messaging
```

Why Firebase:
The MVP prioritizes speed of iteration and reduced operational overhead. Firebase provides authentication, database, messaging, and serverless execution without requiring custom server management.

Critical logic such as booking validation is handled through Cloud Functions to avoid trusting client-side operations.

---

# Firestore Data Model (MVP)

The data model is designed for clarity and future scalability while remaining minimal.

## users/{uid}

```
{ name, email, role, createdAt, photoUrl }
```

Stores core identity information.

## gyms/{gymId}

```
{ name, location: GeoPoint, address, photoUrl, ownerId }
```

Supports geolocation queries and marketplace discovery.

## trainers/{trainerId}

```
{ userId, displayName, specialties: [], photoUrl, hourlyIntro }
```

Separated from users to allow easier querying and indexing.

## trainer_slots/{slotId}

```
{ trainerId, startTimestamp, endTimestamp, isBooked }
```

Simple availability model for MVP. Slots are locked atomically during booking.

## bookings/{bookingId}

```
{ userId, trainerId, gymId, slotId, status, createdAt }
```

Represents the transactional core of the marketplace.

## users/{uid}/wellness_logs/{logId}

```
{ type: workout | water | sleep, value, metadata:{}, timestamp }
```

User-scoped subcollection to simplify security rules and improve read performance.

---

# Security Model

Security is enforced primarily through Firestore rules and Cloud Functions.

* Users may modify only their own wellness logs.
* Trainer availability can only be managed by the owning trainer.
* Bookings must be created via Cloud Function to prevent race conditions.
* Role-based access is enforced through custom claims and rules.

The client application is never trusted for transactional validation.

---

# Cloud Functions

## createBooking

Responsibilities:

* Validate slot availability atomically
* Prevent double booking
* Mark slot as booked
* Create booking record
* Send confirmation notifications

## sendDailyReminder (Scheduled)

Responsibilities:

* Identify users who opted into reminders
* Send push notifications via FCM

Cloud Functions isolate business logic from the client and ensure consistent behavior regardless of device or network state.

---

# Getting Started

## Prerequisites

* Flutter SDK
* Node.js (for Cloud Functions)
* Firebase CLI
* Android Studio or VS Code

## Clone the Repository

```
git clone <repository-url>
cd wellpath
```

## Firebase Setup

1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Enable Firestore
4. Enable Cloud Functions
5. Enable Cloud Messaging
6. Register the Android app in Firebase
7. Download `google-services.json` and place it in:

```
android/app/
```

## Install Dependencies

```
flutter pub get
```

## Run the Application

```
flutter run
```

---

# Testing Priorities

* Authentication edge cases
* Booking race condition prevention
* Firestore security rule enforcement
* Push notification delivery reliability
* Offline wellness log synchronization

The MVP should demonstrate correctness before feature expansion.

---

# Deployment

## Build Android APK

```
flutter build apk
```

## Deploy Cloud Functions

```
firebase deploy --only functions
```

## Deploy Firestore Rules

```
firebase deploy --only firestore:rules
```

---

# Product Direction Beyond MVP

Future development may include:

* Payment processing
* Corporate wellness dashboards
* Trainer management tools
* Advanced analytics
* Wearable integrations

These are intentionally excluded from the MVP to preserve focus and maintain architectural clarity.

---

# License

Here, I am thinking MIT Licence or Apache, both are open source, MIT being extremely permissive (If you, GRACE, are actually reading this code, research on the licenses and give me a recommendation by next saturday, that is the 7th of March)

---

# Author

WellPath is built as a focused validation project demonstrating how a minimal, thoughtfully designed system can enable both marketplace transactions and personal health tracking within a unified architecture.

The guiding principle of this repository is discipline: build only what proves value, validate assumptions early, and evolve based on evidence rather than speculation.
