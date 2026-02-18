# Pulse 5 BLE Protocol

## Connection

- **BLE Service UUID:** `65786365-6c70-6f69-6e74-2e636f6d0000`
- **Write Characteristic:** `65786365-6c70-6f69-6e74-2e636f6d0002` (write + writeWithoutResponse)
- **Read/Notify Characteristic:** `65786365-6c70-6f69-6e74-2e636f6d0001` (read + notify)

## Packet Format

```
[0xAA] [CMD] [LEN] [PAYLOAD...]
```

Canvas commands (`0x86`, `0x92`) use 2-byte length:

```
[0xAA] [CMD] [LEN_HI] [LEN_LO] [PAYLOAD...]
```

No checksum.

## Commands

### Light

| Cmd  | Name             | Direction   | Payload                |
|------|------------------|-------------|------------------------|
| 0x71 | REQ_LIGHT_STATUS | App→Speaker | none                   |
| 0x72 | RET_LIGHT_STATUS | Speaker→App | [status: 0=off, 1=on] |
| 0x73 | SET_LIGHT_STATUS | App→Speaker | [status: 0=off, 1=on] |

### LED Packages

| Cmd  | Name                           | Direction   | Payload                                                           |
|------|--------------------------------|-------------|-------------------------------------------------------------------|
| 0x83 | REQ_LED_PACKAGE_INFO           | App→Speaker | none                                                              |
| 0x84 | RET_LED_PACKAGE_INFO           | Speaker→App | package data                                                      |
| 0x85 | SET_LED_PACKAGE                | App→Speaker | [pkgId][activeCount][allCount][patterns...][colorEffect][R][G][B] |
| 0x86 | SET_LED_CANVAS_PACKAGE         | App→Speaker | (2-byte len) [pkgId][enableStatus][patternId_2b][data...]         |
| 0x87 | NOTIFY_LED_PACKAGE_INFO        | Speaker→App | package state notification                                        |
| 0x88 | NOTIFY_LED_PATTERN_INFO        | Speaker→App | pattern info notification                                         |
| 0x89 | ENABLE_NOTIFY_LED_PATTERN_INFO | App→Speaker | [enable: 0/1]                                                     |
| 0x90 | SWITCH_LED_PACKAGE             | App→Speaker | [packageId]                                                       |

### Brightness & Speed

| Cmd  | Name                   | Direction   | Payload                                  |
|------|------------------------|-------------|------------------------------------------|
| 0x8A | SET_LED_BRIGHTNESS     | App→Speaker | [level:20-80][bodyLight:0/1][projection:0/1] |
| 0x8B | REQ_LED_BRIGHTNESS     | App→Speaker | none                                     |
| 0x8C | RET_LED_BRIGHTNESS     | Speaker→App | [level][bodyLight][projection]           |
| 0x8D | SET_LED_MOVEMENT_SPEED | App→Speaker | [speed: 1=Low, 2=Mid, 3=High]           |
| 0x8E | REQ_LED_MOVEMENT_SPEED | App→Speaker | none                                     |
| 0x8F | RET_LED_MOVEMENT_SPEED | Speaker→App | [speed]                                  |

### Pattern Preview

| Cmd  | Name                   | Direction   | Payload                                                   |
|------|------------------------|-------------|-----------------------------------------------------------|
| 0x91 | PREVIEW_PATTERN        | App→Speaker | [pkgId][patternId]                                        |
| 0x92 | PREVIEW_CANVAS_PATTERN | App→Speaker | (2-byte len) [pkgId][enableStatus][patternId_2b][data...] |

## Themes

| ID   | Name      | Color   |
|------|-----------|---------|
| 0x01 | Nature    | #AD52FF |
| 0x02 | Party     | #FABC03 |
| 0x03 | Spiritual | #FF6C00 |
| 0x04 | Cocktail  | #00CBFF |
| 0x05 | Weather   | #0052FF |
| 0xC1 | Canvas    | #00FFCC |

## Patterns

| ID   | Name            | Theme     |
|------|-----------------|-----------|
| 0x01 | Campfire        | Nature    |
| 0x02 | Northern Lights | Nature    |
| 0x03 | Sea Wave        | Nature    |
| 0x04 | Universe        | Nature    |
| 0x05 | Strobe          | Party     |
| 0x06 | Equalizer       | Party     |
| 0x07 | Geometry        | Party     |
| 0x08 | Spin            | Party     |
| 0x09 | Rainbow         | Party     |
| 0x0A | Dynamic Wave    | Spiritual |
| 0x0B | Lava            | Spiritual |
| 0x0C | Focus           | Spiritual |
| 0x0D | Sky Sunny       | Weather   |
| 0x0E | Rain            | Weather   |
| 0x0F | Snow            | Weather   |
| 0x10 | Thunder         | Weather   |
| 0x11 | Cloud           | Weather   |
| 0x13 | Fruit Gin       | Cocktail  |
| 0x14 | Mojito          | Cocktail  |
| 0x15 | Tequila         | Cocktail  |
| 0x16 | Cherry          | Cocktail  |

## Brightness

- Range: 20–80

## Color Modes

- `0` = STATIC_COLOR
- `1` = COLOR_LOOP
