# CS 442 MP4: Battleships

# Battleships

A multiplayer Battleship game built in Flutter/Dart for iOS and Android.

## Overview
Built as part of CS 442 at Illinois Institute of Technology. The app interfaces 
with a hosted RESTful API to support user authentication, game creation, and 
real-time gameplay against both human and AI opponents.

## Features
- User registration and login with session token persistence
- Play against human opponents or AI (random, perfect, oneship)
- Real-time game board with ship placement, shots, hits, and misses
- Active and completed game history
- Responsive 5x5 game board UI

## Tech Stack
- Flutter / Dart
- REST API consumption via HTTP package
- Provider for state management
- Shared Preferences for local session storage

## How It Works
The app communicates with a hosted REST API to handle all game logic server-side. 
The Flutter client manages UI state, session tokens, and real-time board updates 
across 100+ concurrent game sessions.
