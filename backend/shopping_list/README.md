# Shopping List Backend

A simple PHP REST API that enables **shared shopping lists** for the YouGame shopping list module.  
Lists and items are stored as flat JSON files – no database installation required.

## Requirements

- PHP 8.0+ (PHP 8.1+ recommended)
- A writable `data/` sub-directory (created automatically on first request)

## Deployment

1. Copy the `backend/shopping_list/` folder to any PHP-capable web server.
2. Ensure the web server process can write to the `data/` sub-directory.
3. Set the `backend_url` in your Godot `ShoppingListManager` to the public URL of `api.php`:
   ```
   https://yourserver.example.com/shopping_list/api.php
   ```
4. *(Optional)* Edit `config.php` to restrict `ALLOWED_ORIGIN` to your domain.

## API Reference

All requests go to `api.php`.  Responses are always JSON.

### GET `?action=get_lists`
Returns all shared lists.

**Response**
```json
{ "lists": [{ "id": "abcd1234", "name": "Weekly Shop", "created_at": 1700000000 }] }
```

---

### POST `?action=create_list`  `{ "name": "..." }`
Creates a new shared list.

**Response**
```json
{ "list_id": "abcd1234", "list": { "id": "abcd1234", "name": "Weekly Shop", "created_at": ... } }
```

---

### GET `?action=get_list&list_id=<id>`
Returns all items in a list.

**Response**
```json
{
  "list_id": "abcd1234",
  "meta": { "id": "abcd1234", "name": "Weekly Shop", "created_at": ... },
  "items": [{ "id": "deadbeef", "name": "Bread", "checked": false, "created_at": ... }]
}
```

---

### POST `?action=add_item`  `{ "list_id": "...", "item_name": "..." }`
Adds an item to a list.

**Response**
```json
{ "item": { "id": "deadbeef", "name": "Bread", "checked": false, "created_at": ... } }
```

---

### POST `?action=toggle_item`  `{ "list_id": "...", "item_id": "..." }`
Toggles the `checked` state of an item.

**Response**
```json
{ "item": { "id": "deadbeef", "name": "Bread", "checked": true, "created_at": ... } }
```

---

### POST `?action=delete_item`  `{ "list_id": "...", "item_id": "..." }`
Removes an item from a list.

**Response**
```json
{ "deleted": true }
```

---

### POST `?action=delete_list`  `{ "list_id": "..." }`
Deletes an entire list and all its items.

**Response**
```json
{ "deleted": true }
```

---

### Error responses
All errors return a non-2xx HTTP status and a body:
```json
{ "error": "Human-readable message" }
```

## Running the tests

```bash
cd backend/shopping_list
php test_api.php
```

Expected output: all 23 tests pass.

## Godot integration

The `scripts/systems/shopping_list.gd` GDScript autoload wraps all API calls.  
See inline documentation in that file for usage examples.

```gdscript
# Local (offline) mode – no server needed
var item = ShoppingListManager.add_item_local("Bread")
ShoppingListManager.toggle_item_local(item.id)
ShoppingListManager.remove_item_local(item.id)

# Shared mode
ShoppingListManager.backend_url = "https://yourserver.com/shopping_list/api.php"
ShoppingListManager.create_list_remote("Weekly Shop")   # emits list_updated with new list_id
ShoppingListManager.add_item_remote("Milk")
ShoppingListManager.fetch_list()
```

Connect to signals to react to changes:
```gdscript
ShoppingListManager.list_updated.connect(func(items): refresh_ui(items))
ShoppingListManager.request_error.connect(func(msg): show_error(msg))
```
