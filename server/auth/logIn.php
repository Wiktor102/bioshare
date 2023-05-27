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

	$mail = $credentials["mail"];
	$userData = getUserData($mail);

	$correctPasswordHash = $userData["password"];
	$passwordCorrect = password_verify($credentials["password"], $correctPasswordHash);

	if (!$passwordCorrect) {
		http_response_code(404);
		exit(
			json_encode(
				[
					"error" => "Niepoprawny adres e-mail lub hasło",
				],
				JSON_UNESCAPED_UNICODE
			)
		);
	}

	// W przyszłości tutaj sprawdzać czy e-mail jest zweryfikowany

	$_SESSION["userId"] = $userData["id"];
	exit(json_encode(["userId" => $_SESSION["userId"]]));
}

function getUserData($mail)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "SELECT * FROM `user` WHERE `email` = ?;";

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

	$stmt->bind_param("s", $mail);

	if ($stmt->execute()) {
		$result = $stmt->get_result();

		if ($result->num_rows <= 0) {
			http_response_code(404); // check if correct code

			exit(
				json_encode(
					[
						"error" => "Niepoprawny adres e-mail lub hasło",
					],
					JSON_UNESCAPED_UNICODE
				)
			);
		}

		return $result->fetch_assoc();
	} else {
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
}

main();

// DOKUMENTACJA
// Spodziewane wejście programu
//     HTTP method: POST
//     Format: JSON
//         {
//             "mail": "a@b.com"
//             "password": "3yt#$7t%0@!!2"
//         }
//
//
// Możliwe wyjście programu (kody http)
// 200 -> JSON - Ok, logowanie pomyślne. Format odpowiedzi:
//               {
//                   "userId": id użytkownika,
//               }
// 400 -> (puste) - błędne dane wejściowe, nie właściwa składnia JSON.
// 404 -> JSON - Użytkownik o podanym adresie e-mail i haśle nie istnieje. Format wiadomości o błędzie:
//               {
//                   "error": "treść błędu do wyświetlenia w UI",
//               }
// 500 -> JSON - Błąd SQL lub bazy danych w formacie:
//               {
//                   "error": "treść błędu",
//                   "errorNumber": "kod błędu,
//                   "type": "dbError lub sqlError
//                }
