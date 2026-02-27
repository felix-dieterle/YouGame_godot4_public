<?php
/**
 * Shopping List API – business-logic functions
 *
 * This file is included by both api.php (production) and test_api.php (tests).
 * It relies on:
 *  - constants DATA_DIR, MAX_ITEMS_PER_LIST, MAX_LISTS, MAX_NAME_LENGTH
 *  - functions error_response() and success_response() defined by the caller
 */

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Generate a short random ID (8 hex chars). */
function generate_id(): string
{
    return bin2hex(random_bytes(4));
}

/**
 * Ensure the data directory exists.
 */
function ensure_data_dir(): void
{
    if (!is_dir(DATA_DIR)) {
        if (!mkdir(DATA_DIR, 0750, true)) {
            error_response('Server error: cannot create data directory.', 500);
        }
    }
}

/** Path to the index file that tracks all lists. */
function index_file(): string
{
    return DATA_DIR . '/index.json';
}

/**
 * Return the path to the data file for a single list.
 * Validates the list_id to prevent path traversal.
 */
function list_file(string $list_id): string
{
    if (!preg_match('/^[0-9a-f]{8}$/', $list_id)) {
        error_response('Invalid list_id format.');
    }
    return DATA_DIR . '/' . $list_id . '.json';
}

// ---------------------------------------------------------------------------
// Low-level persistence (flat JSON files)
// ---------------------------------------------------------------------------

/** Read the list index (array of {id, name, created_at}). */
function read_index(): array
{
    ensure_data_dir();
    $file = index_file();
    if (!file_exists($file)) {
        return [];
    }
    $raw = file_get_contents($file);
    if ($raw === false) {
        error_response('Server error: cannot read index.', 500);
    }
    return json_decode($raw, true) ?? [];
}

/** Persist the list index. */
function write_index(array $index): void
{
    ensure_data_dir();
    if (file_put_contents(index_file(), json_encode($index)) === false) {
        error_response('Server error: cannot write index.', 500);
    }
}

/** Read the items of a single list (array of {id, name, checked, created_at}). */
function read_list(string $list_id): array
{
    $file = list_file($list_id);
    if (!file_exists($file)) {
        error_response('List not found.', 404);
    }
    $raw = file_get_contents($file);
    if ($raw === false) {
        error_response('Server error: cannot read list.', 500);
    }
    return json_decode($raw, true) ?? [];
}

/** Persist the items of a single list. */
function write_list(string $list_id, array $items): void
{
    ensure_data_dir();
    if (file_put_contents(list_file($list_id), json_encode($items)) === false) {
        error_response('Server error: cannot write list.', 500);
    }
}

// ---------------------------------------------------------------------------
// Input parsing
// ---------------------------------------------------------------------------

/**
 * Return the decoded JSON request body.
 * In tests, a global $__test_request_body array can be set to override
 * reading from php://input.
 */
function request_body(): array
{
    global $__test_request_body;
    if (isset($__test_request_body) && is_array($__test_request_body)) {
        return $__test_request_body;
    }
    $raw = file_get_contents('php://input');
    if ($raw === false || $raw === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

/** Sanitise a plain text field (strip tags, trim, enforce max length). */
function sanitise(string $value): string
{
    return mb_substr(trim(strip_tags($value)), 0, MAX_NAME_LENGTH);
}

// ---------------------------------------------------------------------------
// Action handlers
// ---------------------------------------------------------------------------

function action_get_lists(): void
{
    $index = read_index();
    success_response(['lists' => $index]);
}

function action_create_list(): void
{
    $body = request_body();
    $name = sanitise($body['name'] ?? '');

    if ($name === '') {
        error_response('Field "name" is required.');
    }

    $index = read_index();
    if (count($index) >= MAX_LISTS) {
        error_response('Maximum number of lists reached.', 400);
    }

    $list_id = generate_id();
    $entry = [
        'id'         => $list_id,
        'name'       => $name,
        'created_at' => time(),
    ];

    $index[] = $entry;
    write_index($index);
    write_list($list_id, []);

    success_response(['list_id' => $list_id, 'list' => $entry]);
}

function action_get_list(): void
{
    $list_id = sanitise($_GET['list_id'] ?? '');
    if ($list_id === '') {
        error_response('Parameter "list_id" is required.');
    }

    $items = read_list($list_id);

    $index = read_index();
    $meta  = null;
    foreach ($index as $entry) {
        if ($entry['id'] === $list_id) {
            $meta = $entry;
            break;
        }
    }

    success_response(['list_id' => $list_id, 'meta' => $meta, 'items' => $items]);
}

function action_add_item(): void
{
    $body      = request_body();
    $list_id   = sanitise($body['list_id'] ?? '');
    $item_name = sanitise($body['item_name'] ?? '');

    if ($list_id === '') {
        error_response('Field "list_id" is required.');
    }
    if ($item_name === '') {
        error_response('Field "item_name" is required.');
    }

    $items = read_list($list_id);
    if (count($items) >= MAX_ITEMS_PER_LIST) {
        error_response('Maximum number of items per list reached.', 400);
    }

    $item = [
        'id'         => generate_id(),
        'name'       => $item_name,
        'checked'    => false,
        'created_at' => time(),
    ];

    $items[] = $item;
    write_list($list_id, $items);

    success_response(['item' => $item]);
}

function action_toggle_item(): void
{
    $body    = request_body();
    $list_id = sanitise($body['list_id'] ?? '');
    $item_id = sanitise($body['item_id'] ?? '');

    if ($list_id === '' || $item_id === '') {
        error_response('Fields "list_id" and "item_id" are required.');
    }

    $items  = read_list($list_id);
    $found  = false;
    $updated = null;
    foreach ($items as &$item) {
        if ($item['id'] === $item_id) {
            $item['checked'] = !$item['checked'];
            $found   = true;
            $updated = $item;
            break;
        }
    }
    unset($item);

    if (!$found) {
        error_response('Item not found.', 404);
    }

    write_list($list_id, $items);
    success_response(['item' => $updated]);
}

function action_delete_item(): void
{
    $body    = request_body();
    $list_id = sanitise($body['list_id'] ?? '');
    $item_id = sanitise($body['item_id'] ?? '');

    if ($list_id === '' || $item_id === '') {
        error_response('Fields "list_id" and "item_id" are required.');
    }

    $items  = read_list($list_id);
    $before = count($items);
    $items  = array_values(array_filter($items, fn($i) => $i['id'] !== $item_id));

    if (count($items) === $before) {
        error_response('Item not found.', 404);
    }

    write_list($list_id, $items);
    success_response(['deleted' => true]);
}

function action_delete_list(): void
{
    $body    = request_body();
    $list_id = sanitise($body['list_id'] ?? '');

    if ($list_id === '') {
        error_response('Field "list_id" is required.');
    }

    $index = read_index();
    $found = false;
    $index = array_values(array_filter($index, function ($e) use ($list_id, &$found) {
        if ($e['id'] === $list_id) {
            $found = true;
            return false;
        }
        return true;
    }));

    if (!$found) {
        error_response('List not found.', 404);
    }

    write_index($index);

    $file = list_file($list_id);
    if (file_exists($file)) {
        unlink($file);
    }

    success_response(['deleted' => true]);
}
