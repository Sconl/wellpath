// lib/spaces/space_site/screen_home/wellpath_config.dart
import 'package:flutter/material.dart';
import '../../../core/navigation/nav_items.dart';
import '../../../core/style/app_branding.dart';
import '../../../core/style/app_motion.dart';
import 'space_site_config.dart';

const SpaceSiteConfig kWellPathSpaceSiteConfig = SpaceSiteConfig(
  signupRoute: '/signup', loginRoute: '/login', featuresRoute: '/features',
  pageMaxWidth: 1100.0, pagePaddingH: 60.0,

  nav: SiteNavConfig(
    ctaLabel:       'Begin Journey →',
    profileIcon:    Icons.person_outline,
    profileTooltip: 'Sign in or create an account',
  ),

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

  trusted: SiteTrustedConfig(
    logos: [
      'NYALI FIT', 'BAMBURI CORE', 'COAST CLUB', 'MOMBASA MOVE',
      'NEXUS GYM', 'SAND & STEEL', 'URBAN REP', 'FLOW LAB',
    ],
  ),

  // Three stats — numeric values drive the count-up animation.
  stats: SiteStatsConfig(
    eyebrow:    'Platform Snapshot',
    heading:    'A focused launch, built for momentum',
    subheading: 'Early numbers from a small, growing product — built to earn '
                'trust at every step.',
    stats: [
      SpaceSiteStat(display: '12+',  numericValue: 12,  suffix: '+', label: 'Certified\nTrainers'),
      SpaceSiteStat(display: '250+', numericValue: 250, suffix: '+', label: 'Sessions\nBooked'),
      SpaceSiteStat(display: '92%',  numericValue: 92,  suffix: '%', label: 'Client\nSatisfaction'),
    ],
  ),

  steps: SiteStepsConfig(
    eyebrow:    'How It Works',
    heading:    'Three steps to a stronger you',
    subheading: 'WellPath removes every obstacle between you and your next great session.',
    steps: [
      SpaceSiteStep(number: '01', title: 'Discover', icon: Icons.search_rounded,
        body: 'Browse verified trainers by specialty, distance, price, and real '
              'availability. Read reviews, view certifications, and find your perfect match.'),
      SpaceSiteStep(number: '02', title: 'Book', icon: Icons.calendar_today_rounded,
        body: 'Reserve a session in seconds. Our real-time booking system handles '
              'scheduling, confirmations, and reminders — so you can focus on showing up.'),
      SpaceSiteStep(number: '03', title: 'Track', icon: Icons.show_chart_rounded,
        body: 'Log workouts, water intake, and sleep from your dashboard. Set goals, '
              'watch your streaks grow, and celebrate every milestone.'),
    ],
  ),

  features: SiteFeaturesConfig(
    eyebrow:    'Platform Features',
    heading:    'Everything your fitness journey needs',
    subheading: 'From discovery to accountability — built around how Mombasa trains.',
    features: [
      SpaceSiteFeature(icon: Icons.person_search_rounded, title: 'Smart Trainer Discovery',
        body: 'Filter by specialty — strength, yoga, HIIT, swimming, and more. '
              'Every trainer is verified and rated by real WellPath members.'),
      SpaceSiteFeature(icon: Icons.event_available_rounded, title: 'Instant Booking',
        body: 'See live availability and book in two taps. Receive instant push '
              'confirmations and 24-hour reminders before every session.',
        useSecondaryAccent: true),
      SpaceSiteFeature(icon: Icons.insights_rounded, title: 'Wellness Dashboard',
        body: 'Track workouts, hydration, and sleep in one place. Weekly summaries '
              'and goal progress keep you accountable between sessions.'),
      SpaceSiteFeature(icon: Icons.notifications_active_rounded, title: 'Smart Reminders',
        body: 'Customisable push alerts for sessions, daily water goals, and sleep '
              'check-ins. Never miss a beat — or a rep.',
        useSecondaryAccent: true),
    ],
  ),

  testimonials: SiteTestimonialsConfig(
    eyebrow:    'Member Stories',
    heading:    'Real people. Real results.',
    subheading: 'From first-timers to regulars — hear what WellPath members say.',
    testimonials: [
      SpaceSiteTestimonial(
        quote: 'I\'d tried three other apps before WellPath. None of them felt like '
               'they were built for how we actually live and move in Mombasa. This one gets it.',
        name: 'Fatuma A.', location: 'Nyali, Mombasa', initials: 'FA'),
      SpaceSiteTestimonial(
        quote: 'Booking is genuinely two taps. My trainer confirms instantly and I get a '
               'reminder the evening before. I\'ve not missed a session in six weeks.',
        name: 'John K.', location: 'Mombasa CBD', initials: 'JK'),
      SpaceSiteTestimonial(
        quote: 'The wellness dashboard changed how I think about rest days. Seeing sleep '
               'and water alongside my workouts made the difference I\'d been looking for.',
        name: 'Aisha M.', location: 'Bamburi, Mombasa', initials: 'AM'),
    ],
  ),

  cta: SiteCtaConfig(
    eyebrow:     'Get Started',
    heading:     'Ready to transform\nyour fitness journey?',
    subheading:  'Join hundreds of Mombasa members already on WellPath.\n'
                 'Free to start — no credit card required.',
    buttonLabel: 'Create Your Free Account',
  ),

  footer: SiteFooterConfig(
    tagline:   'Your fitness journey, connected.',
    location:  'Mombasa, Kenya',
    copyright: '${BrandCopy.copyright} · BSIT/445J/2020 · Grace Miriri',
    columns: [
      SpaceSiteFooterColumn(title: 'Product', links: [
        SpaceSiteFooterLink(label: 'Features', route: '/features'),
        SpaceSiteFooterLink(label: 'Pricing',  route: '/pricing'),
        SpaceSiteFooterLink(label: 'About',    route: '/about'),
      ]),
      SpaceSiteFooterColumn(title: 'Account', links: [
        SpaceSiteFooterLink(label: 'Sign Up', route: '/signup'),
        SpaceSiteFooterLink(label: 'Log In',  route: '/login'),
      ]),
      SpaceSiteFooterColumn(title: 'Dev', links: [
        SpaceSiteFooterLink(label: 'Project Roadmap', route: '/dev'),
      ]),
    ],
  ),
);