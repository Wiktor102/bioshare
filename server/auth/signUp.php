<?php
session_start();
// require_once "../validateRequest.php"; To będzie w przyszłości do sprawdzania czy zapytanie naprawdę pochodzi z naszej aplikacji
require_once "../connect.php";
// require_once "./sendEmail.php";

function main()
{
	$credentials = json_decode(file_get_contents("php://input"), true);
	if ($credentials == null) {
		http_response_code(400);
		exit();
	}

	verify($credentials);

	// To jest do ewentualnej weryfikacji adresu e-mail
	// $verificationCode = md5(uniqid(rand(), true));
	// sendVerificationEmail($credentials["lang"], $credentials["mail"], $verificationCode);

	$passwordHash = password_hash($credentials["password"], PASSWORD_DEFAULT);
	createUser($credentials["mail"], $passwordHash);
	http_response_code(200);
	exit(json_encode(["userId" => $_SESSION["userId"]]));
}

/**
 * Tworzy użytkownika w bazie danych
 */
function createUser($mail, $passwordHash)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "INSERT INTO `user` (`email`, `password`)  VALUES (?, ?);";

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

	$stmt->bind_param("ss", $mail, $passwordHash);

	if ($stmt->execute()) {
		$_SESSION["userId"] = $stmt->insert_id;
		http_response_code(200);
	} else {
		if ($conn->errno === 1062) {
			$msg = json_encode(
				[
					"error" => $stmt->error,
					"type" => "dbError",
				],
				JSON_UNESCAPED_UNICODE
			);
			http_response_code(409);
			exit($msg);
		}

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

	$conn->close();
}

/**
 * Sprawdza czy e-mail i hasło spełniają wymagania
 */
function verify($credentials)
{
	$errors = [];

	function hasUppercase($string)
	{
		return (bool) preg_match("/[A-Z]/", $string);
	}

	if (!filter_var($credentials["mail"], FILTER_VALIDATE_EMAIL)) {
		array_push($errors, [
			"error" => "Nieprawidłowy adres E-mail",
			"errorEn" => "Invalid email address",
			"type" => "mail",
		]);
	}

	if (strlen($credentials["password"]) <= 0) {
		array_push($errors, [
			"error" => "Należy podać hasło",
			"type" => "password",
		]);
	}

	if (strlen($credentials["password"]) < 8) {
		array_push($errors, [
			"error" => "Hasło musi mieć co najmniej 8 znaków",
			"type" => "password",
		]);
	}

	if (!hasUppercase($credentials["password"])) {
		array_push($errors, [
			"error" => "Hasło musi zawierać wielką literę",
			"type" => "password",
		]);
	}

	if ($credentials["password"] != $credentials["password2"]) {
		array_push($errors, [
			"error" => "Hasła nie są zgodne",
			"type" => "password2",
		]);
	}

	if (!$credentials["terms"]) {
		array_push($errors, [
			"error" => "Musisz zaakceptować Regulamin",
			"type" => "terms",
		]);
	}

	if (!$credentials["privacy"]) {
		array_push($errors, [
			"error" => "Musisz zaakceptować Politykę Prywatności",
			"type" => "privacy",
		]);
	}

	if (!empty($errors)) {
		http_response_code(400);
		exit(json_encode(["errors" => $errors], JSON_UNESCAPED_UNICODE));
	}
}

main();

// DOKUMENTACJA
// Spodziewane wejście programu
//     HTTP method: POST
//     Format: JSON
//         {
//             "mail": "a@b.com"
//             "password": "3yt#$7t%0@!!2"
//             "password2": "3yt#$7t%0@!!2"
//             "terms": true / false
//             "privacy": true / false
//         }
//
//
// Możliwe wyjście programu (kody http)
// 200 -> JSON - Ok, rejestracja pomyślna. Format odpowiedzi:
//               {
//                   "userId": id użytkownika,
//               }
// 400 -> (puste) - błędne dane wejściowe, nie właściwa składnia JSON
//     -> JSON - błędy typu np. zbyt słabe hasło w formacie:
//               {"errors": [
//                   {error: "treść błędu", "type": "informacja pod którym polem powinien się pojawić błąd w UI"}
//                   ...
//               ]}
// 409 -> JSON - Użytkownik już istnieje. Błąd w podobnym formacie co przy kodzie 500.
// 500 -> JSON - Błąd SQL lub bazy danych w formacie:
//               {
//                   "error": "treść błędu",
//                   "errorNumber": "kod błędu,
//                   "type": "dbError lub sqlError
//                }
