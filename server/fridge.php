<?php
// require "./vendor/autoload.php";
require_once "./connect.php";
require_once "./auth/verify_jwt.php";

session_start();
header("Content-Type: application/json; charset=utf-8");

$userId = null;

$input = file_get_contents("php://input");
$inputJson = json_decode($input, true);

$method = $_SERVER["REQUEST_METHOD"];
$request = explode("/", substr(@$_SERVER["PATH_INFO"], 1));
$query = $_SERVER["QUERY_STRING"];

switch ($method) {
	case "POST":
		$credentials = verifyJWT();
		$userId = $credentials["userId"];

		if ($inputJson == null) {
			http_response_code(400);
			exit();
		}

		createFridge();
	case "GET":
		if ($request[0] == "") {
			getFridge();
		}

		if (is_numeric($request[0]) && $request[1] == "items") {
			getItemsInFridge($request[0]);
		}
	default:
		http_response_code(405);
		header("Allow: GET, POST");
		exit();
}

function createFridge()
{
	global $inputJson, $userId;
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "INSERT INTO `fridge`VALUES (NULL, ?, ?, POINT(?, ?), ?, ?);";

	$name = $inputJson["name"];
	$lat = $inputJson["location"][0];
	$lng = $inputJson["location"][1];
	$address = $inputJson["address"];
	$desc = $inputJson["description"];

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

	$stmt->bind_param("siiiss", $name, $userId, $lat, $lng, $address, $desc);

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

	$inputJson["id"] = $stmt->insert_id;
	$inputJson["admin"] = $userId;

	http_response_code(200);
	exit(json_encode($inputJson, JSON_UNESCAPED_UNICODE));
}

function getFridge()
{
	$conn = connect();
	$sql =
		"SELECT `id`, `name`, `admin`, ST_X(`location`) AS `lat`, ST_Y(`location`) AS `lng`, `address`, `description` FROM `fridge`;";

	if ($result = $conn->query($sql)) {
		if ($result->num_rows <= 0) {
			http_response_code(404);
			exit();
		}

		$rows = [];
		while ($row = $result->fetch_assoc()) {
			$rows[] = $row;
		}

		http_response_code(200);
		exit(json_encode($rows, JSON_UNESCAPED_UNICODE));
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

function getItemsInFridge($fridgeId)
{
	$conn = connect();
	$stmt = $conn->stmt_init();
	$sql = "SELECT * FROM `item` WHERE `fridge` = ?;";

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

	$stmt->bind_param("i", $fridgeId);

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
	if ($result->num_rows <= 0) {
		http_response_code(404);
		exit();
	}

	$rows = [];
	while ($row = $result->fetch_assoc()) {
		$rows[] = $row;
	}

	http_response_code(200);
	exit(json_encode($rows, JSON_UNESCAPED_UNICODE));
}

// DOKUMENTACJA
// Obsługiwane metody HTTP: GET
//
// GET:
//       Opis: Zwraca wszystkie istniejące lodówki.
//       Spodziewane wejście programu - brak
//       Możliwe wyjście programu (kody http)
//           200 -> JSON - Ok, brak błędów. Format odpowiedzi:
//               [
//                   {
//                       "id": int,
//                       "admin": int,
//                       "location": [float, float],
//                       "address": string,
//                       "description": string
//                   }
//                  ...
//               ]
//           404 -> (puste) - Lodówka o podanych parametrach nie istnieje.
//           500 -> JSON - Błąd SQL lub bazy danych w formacie:
//               {
//                   "error": "treść błędu",
//                   "errorNumber": "kod błędu,
//                   "type": "dbError lub sqlError
//               }
// POST:
//       Opis: Tworzy nową lodówkę.
//       Spodziewane wejście programu - brak
//       Możliwe wyjście programu (kody http)
//           200 -> JSON - Ok, brak błędów. Zwraca wysłane dane razem z dopisanym polem 'id' i 'admin' ('admin' to id obecnego użytkownika)
//           400 -> (puste) - Błędne dane wejściowe, nie właściwa składnia JSON.
//           403 -> (puste) - Brak dostępu. Użytkownik nie jest zalogowany.
//           500 -> JSON - Błąd SQL lub bazy danych w formacie:
//               {
//                   "error": "treść błędu",
//                   "errorNumber": "kod błędu,
//                   "type": "dbError lub sqlError
//               }
// Inne kody błędów http:
//           405 -> (puste) - Nieobsługiwana metoda http.
