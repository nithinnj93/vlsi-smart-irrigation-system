# RTL Block Diagrams

## Moisture Comparator

```
Moisture -----> Comparator -----> Dry Signal
Threshold -----^
```

---

## Pump FSM

```
Dry Signal
      │
      ▼
 +-------------+
 | Pump FSM    |
 +-------------+
       │
       ▼
 Pump Control
```

---

## UART

```
Data
 │
 ▼
Shift Register
 │
 ▼
 UART FSM
 │
 ▼
 TX
```