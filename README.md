# BlockTix

## Overview
BlockTix is a decentralized event ticketing system built on the Stacks blockchain using Clarity smart contracts. The platform leverages non-fungible tokens (NFTs) to represent event tickets, providing transparency, security, and new capabilities for event organizers and attendees.

## Features

### For Event Organizers
- **Create Events**: Define event details including name, schedule, ticket price, and attendance capacity
- **Manage Events**: Update event information before tickets are sold
- **Cancel Events**: Initiate event cancellations with automated refund capability
- **Direct Revenue**: Receive STX payments directly to your wallet

### For Attendees
- **Purchase Tickets**: Buy tickets directly using STX cryptocurrency
- **Transfer Tickets**: Securely transfer tickets to other users
- **Request Refunds**: Get automatic refunds for cancelled events
- **Verifiable Ownership**: Prove ticket authenticity through blockchain verification

## Technical Architecture
BlockTix is built on the following components:

1. **NFT-Based Tickets**: Each ticket is a non-fungible token with a unique identifier
2. **Event Registry**: Stores event details including capacity and sales information
3. **Attendee Registry**: Tracks event participation and ticket ownership
4. **Security Controls**: Prevents fraud through ownership verification and access controls

## Contract Functions

### Event Management
- `create-show`: Create a new event with all necessary details
- `update-show`: Modify event information (before ticket sales begin)
- `cancel-show`: Cancel an event and enable refund processing

### Ticket Operations
- `purchase-ticket`: Buy a ticket for a specific event
- `reassign-ticket`: Transfer a ticket to another attendee
- `claim-refund`: Request a refund for a cancelled event

### Query Functions
- `get-ticket-owner`: Check current ownership of a specific ticket
- `get-show-details`: Retrieve detailed information about an event

## Error Handling
The contract implements comprehensive error handling for various scenarios including:
- Invalid input validation
- Event capacity constraints
- Ownership verification failures
- Event status conflicts
- Payment processing issues

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- Basic understanding of Stacks blockchain and Clarity language

### Deployment
1. Clone this repository
2. Install Clarinet if you haven't already
3. Deploy using standard Clarinet deployment procedures

```bash
# Initialize a new Clarinet project
clarinet new my-blocktix

# Replace the default contract with BlockTix
cp blocktix.clar my-blocktix/contracts/

# Test locally
cd my-blocktix
clarinet test

# Deploy to testnet/mainnet (requires additional configuration)
clarinet publish
```

## Security Considerations
- Admin functions are restricted to the contract deployer
- Ticket transfers require ownership verification
- Event modifications are restricted after tickets are sold
- Refunds are only processed for cancelled events

## License
This project is licensed under the MIT License.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.