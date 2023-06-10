<?php
use Firebase\JWT\JWT;
require_once realpath(dirname(__FILE__) . "/../vendor/autoload.php");

function generateAccessToken($userData)
{
	$jwtSecretKey = file_get_contents("./.jwt-secret");
	// $expirationTime = time() + 60 * 60; // 1 hour
	$expirationTime = time() + 5; // 1 hour
	$payload = [
		"user_id" => $userData["id"], // According to the [spec](https://www.iana.org/assignments/jwt/jwt.xhtml) it should be called "sub"
		"preferred_username" => $userData["username"],
		"email" => $userData["email"],
		"exp" => $expirationTime,
	];

	$jwt = JWT::encode($payload, $jwtSecretKey, "HS256");
	return [
		"token" => $jwt,
		"expiration" => $expirationTime,
	];
}
