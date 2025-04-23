# VaultAI: AI-Based Decentralized File Storage Marketplace

A blockchain-based marketplace smart contract that enables decentralized file storage with AI-powered classification and dynamic pricing.

## Overview

This smart contract facilitates a decentralized marketplace where storage providers can offer their services and users can purchase storage space. The system leverages artificial intelligence for file classification and dynamic pricing adjustments, creating an efficient and automated storage ecosystem.

## Features

- **Provider Registration**: Storage providers can register on the platform, specifying their available storage capacity and pricing.
- **AI-Based File Classification**: Files are classified using AI to determine appropriate storage costs based on content type.
- **Dynamic Pricing**: Pricing is automatically adjusted based on AI classification, storage duration, and market conditions.
- **Secure Storage Contracts**: Complete storage agreements between providers and clients are recorded on-chain.
- **Reputation System**: Providers build reputation scores based on service quality and customer engagement.
- **Automated Optimization**: AI-driven parameter optimization adjusts pricing and reputation based on market conditions.
- **Encryption Support**: Multiple encryption levels are supported for varying security requirements.
- **Contract Termination**: Both providers and clients can terminate storage contracts with automatic resource reallocation.

## Contract Architecture

### Key Data Structures

1. **Storage Providers**
   ```
   {
     available-storage: uint,
     price-per-gb: uint,
     reputation-score: uint,
     total-clients: uint,
     online: bool
   }
   ```

2. **Storage Contracts**
   ```
   {
     provider: principal,
     client: principal,
     storage-amount: uint,
     duration-days: uint,
     price-paid: uint,
     start-time: uint,
     ai-classification: (string-ascii 20),
     encryption-level: uint,
     active: bool
   }
   ```

3. **Client Files**
   ```
   {
     file-hash: (buff 32),
     size-kb: uint,
     ai-classification: (string-ascii 20),
     contract-id: uint,
     encryption-level: uint
   }
   ```

4. **AI Pricing Modifiers**
   ```
   {
     price-multiplier: uint
   }
   ```

### Core Functions

#### For Storage Providers

- `register-provider`: Register as a new storage provider with available capacity and pricing
- `update-provider-info`: Update provider storage availability, pricing, and online status
- `ai-optimize-storage-parameters`: Optimize pricing and reputation parameters using AI analytics

#### For Clients

- `purchase-storage`: Purchase storage space from a provider with specific requirements
- `terminate-storage-contract`: End an existing storage contract

#### For Platform Administration

- `set-ai-pricing-modifier`: Set price multipliers for different AI-classified file types

#### Helper Functions

- `calculate-price`: Calculate storage pricing based on provider rates, storage amount, duration, and AI classification

## Error Codes

| Error Code | Description |
|------------|-------------|
| u1 | Not authorized to perform this action |
| u2 | Provider not found in the system |
| u3 | Insufficient funds for transaction |
| u4 | Invalid storage amount specified |
| u5 | Invalid duration specified |
| u6 | Not registered as a provider |
| u7 | Requested storage not available |
| u8 | Invalid AI classification |
| u9 | Unwrap operation failed |

## How It Works

### For Storage Providers

1. Register on the platform by specifying available storage and price per GB
2. Maintain online status and update availability as needed
3. Benefit from AI-based optimization to maximize earnings
4. Build reputation through reliable service

### For Users/Clients

1. Select a storage provider with sufficient capacity
2. Purchase storage with specified duration and encryption requirements
3. Files are automatically classified by the AI system
4. Pay the calculated price based on provider rates, classification, and duration
5. Access stored files via their contract IDs
6. Terminate contracts when no longer needed

### AI Classification and Pricing

The system uses AI to classify files and adjust pricing accordingly:

1. Files are categorized into various classifications (text, image, video, etc.)
2. Each classification has a price multiplier set by the platform administrator
3. Final price is calculated by combining:
   - Provider's base price per GB
   - AI classification multiplier
   - Storage duration factor
   - Available capacity factors

### Automated Optimization

The AI optimization system:

1. Analyzes market conditions and provider performance
2. Adjusts pricing based on demand and supply factors
3. Updates reputation scores based on client engagement
4. Balances market efficiency for both providers and clients

## Usage Examples

### Registering as a Provider

```clarity
(contract-call? .storage-marketplace register-provider u1000 u50)
```
This registers a provider with 1000 GB available at 50 μSTX per GB.

### Purchasing Storage

```clarity
(contract-call? .storage-marketplace purchase-storage 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  u5 
  u30 
  0x8a9c5262a93c48ceb91d1369706fc0a51f9d016d4769492d4213eaaa96d67e5a 
  "document" 
  u2)
```
This purchases 5 GB of storage for 30 days with encryption level 2 for a document-type file.

### Setting AI Classification Pricing

```clarity
(contract-call? .storage-marketplace set-ai-pricing-modifier "video" u150)
```
This sets a 1.5x price multiplier for video files.

### Terminating a Contract

```clarity
(contract-call? .storage-marketplace terminate-storage-contract u5)
```
This terminates storage contract with ID 5.

## Security Considerations

- All file data is stored off-chain; only file references and metadata are stored on-chain
- File hashes are used to verify data integrity
- Multiple encryption levels provide varying security options
- Contracts are fully auditable and transparent on the blockchain
- Authorization checks prevent unauthorized modification of contracts

## Future Development

- Integration with additional AI classification models
- Reputation-based incentive mechanisms
- Dispute resolution system
- Automated contract renewal options
- Multi-token payment support
- Cross-chain interoperability

## License

MIT
