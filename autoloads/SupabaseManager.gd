# SupabaseManager.gd
# Uses Supabase Auth for email + password
extends Node

const SUPABASE_URL := "https://ehhngzbkzcranvygnyjo.supabase.co"
const ANON_KEY     := "sb_publishable_G5sL9znS3rCvH4BUitElIg_cLPIeF4n"

# ─── SESSION ───────────────────────────────────────────
var student_id:   String = ""
var full_name:    String = ""
var username:     String = ""
var section:      String = ""
var year_level:   String = ""
var access_token: String = ""
var is_logged_in: bool   = false

# ─── SIGNALS ───────────────────────────────────────────
signal register_completed(success: bool, message: String)
signal login_completed(success: bool, message: String)
signal logout_completed()
signal progress_saved(success: bool)
signal leaderboard_loaded(data: Array)

# ─── HEADERS ───────────────────────────────────────────
func _get_headers(auth := true) -> PackedStringArray:
	var token = access_token if (auth and access_token != "") else ANON_KEY
	return PackedStringArray([
		"apikey: "               + ANON_KEY,
		"Authorization: Bearer " + token,
		"Content-Type: application/json",
		"Prefer: return=representation"
	])

# ─── REGISTER ──────────────────────────────────────────
func register_student(
		p_full_name: String,
		p_username: String,
		p_email: String,
		p_password: String,
		p_year: String,
		p_section: String) -> void:

	# Step 1 — check username not taken
	var check_url = SUPABASE_URL + \
		"/rest/v1/students?username=eq." + p_username.uri_encode() + \
		"&select=id"
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_username_check.bind(
			http, p_full_name, p_username,
			p_email, p_password, p_year, p_section
		)
	)
	http.request(check_url, _get_headers(false), HTTPClient.METHOD_GET)

func _on_username_check(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest,
		p_full_name: String, p_username: String,
		p_email: String, p_password: String,
		p_year: String, p_section: String) -> void:
	http.queue_free()
	if code != 200:
		register_completed.emit(false, "Connection error. Try again.")
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array and parsed.size() > 0:
		register_completed.emit(false, "Username already taken.")
		return
	# Username free — create Supabase Auth account
	_create_auth_account(
		p_full_name, p_username,
		p_email, p_password,
		p_year, p_section
	)

func _create_auth_account(
		p_full_name: String, p_username: String,
		p_email: String, p_password: String,
		p_year: String, p_section: String) -> void:
	var url  = SUPABASE_URL + "/auth/v1/signup"
	var body = JSON.stringify({
		"email":    p_email,
		"password": p_password,
		"data": {
			"full_name":  p_full_name,
			"username":   p_username,
			"year_level": p_year,
			"section":    p_section,
		}
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_auth_created.bind(
			http, p_full_name, p_username, p_year, p_section
		)
	)
	http.request(url, _get_headers(false), HTTPClient.METHOD_POST, body)

func _on_auth_created(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest,
		p_full_name: String, p_username: String,
		p_year: String, p_section: String) -> void:
	http.queue_free()
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if code == 200 and parsed.has("access_token"):
		access_token = parsed["access_token"]
		student_id   = parsed["user"]["id"]
		full_name    = p_full_name
		username     = p_username
		year_level   = p_year
		section      = p_section
		is_logged_in = true
		_save_student_profile()
		register_completed.emit(true, "Account created! Welcome.")
		print("[Supabase] Registered: ", username)
	else:
		var msg = "Registration failed."
		if parsed.has("msg"):
			msg = parsed["msg"]
		elif parsed.has("message"):
			msg = parsed["message"]
		register_completed.emit(false, msg)

func _save_student_profile() -> void:
	var url  = SUPABASE_URL + "/rest/v1/students"
	var body = JSON.stringify({
		"id":         student_id,
		"full_name":  full_name,
		"username":   username,
		"year_level": year_level,
		"section":    section,
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_profile_saved.bind(http)
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

func _on_profile_saved(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest) -> void:
	http.queue_free()
	if code == 201:
		_create_initial_progress()
		_create_leaderboard_entry()

# ─── LOGIN ─────────────────────────────────────────────
func login_student(p_email: String, p_password: String) -> void:
	var url  = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({
		"email":    p_email,
		"password": p_password,
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_response.bind(http))
	http.request(url, _get_headers(false), HTTPClient.METHOD_POST, body)

func _on_login_response(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest) -> void:
	http.queue_free()
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if code == 200 and parsed.has("access_token"):
		access_token = parsed["access_token"]
		student_id   = parsed["user"]["id"]
		is_logged_in = true
		_load_student_profile()
	else:
		login_completed.emit(false, "Invalid email or password.")

func _load_student_profile() -> void:
	var url  = SUPABASE_URL + \
		"/rest/v1/students?id=eq." + student_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_profile_loaded.bind(http))
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

func _on_profile_loaded(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest) -> void:
	http.queue_free()
	if code == 200:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Array and parsed.size() > 0:
			var s    = parsed[0]
			full_name  = s.get("full_name",  "")
			username   = s.get("username",   "")
			year_level = s.get("year_level", "")
			section    = s.get("section",    "")
			_update_last_seen()
			load_progress_from_cloud()
			login_completed.emit(
				true, "Welcome back, " + full_name + "!"
			)
			print("[Supabase] Logged in: ", username)
		else:
			login_completed.emit(false, "Profile not found.")
	else:
		login_completed.emit(false, "Failed to load profile.")

# ─── LOGOUT ────────────────────────────────────────────
func logout() -> void:
	save_progress_to_cloud()
	update_leaderboard()
	student_id   = ""
	full_name    = ""
	username     = ""
	section      = ""
	year_level   = ""
	access_token = ""
	is_logged_in = false
	ProgressManager.reset_all_progress()
	logout_completed.emit()
	GameManager.go_to("login")
	print("[Supabase] Logged out.")

# ─── LAST SEEN ─────────────────────────────────────────
func _update_last_seen() -> void:
	var url  = SUPABASE_URL + \
		"/rest/v1/students?id=eq." + student_id
	var body = JSON.stringify({
		"last_seen": Time.get_datetime_string_from_system()
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_r, _c, _h, _b): http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_PATCH, body)

# ─── PROGRESS ──────────────────────────────────────────
func _create_initial_progress() -> void:
	var url  = SUPABASE_URL + "/rest/v1/progress"
	var body = JSON.stringify({"student_id": student_id})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_r, _c, _h, _b): http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

func save_progress_to_cloud() -> void:
	if not is_logged_in:
		return
	var url  = SUPABASE_URL + \
		"/rest/v1/progress?student_id=eq." + student_id
	var body = JSON.stringify({
		"topic_states":       ProgressManager.topic_states,
		"coding_accuracy":    ProgressManager.coding_accuracy,
		"retry_counts":       ProgressManager.retry_counts,
		"time_spent":         ProgressManager.time_spent,
		"unlocked_towers":    ProgressManager.unlocked_towers,
		"campaign_progress":  ProgressManager.campaign_progress,
		"updated_at":         Time.get_datetime_string_from_system()
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_r, _c, _h, _b): http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_PATCH, body)
	print("[Supabase] Progress saved.")

func load_progress_from_cloud() -> void:
	if not is_logged_in:
		return
	var url  = SUPABASE_URL + \
		"/rest/v1/progress?student_id=eq." + student_id
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_progress_loaded.bind(http))
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

func _on_progress_loaded(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest) -> void:
	http.queue_free()
	if code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array and parsed.size() > 0:
		var data = parsed[0]
		ProgressManager.topic_states      = data.get("topic_states",      {})
		ProgressManager.coding_accuracy   = data.get("coding_accuracy",   {})
		ProgressManager.retry_counts      = data.get("retry_counts",      {})
		ProgressManager.time_spent        = data.get("time_spent",        {})
		ProgressManager.campaign_progress = data.get("campaign_progress", {})
		var towers = data.get("unlocked_towers", [])
		ProgressManager.unlocked_towers.clear()
		for t in towers:
			ProgressManager.unlocked_towers.append(str(t))
		print("[Supabase] Progress loaded from cloud.")
		SignalBus.scene_change_requested.emit(
			"res://scenes/main_menu/MainMenu.tscn"
		)

# ─── LEADERBOARD ───────────────────────────────────────
func _create_leaderboard_entry() -> void:
	var url  = SUPABASE_URL + "/rest/v1/leaderboard"
	var body = JSON.stringify({
		"student_id": student_id,
		"full_name":  full_name,
		"username":   username,
		"section":    section,
		"year_level": year_level,
		"score":      0,
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_r, _c, _h, _b): http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

func update_leaderboard() -> void:
	if not is_logged_in:
		return
	var mastered := 0
	for topic_id in ProgressManager.topic_states:
		if ProgressManager.topic_states[topic_id] == "mastered":
			mastered += 1
	var levels     = ProgressManager.campaign_progress.get(
		"waves_completed", 0
	)
	var total_time: float = 0.0
	for t in ProgressManager.time_spent:
		total_time += float(ProgressManager.time_spent[t])
	var score  = (mastered * 100) + (levels * 150)
	var url    = SUPABASE_URL + \
		"/rest/v1/leaderboard?student_id=eq." + student_id
	var body   = JSON.stringify({
		"topics_mastered":           mastered,
		"campaign_levels_completed": levels,
		"total_time_spent":          total_time,
		"score":                     score,
		"updated_at": Time.get_datetime_string_from_system()
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_r, _c, _h, _b): http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_PATCH, body)

func fetch_leaderboard(section_filter: String = "") -> void:
	var url = SUPABASE_URL + \
		"/rest/v1/leaderboard?order=score.desc&limit=20"
	if section_filter != "":
		url += "&section=eq." + section_filter.uri_encode()
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_leaderboard_fetched.bind(http))
	http.request(url, _get_headers(false), HTTPClient.METHOD_GET)

func _on_leaderboard_fetched(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest) -> void:
	http.queue_free()
	if code != 200:
		leaderboard_loaded.emit([])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array:
		leaderboard_loaded.emit(parsed)

# ─── CAMPAIGN SCORE ────────────────────────────────────
func submit_campaign_score(
		level: int, time: float, wave_score: int) -> void:
	if not is_logged_in:
		return
	var url  = SUPABASE_URL + "/rest/v1/campaign_scores"
	var body = JSON.stringify({
		"student_id":      student_id,
		"username":        username,
		"section":         section,
		"level_number":    level,
		"completion_time": time,
		"wave_score":      wave_score
	})
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_r, _c, _h, _b): http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)
