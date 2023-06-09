<?php
require_once "./connect.php";
require_once "./auth/verify_jwt.php";

session_start();
header("Content-Type: application/json");

$credentials = verifyJWT();
$userId = $credentials["userId"];

$input = file_get_contents("php://input");
$inputJson = json_decode($input);

$method = $_SERVER["REQUEST_METHOD"];
$request = explode("/", substr(@$_SERVER["PATH_INFO"], 1));
$query = $_SERVER["QUERY_STRING"];

switch ($method) {
	case "POST":
		if ($inputJson == null) {
			http_response_code(400);
			exit();
		}

		createItem();
	case "DELETE":
		if (is_numeric($request[0])) {
			deleteItem($request[0]);
		} else {
			http_response_code(404);
			exit();
		}
	case "PATCH":
		if (!is_numeric($request[0]) || $inputJson == null) {
			http_response_code(400);
			exit();
		}

		switch ($request[1]) {
			case "expire":
				updateExpireDate($request[0], $inputJson->newExpireDate);
				break;
			case "amount":
				updateAmount($request[0], $inputJson->newAmount);
				break;
			default:
				http_response_code(404);
				exit();
				break;
		}

	default:
		http_response_code(405);
		header("Allow: POST, DELETE, PATCH");
		exit();
}

function createItem()
{
	global $inputJson;
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "INSERT INTO `item` VALUES (NULL, ?, ?, ?, ?, ?, ?);";

	if (!$stmt->prepare($sql)) {
		$msg = json_encode(
			[
				"error" => $stmt->error,
				"errorNumber" => $stmt->errno,
				"type" => "sqlError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	$name = $inputJson->name;
	$fridgeId = $inputJson->fridgeId;
	$category = $inputJson->category;
	$amount = $inputJson->amount;
	$unit = $inputJson->unit;
	$expire = $inputJson->expire;

	$stmt->bind_param("sissss", $name, $fridgeId, $category, $amount, $unit, $expire);

	if (!$stmt->execute()) {
		$msg = json_encode(
			[
				"error" => $conn->error,
				"errorCode" => $conn->errno,
				"type" => "dbError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	$inputJson->{"id"} = $stmt->insert_id;
	http_response_code(200);
	exit(json_encode($inputJson, JSON_UNESCAPED_UNICODE));
}

function deleteItem($id)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "DELETE FROM `item` WHERE `id` = ?;";

	if (!$stmt->prepare($sql)) {
		$msg = json_encode(
			[
				"error" => $stmt->error,
				"errorNumber" => $stmt->errno,
				"type" => "sqlError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	$stmt->bind_param("i", $id);

	if (!$stmt->execute()) {
		$msg = json_encode(
			[
				"error" => $conn->error,
				"errorCode" => $conn->errno,
				"type" => "dbError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	http_response_code(200);
	exit();
}

function updateExpireDate($id, $newDate)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "UPDATE `item` SET `expire` = ? WHERE `id` = ?;";

	if (!$stmt->prepare($sql)) {
		$msg = json_encode(
			[
				"error" => $stmt->error,
				"errorNumber" => $stmt->errno,
				"type" => "sqlError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	$stmt->bind_param("si", $newDate, $id);

	if (!$stmt->execute()) {
		$msg = json_encode(
			[
				"error" => $conn->error,
				"errorCode" => $conn->errno,
				"type" => "dbError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	if ($stmt->affected_rows == 0) {
		http_response_code(404);
		exit();
	}

	http_response_code(200);
	exit();
}

function updateAmount($id, $newAmount)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "UPDATE `item` SET `amount` = ? WHERE `id` = ?;";

	if (!$stmt->prepare($sql)) {
		$msg = json_encode(
			[
				"error" => $stmt->error,
				"errorNumber" => $stmt->errno,
				"type" => "sqlError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	$stmt->bind_param("si", $newAmount, $id);

	if (!$stmt->execute()) {
		$msg = json_encode(
			[
				"error" => $conn->error,
				"errorCode" => $conn->errno,
				"type" => "dbError",
			],
			JSON_UNESCAPED_UNICODE
		);
		http_response_code(500);
		exit($msg);
	}

	if ($stmt->affected_rows == 0) {
		http_response_code(404);
		exit();
	}

	http_response_code(200);
	exit();
}
