# Farmers Market Coordination System

A comprehensive Clarity smart contract system for managing farmers market operations, vendor coordination, and customer engagement.

## Overview

This system provides a complete solution for farmers market management, including vendor applications, booth assignments, customer loyalty programs, payment processing, and community event coordination.

## Smart Contracts

### 1. Vendor Management (`vendor-management.clar`)
- Vendor registration and application processing
- Product verification and approval
- Vendor profile management
- Application status tracking

### 2. Market Layout (`market-layout.clar`)
- Booth assignment and management
- Market layout configuration
- Booth availability tracking
- Vendor-booth mapping

### 3. Customer Loyalty (`customer-loyalty.clar`)
- Customer registration and profiles
- Points-based loyalty system
- Reward redemption
- Purchase history tracking

### 4. Payment Processing (`payment-processing.clar`)
- Transaction recording
- Payment verification
- Sales tracking per vendor
- Revenue distribution

### 5. Event Coordination (`event-coordination.clar`)
- Community event creation and management
- Event registration
- Promotional activities
- Event scheduling

## Key Features

- **Vendor Onboarding**: Streamlined application process with product verification
- **Dynamic Booth Assignment**: Flexible booth allocation based on vendor needs
- **Customer Engagement**: Points-based loyalty system with rewards
- **Payment Tracking**: Comprehensive sales and revenue tracking
- **Event Management**: Community event coordination and promotion

## Data Structures

### Vendor Profile
- Principal ID
- Business name and description
- Product categories
- Verification status
- Application timestamp

### Booth Information
- Booth ID and location
- Size and amenities
- Availability status
- Current vendor assignment

### Customer Profile
- Principal ID
- Loyalty points balance
- Purchase history
- Registration date

### Transaction Record
- Transaction ID
- Vendor and customer principals
- Amount and timestamp
- Product details

## Getting Started

1. Deploy contracts to Stacks blockchain
2. Initialize market layout with booth configurations
3. Enable vendor applications
4. Launch customer loyalty program
5. Begin event coordination

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

Tests cover all contract functions, error conditions, and integration scenarios.

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents invalid data entry
- State transitions are atomic and consistent
- No cross-contract dependencies for security isolation
