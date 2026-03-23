# Cirkit - AR Circuit Builder & Programming Platform

An innovative augmented reality application for iPad that enables users to build, visualize, and program electronic circuits in 3D space using real-world surfaces.

## Overview

Cirkit combines AR technology with visual block programming to create an immersive educational platform for learning electronics and programming. Users can place virtual circuit components on real tables, connect them together, and program microcontrollers using an intuitive drag-and-drop interface.

## Features

### Interactive Circuit Building
- **AR Component Placement**: Spawn circuit components (batteries, bulbs, switches, wires, microcontrollers, sensors) onto real-world surfaces
- **Physical Interactions**: Select, drag, rotate, and delete components with natural gestures
- **Auto-Connection System**: Components automatically snap together when ports are close (2cm threshold)
- **Real-time Circuit Validation**: BFS-based algorithm validates electrical paths from battery to microcontroller
- **Visual Feedback**: Glowing effects on powered components, connection indicators, selection highlighting with animated cone

### Component Library
- **Microcontroller**: 3-port programmable controller with visual block programming
- **Power Sources**: Battery (5V power supply)
- **Output Devices**: Light bulbs with realistic glow effects
- **Input Devices**: Push buttons, light sensors, ultrasonic distance sensors
- **Connectors**: Wires and switches for circuit control
- **Smart Components**: IF blocks with sensor-based and port-based conditions

### Visual Block Programming
- **Drag-and-Drop Interface**: Intuitive block-based programming system
- **Block Types**:
  - Port Control: Set microcontroller ports HIGH/LOW/ANY
  - Timing: Wait/delay blocks for timed operations
  - Control Flow: Forever loops, IF/ELSE conditions, Repeat loops
- **Sensor Integration**: Light sensor and ultrasonic sensor blocks for responsive programs
- **Preset Projects**: Traffic Light Simulator, Blinker, Smart Light Control, Automatic Light Sensor
- **Real-time Execution**: Programs run immediately with visual feedback on circuit components

### User Interface
- **Landscape-First Design**: Optimized for iPad in landscape orientation
- **Floating Controls**: Context-sensitive rotation and delete buttons
- **Sensor Displays**: Real-time readings for light and distance sensors
- **Error Handling**: Clear messages for surface detection, connection issues
- **Clean Navigation**: Tutorial → Library → Freeplay progression

## Technical Architecture

### AR Foundation
- **ARKit Integration**: Horizontal plane detection for table/floor surfaces
- **RealityKit Entities**: 3D models for all circuit components
- **Marker System**: Yellow corner markers for table boundary visualization
- **Gesture Recognition**: Tap selection, drag movement, two-finger rotation

### Circuit System
- **Connection Graph**: Maintains entity relationships and electrical paths
- **BFS Validation**: Breadth-first search algorithm ensures valid circuit topology
- **Port Matching**: 2cm proximity threshold for automatic connection detection
- **State Management**: Tracks microcontroller port states (HIGH/LOW) and sensor readings

### Programming Engine
- **Block Storage**: Array-based program representation with indent levels
- **Sequential Execution**: Top-to-bottom block interpretation
- **Conditional Logic**: IF/ELSE branching based on sensor data or port states
- **Loop Support**: Forever and Repeat (N times) loops
- **Real-time Updates**: Immediate visual feedback on circuit when program runs

### Data Persistence
- **Program Storage**: Dictionary mapping microcontroller entities to saved block arrays
- **Session State**: Maintains circuit configuration and programs during app lifecycle

## Project Structure

```
├── ARTableView.swift                    # Main AR view with circuit logic
├── TutorialView.swift                   # Interactive tutorial experience
├── SmartLightView.swift                 # Smart Light Control preset project
├── AutoLightView.swift                  # Automatic Light Sensor preset project
├── ContentView.swift                    # Home screen and navigation
├── MicrocontrollerProgrammingView.swift # Block programming interface
└── README.md                            # This file
```

## Key Components

### Connection Manager
- Monitors entity proximity and creates/removes connections
- BFS pathfinding from battery to microcontroller
- Sensor-to-microcontroller validation for sensor circuits
- Push button state detection and handling

### Microcontroller Programming
- Modal interface for creating block programs
- Drag blocks from palette to programming area
- Nested block structure with visual indentation
- Projects menu with preset programs (Traffic Light, Blinker, etc.)

## User Flow

1. **Launch**: Welcome screen with Tutorial, Library, and Freeplay options
2. **Tutorial Mode**: 17-step guided experience teaching all concepts
3. **Library Projects**: Two preset circuits with pre-loaded programs
4. **Freeplay Mode**: Unrestricted circuit building and programming

## Acknowledgments

Built with SwiftUI, RealityKit, and ARKit for iOS/iPadOS.
