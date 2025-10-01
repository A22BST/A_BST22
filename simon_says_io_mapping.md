# Simon Says - I/O Mapping and Hardware Configuration

## Phase 1 - 3 Button Configuration

### Hardware Overview
- **PLC**: Omron NX102-1100 CPU
- **Power Supply**: RS PRO LI60-20B24PR2 (24V DC, 2.5A)
- **Input Module**: NX-ID4442 (Digital Input, 64 channels)
- **Output Module**: NX-OD4256 (Digital Output, 32 channels)
- **Buttons**: 3x RAFI RAMO 22 T illuminated pushbuttons (M12, 4-pin, 1NO + LED)

### I/O Allocation

#### Digital Inputs (NX-ID4442)
| Address | Description | Wire Color | Button | Function |
|---------|-------------|------------|---------|----------|
| DI1     | Yellow Button Contact | Black | Yellow | Player input detection |
| DI3     | Blue Button Contact | Black | Blue | Player input detection |
| DI5     | Red Button Contact | Black | Red | Player input detection |
| DI7     | Start/Reset Button | - | External | Game control |

#### Digital Outputs (NX-OD4256)
| Address | Description | Wire Color | Button | Function |
|---------|-------------|------------|---------|----------|
| DO0     | Red LED | White | Red | Sequence display & feedback |
| DO1     | Blue LED | White | Blue | Sequence display & feedback |
| DO2     | Yellow LED | White | Yellow | Sequence display & feedback |
| DO3     | Status LED | - | External | Game status indicator |

### Button Wiring Details

#### Yellow Button (M12 A-coded, 4-pin)
- Pin 1 (Brown) → +24V terminal block (Contact COM)
- Pin 2 (White) → DO2 (LED +)
- Pin 3 (Blue) → 0V terminal block (LED -)
- Pin 4 (Black) → DI1 (Contact output)

#### Blue Button (M12 A-coded, 4-pin)
- Pin 1 (Brown) → +24V terminal block (Contact COM)
- Pin 2 (White) → DO1 (LED +)
- Pin 3 (Blue) → 0V terminal block (LED -)
- Pin 4 (Black) → DI3 (Contact output)

#### Red Button (M12 A-coded, 4-pin)
- Pin 1 (Brown) → +24V terminal block (Contact COM)
- Pin 2 (White) → DO0 (LED +)
- Pin 3 (Blue) → 0V terminal block (LED -)
- Pin 4 (Black) → DI5 (Contact output)

### Power Distribution
- **+24V**: Distributed via DIN terminal blocks to all button contacts (Pin 1)
- **0V**: Distributed via DIN terminal blocks to all LED negatives (Pin 3)
- **PE**: Yellow/green protective earth bonding throughout