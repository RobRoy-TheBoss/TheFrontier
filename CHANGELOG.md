# Changelog

## [Unreleased]

### Added
- Home Storage chest (INV-003): interactable HomeChest near spawn opens infinite shared storage
- StorageUI keyboard navigation: W/S to move selection, A/D to switch panels, E to transfer
- StorageUI quantity picker: E on a stack drops a sub-row; A/D adjust quantity, E confirms partial transfer
- StorageUI carry weight display: live current/max kg label at top
- Two-tier carry weight system (LPC-012/013/047): soft cap (50 kg) and hard cap (100 kg)
- Double-tap sprint (PC-002): double-tap any movement key to sprint; Left Shift = crouch
- Third-person camera zoom (PC-001): scroll wheel adjusts SpringArm3D spring length
- GUT test suites: test_home_storage, test_camera_zoom, test_player_movement (traced to LLR v0.7.1)
- Proposed-Requirement-Changes.md: all 10 PRCs resolved

### Fixed
- Player input correctly blocked while any UI is open (is_paused_for_ui guard in Player._input)
- StorageUI stack splitting: _confirm_transfer no longer clears _quantity_mode before transfer
- DisciplineManager.get_passive_effect() falls back to ability dict when no effect_data nesting
- Monster.State enum: FLEE and DESPAWN added as first-class states
- Per-monster injury_chances routing in PlayerHealth.try_combat_injury_roll()
- PlayerInventory.socket_rune() validates allowed_slot_types against equipped item type
- AreaManager.TOWN_TIER_INDEX corrected to 3 (was 2)
- PlayerInventory.currency is sole gold source (PlayerStats.gold removed)
