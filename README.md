# Trainchain

On-chain apprenticeship credential NFTs for verifiable skill certification and tracking.

## Overview

Trainchain is a Clarity smart contract that enables the creation, management, and verification of apprenticeship credentials as NFTs on the Stacks blockchain. The system allows institutions to register mentors who can issue credentials to apprentices, track skill development, and provide verifiable proof of completed training programs.

## Features

- **NFT-based Credentials**: Each apprenticeship credential is minted as a unique NFT
- **Mentor Registration**: Qualified mentors can register with institutions to issue credentials
- **Institution Management**: Verified institutions can manage their mentor network
- **Skill Registry**: Standardized skill categories with difficulty levels
- **Credential Verification**: Multi-level verification system for authenticity
- **Progress Tracking**: Monitor apprenticeship duration and completion status
- **Grade Assignment**: Mentors can assign grades upon credential completion

## Core Functions

### Mentor Management
```clarity
(register-mentor (name (string-ascii 64)) (institution (string-ascii 128)) (specialization (string-ascii 64)))
```
Registers a new mentor with their institution and specialization.

### Institution Setup
```clarity
(register-institution (institution-name (string-ascii 128)) (admin principal))
```
Registers a new institution with an admin (contract owner only).

### Skill Registration
```clarity
(register-skill (skill-name (string-ascii 64)) (description (string-ascii 256)) (category (string-ascii 32)) (difficulty uint))
```
Adds a new skill to the registry with metadata (contract owner only).

### Credential Issuance
```clarity
(issue-credential (apprentice principal) (skill-area (string-ascii 64)) (institution (string-ascii 128)) (metadata-uri (string-ascii 256)))
```
Issues a new apprenticeship credential NFT to an apprentice.

### Credential Completion
```clarity
(complete-credential (token-id uint) (grade (string-ascii 16)))
```
Marks a credential as completed with a grade (mentor only).

### Verification
```clarity
(verify-credential (token-id uint))
```
Verifies a credential for authenticity (institution admin only).

## Read-Only Functions

- `get-credential`: Retrieve credential details
- `get-mentor-info`: Get mentor information
- `get-institution-info`: Get institution details
- `get-skill-info`: Get skill registry information
- `is-credential-verified`: Check verification status
- `is-credential-completed`: Check completion status
- `get-credential-duration`: Calculate credential duration

## Data Structure

### Credential NFT
Each credential contains:
- Apprentice principal
- Mentor principal
- Skill area
- Institution
- Start and completion blocks
- Metadata URI
- Verification status
- Grade

### Mentor Profile
- Name and specialization
- Associated institution
- Active status
- Number of credentials issued

### Institution
- Verification status
- Admin principal
- Total credentials issued

## Usage Example

1. **Register Institution** (Contract Owner)
```clarity
(contract-call? .trainchain register-institution "TechSkills Academy" 'SP1ABC...)
```

2. **Register Mentor**
```clarity
(contract-call? .trainchain register-mentor "John Smith" "TechSkills Academy" "Web Development")
```

3. **Register Skill**
```clarity
(contract-call? .trainchain register-skill "JavaScript" "Frontend programming language" "Programming" u3)
```

4. **Issue Credential**
```clarity
(contract-call? .trainchain issue-credential 'SP2DEF... "JavaScript" "TechSkills Academy" "ipfs://metadata-hash")
```

5. **Complete Credential**
```clarity
(contract-call? .trainchain complete-credential u1 "A+")
```

## Error Codes

- `u100`: Unauthorized access
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Invalid parameters
- `u104`: Not a registered mentor
- `u105`: Credential already completed

## Testing

Run the test suite:
```bash
npm install
npm test
```

## Deployment

Use Clarinet to deploy:
```bash
clarinet deployments generate --low-cost
clarinet deployments apply
```
