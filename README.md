# OracleProvider

An address reputation system smart contract for oracle data accuracy and reliability scoring on the Stacks blockchain.

## Description

OracleProvider is a Clarity smart contract that tracks oracle provider reputation based on data accuracy, submission frequency, and community feedback to ensure reliable oracle data. The contract provides a comprehensive system for managing oracle providers, tracking their performance, and maintaining a reputation scoring system that helps users identify trustworthy data sources.

## Features

- **Oracle Registration**: Register oracle providers with name and description
- **Reputation Scoring**: Track reputation scores from 0-100 based on accuracy
- **Data Submission Tracking**: Monitor oracle data submissions and verification
- **Community Feedback**: Allow users to rate and comment on oracle performance
- **Active Status Management**: Enable/disable oracle providers
- **Trust Verification**: Identify trusted oracles based on reputation threshold
- **Performance Analytics**: Calculate accuracy percentages and submission statistics

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

### Contract Constants

- `MIN_REPUTATION_SCORE`: 0
- `MAX_REPUTATION_SCORE`: 100
- `TRUSTED_THRESHOLD`: 70 (minimum score for trusted status)
- `NEUTRAL_STARTING_SCORE`: 50

### Error Codes

- `ERR_UNAUTHORIZED` (401): Unauthorized access
- `ERR_ORACLE_NOT_FOUND` (404): Oracle not found
- `ERR_INVALID_SCORE` (400): Invalid score provided
- `ERR_ALREADY_REGISTERED` (409): Oracle already registered

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (for testing)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd OracleProvider
```

2. Navigate to the contract directory:
```bash
cd OracleProvider_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

5. Run tests:
```bash
clarinet test
```

## Usage Examples

### Register an Oracle Provider

```clarity
(contract-call? .OracleProvider register-oracle "MyOracle" "Reliable crypto price oracle")
```

### Submit Oracle Data

```clarity
(contract-call? .OracleProvider submit-data 0x1234567890abcdef...)
```

### Provide Feedback on an Oracle

```clarity
(contract-call? .OracleProvider provide-feedback 'SP1ABC... u4 "Great accuracy!")
```

### Check Oracle Reputation

```clarity
(contract-call? .OracleProvider get-oracle-reputation 'SP1ABC...)
```

### Verify Oracle Trust Status

```clarity
(contract-call? .OracleProvider is-oracle-trusted 'SP1ABC...)
```

## Contract Functions

### Public Functions

#### `register-oracle`
Registers a new oracle provider in the system.

**Parameters:**
- `name`: Oracle name (string-ascii 50)
- `description`: Oracle description (string-ascii 200)

**Returns:** `(response principal uint)`

#### `submit-data`
Submits oracle data for tracking and verification.

**Parameters:**
- `data-hash`: Hash of the submitted data (buff 32)

**Returns:** `(response bool uint)`

#### `update-oracle-accuracy`
Updates oracle accuracy after verification (owner only).

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)
- `was-accurate`: Whether the submission was accurate (bool)

**Returns:** `(response uint uint)`

#### `provide-feedback`
Allows users to rate and comment on oracle performance.

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)
- `rating`: Rating from 1-5 (uint)
- `comment`: Feedback comment (string-ascii 100)

**Returns:** `(response bool uint)`

#### `deactivate-oracle`
Deactivates an oracle provider (owner only).

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)

**Returns:** `(response bool uint)`

### Read-Only Functions

#### `get-oracle-reputation`
Retrieves complete reputation data for an oracle.

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)

**Returns:** Reputation data including score, submissions, and activity status

#### `get-oracle-details`
Gets oracle registration details.

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)

**Returns:** Oracle name, description, and registration block

#### `get-oracle-feedback`
Retrieves feedback from a specific provider about an oracle.

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)
- `feedback-provider`: Address of feedback provider (principal)

**Returns:** Rating, comment, and timestamp

#### `is-oracle-trusted`
Checks if an oracle meets the trusted status threshold.

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)

**Returns:** Boolean indicating trusted status

#### `get-total-oracles`
Returns the total number of registered oracles.

**Returns:** Total oracle count (uint)

#### `get-oracle-accuracy`
Calculates the accuracy percentage for an oracle.

**Parameters:**
- `oracle-addr`: Oracle provider address (principal)

**Returns:** Accuracy percentage (0-100)

## Data Structures

### Oracle Reputation Map
```clarity
{
  reputation-score: uint,
  total-submissions: uint,
  accurate-submissions: uint,
  last-update: uint,
  is-active: bool
}
```

### Oracle Details Map
```clarity
{
  name: (string-ascii 50),
  description: (string-ascii 200),
  registration-block: uint
}
```

### Oracle Feedback Map
```clarity
{
  rating: uint,
  comment: (string-ascii 100),
  timestamp: uint
}
```

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet publish --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet publish --mainnet
```

## Security Notes

### Access Control
- Only the contract owner can update oracle accuracy scores
- Only the contract owner can deactivate oracle providers
- Oracle registration is open to all users
- Feedback submission is open to all users

### Trust Model
- Reputation scores are calculated based on verified accuracy
- New oracles start with a neutral score of 50
- Trusted status requires a minimum score of 70
- The system relies on the contract owner for accuracy verification

### Considerations
- The contract owner has significant control over oracle reputation
- Consider implementing a decentralized verification mechanism for production use
- Monitor oracle activity and implement additional security measures as needed
- Regular auditing of oracle performance and feedback is recommended

### Best Practices
- Verify oracle data through multiple sources before updating accuracy
- Implement proper key management for the contract owner account
- Consider multi-signature requirements for critical operations
- Regular monitoring of oracle provider behavior and reputation scores

## Development

### Project Structure
```
OracleProvider_contract/
├── contracts/
│   └── OracleProvider.clar     # Main contract
├── tests/
│   └── OracleProvider.test.ts  # Test suite
├── settings/
│   ├── Devnet.toml            # Local development config
│   ├── Testnet.toml           # Testnet configuration
│   └── Mainnet.toml           # Mainnet configuration
├── Clarinet.toml              # Project configuration
└── package.json               # Node.js dependencies
```

### Testing

Run the test suite:
```bash
clarinet test
```

The contract includes comprehensive tests covering:
- Oracle registration
- Data submission tracking
- Reputation score updates
- Feedback mechanisms
- Access control validation

## License

This project is open source. Please refer to the license file for details.

## Contributing

Contributions are welcome! Please follow the standard development workflow:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions, issues, or contributions, please refer to the project repository or contact the development team.