<?php
require_once "../connect.php";
require_once "./verify_jwt.php";

session_start();
$credentials = verifyJWT();
$userId = $credentials["userId"];

$conn = connect();
$stmt = $conn->stmt_init();
$sql = "UPDATE `user` SET `refreshToken` = NULL WHERE `id` = ?";

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

$stmt->bind_param("i", $userId);

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

session_unset();
http_response_code(200);
