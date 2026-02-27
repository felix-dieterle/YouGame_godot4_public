extends Node
# ShoppingListManager – manages shared shopping lists via the PHP backend
#
# Usage (local mode, no server):
#   var item = ShoppingListManager.add_item_local("Bread")
#   ShoppingListManager.toggle_item_local(item.id)
#   ShoppingListManager.remove_item_local(item.id)
#
# Usage (shared mode, requires backend):
#   ShoppingListManager.backend_url = "https://yourserver.com/shopping_list/api.php"
#   ShoppingListManager.set_list_id("abcd1234")       # join an existing list
#   ShoppingListManager.fetch_list()                   # load items from server
#   ShoppingListManager.add_item_remote("Milk")
#   ShoppingListManager.toggle_item_remote(item_id)
#   ShoppingListManager.remove_item_remote(item_id)

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal list_updated(items: Array)
signal request_error(message: String)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

## Base URL of the PHP backend (no trailing slash).
## Leave empty to work in local-only mode.
var backend_url: String = ""

## Currently active list ID (8 hex chars).
var current_list_id: String = ""

# ---------------------------------------------------------------------------
# Local state
# ---------------------------------------------------------------------------

## All items in the current list (local or synced from server).
## Each item is a Dictionary: {id, name, checked, created_at}
var items: Array = []

# Internal HTTP request node (created on demand)
var _http: HTTPRequest = null

# Queue of pending actions while a request is in-flight
var _pending_action: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	pass

# ---------------------------------------------------------------------------
# Local (offline) helpers
# ---------------------------------------------------------------------------

## Add an item to the local list. Returns the new item Dictionary.
func add_item_local(item_name: String) -> Dictionary:
	var item := {
		"id": _generate_id(),
		"name": item_name.strip_edges(),
		"checked": false,
		"created_at": int(Time.get_unix_time_from_system())
	}
	items.append(item)
	list_updated.emit(items)
	return item

## Toggle the checked state of a local item. Returns true on success.
func toggle_item_local(item_id: String) -> bool:
	for item in items:
		if item["id"] == item_id:
			item["checked"] = not item["checked"]
			list_updated.emit(items)
			return true
	return false

## Remove an item from the local list. Returns true on success.
func remove_item_local(item_id: String) -> bool:
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			items.remove_at(i)
			list_updated.emit(items)
			return true
	return false

## Clear all local items.
func clear_local() -> void:
	items.clear()
	list_updated.emit(items)

# ---------------------------------------------------------------------------
# Remote (shared) API helpers
# ---------------------------------------------------------------------------

## Set the list to sync (by ID obtained from the server).
func set_list_id(list_id: String) -> void:
	current_list_id = list_id

## Fetch the current list from the server and update local state.
func fetch_list() -> void:
	if not _is_remote_ready():
		return
	var url := "%s?action=get_list&list_id=%s" % [backend_url, current_list_id]
	_send_request(url, HTTPClient.METHOD_GET, {}, {"_action": "fetch_list"})

## Add an item on the server.
func add_item_remote(item_name: String) -> void:
	if not _is_remote_ready():
		return
	var body := {"list_id": current_list_id, "item_name": item_name.strip_edges()}
	_send_request(
		"%s?action=add_item" % backend_url,
		HTTPClient.METHOD_POST,
		body,
		{"_action": "add_item"}
	)

## Toggle an item's checked state on the server.
func toggle_item_remote(item_id: String) -> void:
	if not _is_remote_ready():
		return
	var body := {"list_id": current_list_id, "item_id": item_id}
	_send_request(
		"%s?action=toggle_item" % backend_url,
		HTTPClient.METHOD_POST,
		body,
		{"_action": "toggle_item"}
	)

## Delete an item on the server.
func remove_item_remote(item_id: String) -> void:
	if not _is_remote_ready():
		return
	var body := {"list_id": current_list_id, "item_id": item_id}
	_send_request(
		"%s?action=delete_item" % backend_url,
		HTTPClient.METHOD_POST,
		body,
		{"_action": "delete_item"}
	)

## Create a new shared list on the server. Emits list_updated when done.
func create_list_remote(list_name: String) -> void:
	if backend_url.is_empty():
		request_error.emit("backend_url is not set")
		return
	var body := {"name": list_name.strip_edges()}
	_send_request(
		"%s?action=create_list" % backend_url,
		HTTPClient.METHOD_POST,
		body,
		{"_action": "create_list"}
	)

# ---------------------------------------------------------------------------
# HTTP internals
# ---------------------------------------------------------------------------

func _is_remote_ready() -> bool:
	if backend_url.is_empty():
		request_error.emit("backend_url is not set")
		return false
	if current_list_id.is_empty():
		request_error.emit("current_list_id is not set")
		return false
	return true

func _send_request(url: String, method: int, body: Dictionary, meta: Dictionary) -> void:
	if _http != null and _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		# A request is already in-flight; queue is not implemented yet – emit error
		request_error.emit("A request is already in progress")
		return

	if _http == null:
		_http = HTTPRequest.new()
		add_child(_http)
		_http.request_completed.connect(_on_request_completed)

	_pending_action = meta

	var headers := PackedStringArray(["Content-Type: application/json"])
	var body_string := JSON.stringify(body) if not body.is_empty() else ""
	var err := _http.request(url, headers, method, body_string)
	if err != OK:
		request_error.emit("HTTP request failed (error %d)" % err)

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		request_error.emit("Network error (result %d)" % result)
		return

	if response_code < 200 or response_code >= 300:
		request_error.emit("Server error %d" % response_code)
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		request_error.emit("Failed to parse server response")
		return

	var data: Dictionary = json.get_data()
	_handle_response(data)

func _handle_response(data: Dictionary) -> void:
	var action: String = _pending_action.get("_action", "")
	_pending_action = {}

	match action:
		"fetch_list":
			if data.has("items"):
				items = data["items"]
				list_updated.emit(items)
		"add_item":
			if data.has("item"):
				items.append(data["item"])
				list_updated.emit(items)
		"toggle_item":
			if data.has("item"):
				var updated: Dictionary = data["item"]
				for i in range(items.size()):
					if items[i]["id"] == updated["id"]:
						items[i] = updated
						break
				list_updated.emit(items)
		"delete_item":
			# The server doesn't tell us which item was deleted; re-fetch
			if current_list_id != "":
				fetch_list()
		"create_list":
			if data.has("list_id"):
				current_list_id = data["list_id"]
				items = []
				list_updated.emit(items)
		_:
			push_warning("ShoppingListManager: unhandled response action '%s'" % action)

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

## Generate a random 8-character hex ID (local use only).
func _generate_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x" % (rng.randi() & 0xFFFFFFFF)

## Return a copy of the current items array sorted by creation time.
func get_items_sorted() -> Array:
	var sorted := items.duplicate()
	sorted.sort_custom(func(a, b): return a["created_at"] < b["created_at"])
	return sorted

## Return only unchecked items.
func get_unchecked_items() -> Array:
	return items.filter(func(item): return not item["checked"])

## Return only checked items.
func get_checked_items() -> Array:
	return items.filter(func(item): return item["checked"])
