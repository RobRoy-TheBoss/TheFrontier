# Area Layout

Edit the values in this table, then ask Claude to apply it.

- **x, z** — world-space horizontal position (hex grid spacing is ~346 units between hex centres)
- **y** — elevation (world-space Y of the area surface, e.g. 0 = sea level)
- **rot_y_deg** — Y-axis rotation in degrees (0 = no rotation)

| area_node       | area_id          | x   | y  | z   | rot_y_deg |
|-----------------|------------------|-----|----|-----|-----------|
| CrestportBay    | crestport_bay    |   0 |  2 |   0 |        30 |
| GreenwoodVale   | greenwood_vale   | 300 |  8 | 173 |        30 |
| IronpeakRidge   | ironpeak_ridge   | 600 | 40 |   0 |        30 |
| MarshfenCrossing| marshfen_crossing|   0 |  1 | 346 |        30 |
| StonehillPass   | stonehill_pass   | 600 | 20 | 346 |        30 |
| VerdantReach    | verdant_reach    | 300 |  4 | 519 |        30 |

## Notes
- Hex circumradius is 199 units. Flat-top hex centre-to-centre distance:
  - E–W neighbours: 346 units apart (2 × 199 × sin 60°)
  - offset rows: 173 units Z, 300 units X
- rot_y_deg=0 means the hex corners point along the X axis (pointy-top)
- rot_y_deg=30 means flat-top orientation
