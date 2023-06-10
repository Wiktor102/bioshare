<?php
session_start();
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
require_once realpath(dirname(__FILE__) . "/../vendor/autoload.php");
require_once "../connect.php";

$headers = getallheaders();
if (!array_key_exists("Authorization", $headers)) {
	http_response_code(401);
	exit();
}

$jwt = $headers["Authorization"];
$jwt = str_replace("Bearer ", "", $jwt);
$jwtSecretKey = file_get_contents(realpath(dirname(__FILE__) . "/.jwt-secret"));

try {
	$decodedRefreshToken = JWT::decode($jwt, new Key($jwtSecretKey, "HS256"));
	$correctRefreshToken = getUserRefreshToken($decodedRefreshToken->user_id); // this is is * from db

	if ($decodedRefreshToken != $correctRefreshToken["refresh_token"]) {
		http_response_code(401);
		exit();
	}

	$userData = [
		"id" => $decodedRefreshToken->user_id,
		"username" => $correctRefreshToken["username"],
		"email" => $correctRefreshToken["email"],
	];

	return json_encode(generateAccessToken($userData));
} catch (Exception $e) {
	http_response_code(403);
	exit(json_encode(["error" => $e->getMessage()], JSON_UNESCAPED_UNICODE));
}

function getUserRefreshToken($userId)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "SELECT * FROM `user` WHERE `id` = ?;";

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

	$result = $stmt->get_result();

	if ($result->num_rows == 0) {
		return null;
	}

	return $result->fetch_assoc()["refreshToken"];
}
