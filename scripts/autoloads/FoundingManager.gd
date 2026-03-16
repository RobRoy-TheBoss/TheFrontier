## FoundingManager
## Autoload singleton. Manages the settlement founding workflow (LFOUND-001..012).
## Coordinates: player purchases flag → surveyor dispatched → on_sleep() ticks timer →
## player reports to mayor → BatchProcessor completes founding.
extends Node

signal founding_complete(area_id: String)
signal founding_cancelled

## True while a founding attempt is in progress.
var founding_pending: bool = false

## The area targeted for founding.
var founding_area_id: String = ""

## Remaining surveyor travel time in in-game days.
var surveyor_timer: float = 0.0

## Set to true once surveyor_timer reaches zero.
var surveyor_complete: bool = false

## Set to true once the player has reported the survey to the origin mayor.
var reported_to_mayor: bool = false

## The settlement that sold the founding flag.
var origin_settlement_id: String = ""


# --- Workflow entry points ---

## Begin a founding attempt. Called when the player purchases a founding flag.
## timer_days is the number of sleep cycles before the surveyor is finished.
func start_founding(area_id: String, origin_id: String, timer_days: float) -> void:
	if founding_pending:
		push_warning("[FoundingManager] start_founding called while founding already pending.")
		return
	founding_pending      = true
	founding_area_id      = area_id
	origin_settlement_id  = origin_id
	surveyor_timer        = timer_days
	surveyor_complete     = false
	reported_to_mayor     = false
	print("[FoundingManager] Founding started for area '%s' (%.1f days)." % [area_id, timer_days])


## Called by the sleep/rest system each time the player sleeps until morning.
## Decrements the surveyor timer and marks completion when it reaches zero.
func on_sleep() -> void:
	if not founding_pending or surveyor_complete:
		return
	surveyor_timer -= 1.0
	if surveyor_timer <= 0.0:
		surveyor_timer    = 0.0
		surveyor_complete = true
		print("[FoundingManager] Surveyor has completed for area '%s'." % founding_area_id)


## Called by the player when they speak to the origin settlement's mayor after
## the surveyor has returned.
func report_to_mayor() -> void:
	if not surveyor_complete:
		push_warning("[FoundingManager] report_to_mayor called before surveyor is complete.")
		return
	reported_to_mayor = true


## Called by BatchProcessor step 0. Ticks the surveyor timer and, when all
## conditions are met (surveyor done + player reported), completes founding.
func try_complete_founding() -> void:
	if not founding_pending:
		return
	on_sleep()
	if surveyor_complete and reported_to_mayor:
		complete_founding()


## Called by BatchProcessor step 0 to complete the actual founding.
## Registers the new settlement and clears founding state.
func complete_founding() -> void:
	if not founding_pending:
		push_warning("[FoundingManager] complete_founding called with no pending founding.")
		return
	if not reported_to_mayor:
		push_warning("[FoundingManager] complete_founding called before report_to_mayor.")
		return

	var area := founding_area_id
	# Delegate to SettlementManager to create the settlement data.
	SettlementManager.found_settlement(area, origin_settlement_id)
	founding_complete.emit(area)
	_clear_state()
	print("[FoundingManager] Founding complete for area '%s'." % area)


## Cancel the current founding attempt and return state to idle.
## The surveyor is considered returned to origin_settlement_id (narrative only).
func cancel_founding() -> void:
	if not founding_pending:
		return
	print("[FoundingManager] Founding cancelled for area '%s'. Surveyor returned to '%s'." % [
		founding_area_id, origin_settlement_id])
	_clear_state()
	founding_cancelled.emit()


# --- Gate checks ---

## Returns true — a surveyor is always required to found a settlement (LFOUND-003).
func requires_surveyor() -> bool:
	return true


# --- Private helpers ---

func _clear_state() -> void:
	founding_pending      = false
	founding_area_id      = ""
	surveyor_timer        = 0.0
	surveyor_complete     = false
	reported_to_mayor     = false
	origin_settlement_id  = ""


# --- Save / Load helpers ---

func get_save_data() -> Dictionary:
	return {
		"founding_pending":      founding_pending,
		"founding_area_id":      founding_area_id,
		"surveyor_timer":        surveyor_timer,
		"surveyor_complete":     surveyor_complete,
		"reported_to_mayor":     reported_to_mayor,
		"origin_settlement_id":  origin_settlement_id
	}


func apply_save_data(data: Dictionary) -> void:
	founding_pending      = data.get("founding_pending",      false)
	founding_area_id      = data.get("founding_area_id",      "")
	surveyor_timer        = data.get("surveyor_timer",         0.0)
	surveyor_complete     = data.get("surveyor_complete",      false)
	reported_to_mayor     = data.get("reported_to_mayor",      false)
	origin_settlement_id  = data.get("origin_settlement_id",   "")
