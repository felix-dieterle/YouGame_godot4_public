<?php
/**
 * Unit tests for the Shopping List API
 *
 * Run from the command line:
 *   php test_api.php
 *
 * The script exits with code 0 on success and 1 on failure.
 */

// Use a temporary data directory so tests do not pollute real data.
define('DATA_DIR', sys_get_temp_dir() . '/shopping_list_test_' . uniqid());

// Inline the constants normally set by config.php
define('MAX_ITEMS_PER_LIST', 100);
define('MAX_LISTS', 50);
define('MAX_NAME_LENGTH', 100);
define('ALLOWED_ORIGIN', '*');

// ---------------------------------------------------------------------------
// Test doubles: override error_response / success_response before loading
// the business logic so the action handlers use these test versions.
// ---------------------------------------------------------------------------

class SuccessException extends RuntimeException
{
    public array $data;
    public function __construct(array $data)
    {
        parent::__construct('success');
        $this->data = $data;
    }
}

function error_response(string $message, int $code = 400): void
{
    throw new RuntimeException("ERROR $code: $message");
}

function success_response(array $data): void
{
    throw new SuccessException($data);
}

// ---------------------------------------------------------------------------
// Load business logic (functions only – no router, no headers)
// ---------------------------------------------------------------------------
require_once __DIR__ . '/api_functions.php';

// ---------------------------------------------------------------------------
// Test framework (tiny, self-contained)
// ---------------------------------------------------------------------------

$tests_passed = 0;
$tests_failed = 0;

function assert_equal($expected, $actual, string $label): void
{
    global $tests_passed, $tests_failed;
    if ($expected === $actual) {
        echo "[PASS] $label\n";
        $tests_passed++;
    } else {
        echo "[FAIL] $label\n";
        echo "       expected: " . var_export($expected, true) . "\n";
        echo "       actual:   " . var_export($actual, true) . "\n";
        $tests_failed++;
    }
}

function assert_true(bool $condition, string $label): void
{
    assert_equal(true, $condition, $label);
}

function assert_throws(callable $fn, string $label): void
{
    global $tests_passed, $tests_failed;
    try {
        $fn();
        echo "[FAIL] $label (no exception thrown)\n";
        $tests_failed++;
    } catch (RuntimeException $e) {
        echo "[PASS] $label\n";
        $tests_passed++;
    }
}

// ---------------------------------------------------------------------------
// Helper: call an action handler, inject a mock request body, and return data.
// ---------------------------------------------------------------------------
function call_action(string $fn_name, array $body = [], array $get = []): array
{
    global $__test_request_body;
    $__test_request_body = $body;

    foreach ($get as $k => $v) {
        $_GET[$k] = $v;
    }

    try {
        $fn_name();
    } catch (SuccessException $e) {
        return $e->data;
    }
    return [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

echo "=== Shopping List API Tests ===\n\n";

// --- generate_id ---
$id = generate_id();
assert_true(preg_match('/^[0-9a-f]{8}$/', $id) === 1, 'generate_id returns 8 hex chars');

// --- sanitise ---
assert_equal('hello', sanitise('  hello  '), 'sanitise trims whitespace');
assert_equal('hello', sanitise('<b>hello</b>'), 'sanitise strips tags');
assert_equal(str_repeat('a', MAX_NAME_LENGTH), sanitise(str_repeat('a', MAX_NAME_LENGTH + 50)), 'sanitise enforces max length');

// --- create_list ---
$result = call_action('action_create_list', ['name' => 'Test List']);
assert_true(isset($result['list_id']), 'create_list returns list_id');
assert_equal('Test List', $result['list']['name'], 'create_list stores correct name');
$list_id = $result['list_id'];

// --- get_lists ---
$result = call_action('action_get_lists');
assert_true(count($result['lists']) === 1, 'get_lists returns 1 list after creation');
assert_equal($list_id, $result['lists'][0]['id'], 'get_lists contains the created list');

// --- get_list (empty) ---
$result = call_action('action_get_list', [], ['list_id' => $list_id]);
assert_equal([], $result['items'], 'get_list returns empty items for new list');

// --- add_item ---
$result = call_action('action_add_item', ['list_id' => $list_id, 'item_name' => 'Bread']);
assert_true(isset($result['item']['id']), 'add_item returns item id');
assert_equal('Bread', $result['item']['name'], 'add_item stores correct name');
assert_equal(false, $result['item']['checked'], 'add_item item starts unchecked');
$item_id = $result['item']['id'];

// --- get_list (one item) ---
$result = call_action('action_get_list', [], ['list_id' => $list_id]);
assert_equal(1, count($result['items']), 'get_list returns 1 item after add');

// --- toggle_item ---
$result = call_action('action_toggle_item', ['list_id' => $list_id, 'item_id' => $item_id]);
assert_equal(true, $result['item']['checked'], 'toggle_item checks the item');

$result = call_action('action_toggle_item', ['list_id' => $list_id, 'item_id' => $item_id]);
assert_equal(false, $result['item']['checked'], 'toggle_item unchecks the item');

// --- delete_item ---
$result = call_action('action_delete_item', ['list_id' => $list_id, 'item_id' => $item_id]);
assert_equal(true, $result['deleted'], 'delete_item returns deleted=true');

$result = call_action('action_get_list', [], ['list_id' => $list_id]);
assert_equal(0, count($result['items']), 'get_list returns 0 items after delete');

// --- delete_item on non-existent item throws ---
assert_throws(
    fn() => call_action('action_delete_item', ['list_id' => $list_id, 'item_id' => 'deadbeef']),
    'delete_item throws for unknown item_id'
);

// --- delete_list ---
$result = call_action('action_delete_list', ['list_id' => $list_id]);
assert_equal(true, $result['deleted'], 'delete_list returns deleted=true');

$result = call_action('action_get_lists');
assert_equal(0, count($result['lists']), 'get_lists returns 0 lists after delete');

// --- validation: create_list with empty name ---
assert_throws(
    fn() => call_action('action_create_list', ['name' => '']),
    'create_list throws for empty name'
);

// --- validation: add_item with empty name ---
$r2 = call_action('action_create_list', ['name' => 'Validation List']);
$list_id2 = $r2['list_id'];
assert_throws(
    fn() => call_action('action_add_item', ['list_id' => $list_id2, 'item_name' => '']),
    'add_item throws for empty item_name'
);

// --- validation: invalid list_id format (path traversal) ---
assert_throws(
    fn() => call_action('action_get_list', [], ['list_id' => '../etc/passwd']),
    'list_file rejects path-traversal list_id'
);

// ---------------------------------------------------------------------------
// Cleanup temp directory
// ---------------------------------------------------------------------------
function rrmdir(string $dir): void
{
    if (!is_dir($dir)) {
        return;
    }
    foreach (scandir($dir) as $item) {
        if ($item === '.' || $item === '..') {
            continue;
        }
        $path = "$dir/$item";
        is_dir($path) ? rrmdir($path) : unlink($path);
    }
    rmdir($dir);
}
rrmdir(DATA_DIR);

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
echo "\n--- Results ---\n";
echo "Passed: $tests_passed\n";
echo "Failed: $tests_failed\n";
exit($tests_failed > 0 ? 1 : 0);

