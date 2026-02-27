<?php
/**
 * Shopping List REST API – entry point
 *
 * Endpoints:
 *   GET  ?action=get_lists                          – list all shared lists
 *   POST ?action=create_list  {name}                – create a new list, returns {list_id}
 *   GET  ?action=get_list     &list_id=<id>         – get items of one list
 *   POST ?action=add_item     {list_id, item_name}  – add item, returns {item_id}
 *   POST ?action=toggle_item  {list_id, item_id}    – toggle checked state
 *   POST ?action=delete_item  {list_id, item_id}    – remove an item
 *   POST ?action=delete_list  {list_id}             – remove an entire list
 */

require_once __DIR__ . '/config.php';

// ---------------------------------------------------------------------------
// CORS & content-type headers
// ---------------------------------------------------------------------------
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ---------------------------------------------------------------------------
// Response helpers (production versions – send JSON and exit)
// ---------------------------------------------------------------------------

/** Return a JSON error response and exit. */
function error_response(string $message, int $code = 400): void
{
    http_response_code($code);
    echo json_encode(['error' => $message]);
    exit;
}

/** Return a JSON success response and exit. */
function success_response(array $data): void
{
    http_response_code(200);
    echo json_encode($data);
    exit;
}

// ---------------------------------------------------------------------------
// Business-logic functions (shared with tests)
// ---------------------------------------------------------------------------
require_once __DIR__ . '/api_functions.php';

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

$action = $_GET['action'] ?? (request_body()['action'] ?? '');

switch ($action) {
    case 'get_lists':
        action_get_lists();
        break;
    case 'create_list':
        action_create_list();
        break;
    case 'get_list':
        action_get_list();
        break;
    case 'add_item':
        action_add_item();
        break;
    case 'toggle_item':
        action_toggle_item();
        break;
    case 'delete_item':
        action_delete_item();
        break;
    case 'delete_list':
        action_delete_list();
        break;
    default:
        error_response('Unknown action. See API documentation.', 400);
}
