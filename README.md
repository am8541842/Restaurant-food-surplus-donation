# Restaurant Food Surplus Donation

A blockchain-based platform connecting restaurants with excess food to shelters and food banks for same-day donation pickup.

## Overview

This smart contract system provides a decentralized solution for restaurants to donate surplus food to those in need. The platform ensures food safety, efficient logistics coordination, and transparent impact tracking while reducing food waste and feeding communities.

## Features

### Restaurant Management
- **Restaurant Registration**: Onboard restaurants with location and capacity details
- **Surplus Listing**: Post available food with type, quantity, and pickup windows
- **Donation History**: Track all donations made and impact created
- **Safety Compliance**: Food safety certification and handling protocols

### Recipient Management
- **Organization Registration**: Register shelters, food banks, and community centers
- **Capacity Tracking**: Monitor storage capacity and current inventory
- **Need Specification**: Specify dietary requirements and food type preferences
- **Service Population**: Track people served through received donations

### Donation Matching
- **Smart Matching**: Automatic pairing based on location, food type, and needs
- **Pickup Coordination**: Schedule same-day pickups within specified windows
- **Quantity Management**: Match available food with recipient capacity
- **Priority System**: Prioritize urgent needs and perishable items

### Logistics Coordination
- **Pickup Scheduling**: Coordinate pickup times and locations
- **Status Tracking**: Monitor donations from listing through delivery
- **Route Optimization**: Efficient matching based on proximity
- **Real-time Updates**: Track pickup confirmation and completion

### Food Safety
- **Temperature Monitoring**: Track food storage conditions
- **Expiry Management**: Ensure food freshness and safety
- **Compliance Tracking**: Maintain food safety standards
- **Quality Assurance**: Document food condition and handling

### Impact Measurement
- **Donation Metrics**: Track pounds of food donated and meals provided
- **Waste Reduction**: Calculate environmental impact and waste prevented
- **Community Impact**: Measure people served and organizations helped
- **Reporting**: Generate impact reports for stakeholders

## Contract: food-donation-coordinator

The main smart contract that coordinates all food donation operations.

### Key Functions

#### Restaurant Operations
- `register-restaurant`: Register restaurants as food donors
- `list-surplus-food`: Post available surplus food
- `update-food-status`: Modify food listing status
- `cancel-listing`: Cancel food availability

#### Recipient Operations
- `register-recipient`: Register organizations to receive food
- `update-capacity`: Modify receiving capacity
- `claim-donation`: Request specific food donations

#### Donation Coordination
- `match-donation`: Match food with recipients
- `schedule-pickup`: Coordinate pickup logistics
- `confirm-pickup`: Confirm food collection
- `complete-donation`: Finalize donation delivery

#### Safety & Quality
- `record-temperature`: Log food temperature data
- `verify-safety`: Confirm food safety compliance
- `report-issue`: Report food safety concerns

#### Analytics
- `get-restaurant-stats`: View restaurant donation metrics
- `get-recipient-stats`: View recipient impact data
- `get-system-metrics`: Access platform-wide statistics
- `get-donation-details`: Retrieve specific donation information

## Technical Details

### Data Structures

**Restaurants**: Stores restaurant ID, principal, name, location, contact, total donations, and verification status.

**Recipients**: Tracks organization ID, principal, name, type, capacity, location, and people served.

**Food Listings**: Manages food ID, restaurant, food type, quantity, expiry, pickup window, status, and safety data.

**Donations**: Records donation ID, food listing, recipient, pickup time, status, and completion details.

### Security Features
- Principal-based authentication
- Role-based access control (restaurants, recipients, admins)
- Status validation for state transitions
- Capacity checks before matching
- Food safety verification requirements

## Deployment

1. Install Clarinet: Follow [Clarinet installation guide](https://docs.hiro.so/clarinet)
2. Clone this repository
3. Run tests: `clarinet test`
4. Check contracts: `clarinet check`
5. Deploy: `clarinet deploy`

## Usage Example

```clarity
;; Register a restaurant
(contract-call? .food-donation-coordinator register-restaurant
  "Joe's Pizza"
  "123 Main St"
  "+1-555-0100")

;; List surplus food
(contract-call? .food-donation-coordinator list-surplus-food
  "prepared-meals"
  u50
  u1732550400
  u1732557600)

;; Match with recipient
(contract-call? .food-donation-coordinator match-donation
  u1
  'ST2RECIPIENT_ADDRESS)
```

## Impact

This system enables:
- Reduction of food waste from restaurants
- Feeding communities in need
- Efficient same-day donation logistics
- Transparent impact tracking
- Food safety compliance
- Environmental sustainability

## License

MIT License

## Contributing

Contributions are welcome! Please submit pull requests or open issues for improvements.

## Support

For questions or support, please open an issue in this repository.
