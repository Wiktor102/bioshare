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
	default:
		http_response_code(405);
		header("Allow: GET, POST");
		exit();
}

function createItem()
{
	global $inputJson;
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "INSERT INTO `item` VALUES (NULL, ?, ?, ?, ?, ?);";

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
	$amount = $inputJson->amount;
	$unit = $inputJson->unit;
	$expire = $inputJson->expire;

	$stmt->bind_param("sisss", $name, $fridgeId, $amount, $unit, $expire);

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
