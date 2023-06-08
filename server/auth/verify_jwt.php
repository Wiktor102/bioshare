<?php
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
require_once realpath(dirname(__FILE__) . "/../vendor/autoload.php");

function verifyJWT()
{
	$headers = getallheaders();
	// print_r($headers);
	if (!array_key_exists("authorization", $headers)) {
		http_response_code(401);
		exit();
	}

	$jwt = $headers["authorization"];
	$jwt = str_replace("Bearer ", "", $jwt);
	$jwtSecretKey = file_get_contents(realpath(dirname(__FILE__) . "/.jwt-secret"));

	try {
		$decodedToken = JWT::decode($jwt, new Key($jwtSecretKey, "HS256"));
		return [
			"userId" => $decodedToken->user_id,
			"username" => $decodedToken->preferred_username,
			"exp" => $decodedToken->exp,
		];
	} catch (Exception $e) {
		http_response_code(403);
		exit(json_encode(["error" => $e->getMessage()], JSON_UNESCAPED_UNICODE));
	}
}
