// lib/features/site/home/wellpath_config.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// WellPath — SiteConfig instance
// ─────────────────────────────────────────────────────────────────────────────
// Single source of truth for all WellPath marketing copy.
// To update any landing page content, edit only this file.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/constants/marketing_nav.dart';
import '../../../core/style/app_branding.dart';
import '../../../core/style/app_motion.dart';
import '../site_config.dart';

const SiteConfig kWellPathSiteConfig = SiteConfig(
  signupRoute:   '/signup',
  loginRoute:    '/login',
  featuresRoute: '/features',
  pageMaxWidth:  1100.0,
  pagePaddingH:  60.0,

  // ── Navigation ─────────────────────────────────────────────────────────────
  nav: SiteNavConfig(
    navItems:       kMarketingNavItems,
    ctaLabel:       'Begin Journey →',
    profileIcon:    Icons.person_outline,
    profileTooltip: 'Sign in or create an account',
  ),

  // ── Hero ───────────────────────────────────────────────────────────────────
  hero: SiteHeroConfig(
    badge: 'Now live in Mombasa, Kenya',
    headline: TypingTextConfig(
      phrases: [
        'Book trusted local trainers.',
        'Connect with certified coaches.',
        'Transform your fitness routine.',
      ],
    ),
    subline:
        'WellPath brings Mombasa\'s finest certified trainers to your fingertips. '
        'Book sessions in seconds, track every rep and rest day, and build the '
        'habits that last.',
    primaryCtaLabel:   'Start Free Today',
    secondaryCtaLabel: 'Explore Features',
    microcopy:         'Free to join · No credit card required · Cancel anytime',
  ),

  // ── Trusted by ─────────────────────────────────────────────────────────────
  trusted: SiteTrustedConfig(
    label: 'Trusted by',
    logos: [
      'NYALI FIT', 'BAMBURI CORE', 'COAST CLUB', 'MOMBASA MOVE',
      'NEXUS GYM', 'SAND & STEEL', 'URBAN REP', 'FLOW LAB',
    ],
  ),

  // ── Stats ──────────────────────────────────────────────────────────────────
  stats: SiteStatsConfig(
    eyebrow:    'Platform Snapshot',
    heading:    'A focused launch, built for momentum',
    subheading: 'Early numbers that reflect a small, growing product — designed '
                'to build trust without overstating scale.',
    stats: [
      SiteStat(value: '12+', label: 'Certified\nTrainers'),
      SiteStat(value: '80+', label: 'Early\nMembers'),
      SiteStat(value: '250+', label: 'Sessions\nBooked'),
      SiteStat(value: '92%', label: 'Client\nSatisfaction'),
    ],
  ),

  // ── How It Works ───────────────────────────────────────────────────────────
  howItWorks: SiteHowItWorksConfig(
    eyebrow:    'How It Works',
    heading:    'Three steps to a stronger you',
    subheading: 'WellPath removes every obstacle between you and your next '
                'great session.',
    steps: [
      SiteStep(
        number: '01', title: 'Discover', icon: Icons.search_rounded,
        body:
            'Browse verified trainers by specialty, distance, price, and real '
            'availability. Read reviews, view certifications, and find your '
            'perfect match.',
      ),
      SiteStep(
        number: '02', title: 'Book', icon: Icons.calendar_today_rounded,
        body:
            'Reserve a session in seconds. Our real-time booking system handles '
            'scheduling, confirmations, and reminders — so you can focus on '
            'showing up.',
      ),
      SiteStep(
        number: '03', title: 'Track', icon: Icons.show_chart_rounded,
        body:
            'Log workouts, water intake, and sleep from your dashboard. Set '
            'goals, watch your streaks grow, and celebrate every milestone.',
      ),
    ],
  ),

  // ── Features ───────────────────────────────────────────────────────────────
  features: SiteFeaturesConfig(
    eyebrow:    'Platform Features',
    heading:    'Everything your fitness journey needs',
    subheading: 'From discovery to accountability — built around how '
                'Mombasa trains.',
    features: [
      SiteFeature(
        icon: Icons.person_search_rounded,
        title: 'Smart Trainer Discovery',
        body:
            'Filter by specialty — strength, yoga, HIIT, swimming, and more. '
            'Every trainer is verified and rated by real WellPath members.',
      ),
      SiteFeature(
        icon: Icons.event_available_rounded,
        title: 'Instant Booking',
        body:
            'See live availability and book in two taps. Receive instant push '
            'confirmations and 24-hour reminders before every session.',
        useSecondaryAccent: true,
      ),
      SiteFeature(
        icon: Icons.insights_rounded,
        title: 'Wellness Dashboard',
        body:
            'Track workouts, hydration, and sleep in one place. Weekly summaries '
            'and goal progress keep you accountable between sessions.',
      ),
      SiteFeature(
        icon: Icons.notifications_active_rounded,
        title: 'Smart Reminders',
        body:
            'Customisable push alerts for sessions, daily water goals, and sleep '
            'check-ins. Never miss a beat — or a rep.',
        useSecondaryAccent: true,
      ),
    ],
  ),

  // ── Testimonials ───────────────────────────────────────────────────────────
  testimonials: SiteTestimonialsConfig(
    eyebrow:    'Member Stories',
    heading:    'Real people. Real results.',
    subheading: 'From first-timers to regulars — hear what WellPath members say.',
    testimonials: [
      SiteTestimonial(
        quote:
            'I\'d tried three other apps before WellPath. None of them felt like '
            'they were built for how we actually live and move in Mombasa. '
            'This one gets it.',
        name: 'Fatuma A.', location: 'Nyali, Mombasa', initials: 'FA',
      ),
      SiteTestimonial(
        quote:
            'Booking is genuinely two taps. My trainer confirms instantly and I '
            'get a reminder the evening before. I\'ve not missed a session in '
            'six weeks.',
        name: 'John K.', location: 'Mombasa CBD', initials: 'JK',
      ),
      SiteTestimonial(
        quote:
            'The wellness dashboard changed how I think about rest days. Seeing '
            'sleep and water alongside my workouts made the difference I\'d been '
            'looking for.',
        name: 'Aisha M.', location: 'Bamburi, Mombasa', initials: 'AM',
      ),
    ],
  ),

  // ── CTA Banner ─────────────────────────────────────────────────────────────
  cta: SiteCtaConfig(
    eyebrow:     'Get Started',
    heading:     'Ready to transform\nyour fitness journey?',
    subheading:  'Join hundreds of Mombasa members already on WellPath.\n'
                 'Free to start — no credit card required.',
    buttonLabel: 'Create Your Free Account',
  ),

  // ── Footer ─────────────────────────────────────────────────────────────────
  footer: SiteFooterConfig(
    tagline:   'Your fitness journey, connected.',
    location:  'Mombasa, Kenya',
    copyright: '${BrandCopy.copyright} · BSIT/445J/2020 · Grace Miriri',
    columns: [
      SiteFooterColumn(title: 'Product', links: [
        SiteFooterLink(label: 'Features', route: '/features'),
        SiteFooterLink(label: 'Pricing',  route: '/pricing'),
        SiteFooterLink(label: 'About',    route: '/about'),
      ]),
      SiteFooterColumn(title: 'Account', links: [
        SiteFooterLink(label: 'Sign Up', route: '/signup'),
        SiteFooterLink(label: 'Log In',  route: '/login'),
      ]),
      SiteFooterColumn(title: 'Dev', links: [
        SiteFooterLink(label: 'Project Roadmap', route: '/dev'),
      ]),
    ],
  ),
);