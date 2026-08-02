# SupabaseManager.gd
# Uses Supabase Auth for email + password
extends Node

const SUPABASE_URL := "https://ehhngzbkzcranvygnyjo.supabase.co"
const ANON_KEY     := "sb_publishable_G5sL9znS3rCvH4BUitElIg_cLPIeF4n"

# ─── SESSION ───────────────────────────────────────────
var student_id:   String = ""
var full_name:    String = ""
var username:     String = ""
var email:        String = ""
var section:      String = ""
var year_level:   String = ""
var access_token: String = ""
var last_login:  String = ""
var is_logged_in: bool   = false

# User metadata captured from the auth response, used to restore a
# missing students row at login (e.g. registration was interrupted).
var _auto_meta: Dictionary = {}

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
			http, p_full_name, p_username, p_email, p_year, p_section
		)
	)
	http.request(url, _get_headers(false), HTTPClient.METHOD_POST, body)

func _on_auth_created(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest,
		p_full_name: String, p_username: String, p_email: String,
		p_year: String, p_section: String) -> void:
	http.queue_free()
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if code == 200 and parsed.has("access_token"):
		access_token = parsed["access_token"]
		student_id   = parsed["user"]["id"]
		full_name    = p_full_name
		username     = p_username
		email        = p_email
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

func _save_student_profile(with_email := true) -> void:
	var url  = SUPABASE_URL + "/rest/v1/students"
	var body_dict := {
		"id":         student_id,
		"full_name":  full_name,
		"username":   username,
		"year_level": year_level,
		"section":    section,
	}
	if with_email and email != "":
		body_dict["email"] = email
	var body = JSON.stringify(body_dict)
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_profile_saved.bind(http, with_email)
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

func _on_profile_saved(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest, with_email: bool) -> void:
	http.queue_free()
	if code != 201 and code != 200:
		if with_email:
			# The students table may not have an email column yet —
			# retry the profile save without it.
			print("[Supabase] Profile save failed, retrying without email: ",
				code, " — ", body.get_string_from_utf8())
			_save_student_profile(false)
			return
		print("[Supabase] Failed to save profile: ", code,
			" — ", body.get_string_from_utf8())
		register_completed.emit(false, "Registration failed. Could not save profile.")
		return
	ProgressManager.reset_all_progress()
	_create_initial_progress()
	_create_leaderboard_entry()
	# Reset local progress for new user, then load fresh progress from cloud
	load_progress_from_cloud()

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

# Resolve a username to its email via the students table, then log in.
# Falls back to the legacy "username@packetsurge.com" convention for
# accounts created before email was collected.
func login_with_username(p_username: String, p_password: String) -> void:
	var url = SUPABASE_URL + \
		"/rest/v1/students?username=eq." + p_username.uri_encode() + \
		"&select=email"
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_username_email_resolved.bind(http, p_username, p_password)
	)
	http.request(url, _get_headers(false), HTTPClient.METHOD_GET)

func _on_username_email_resolved(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest,
		p_username: String, p_password: String) -> void:
	http.queue_free()
	var email := ""
	if code == 200:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Array and parsed.size() > 0:
			email = str(parsed[0].get("email", ""))
	if email == "":
		email = p_username.to_lower() + "@packetsurge.com"
	login_student(email, p_password)

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
		var user_data = parsed.get("user", {})
		_auto_meta = user_data.get("user_metadata", {})
		_auto_meta["email"] = user_data.get("email", "")
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
			var s      = parsed[0]
			full_name  = s.get("full_name",  "")
			username   = s.get("username",   "")
			email      = s.get("email",      "")
			year_level = s.get("year_level", "")
			section    = s.get("section",    "")
			last_login = s.get("last_seen", "")
			_update_last_seen()
			load_progress_from_cloud()   # ← loads progress THEN navigates
			login_completed.emit(
				true, "Welcome back, " + full_name + "!"
			)
			print("[Supabase] Logged in: ", username)
			return
		# No students row found — registration was probably interrupted
		# (e.g. before the email column existed). Restore it from the
		# auth metadata so login can continue normally.
		_restore_profile_from_metadata()
		return
	login_completed.emit(false, "Failed to load profile.")
	GameManager.go_to("login")

func _restore_profile_from_metadata() -> void:
	full_name  = str(_auto_meta.get("full_name",  full_name))
	username   = str(_auto_meta.get("username",   username))
	year_level = str(_auto_meta.get("year_level", year_level))
	section    = str(_auto_meta.get("section",    section))
	email      = str(_auto_meta.get("email",      email))
	# Save the row (retries without email if the column is missing),
	# then the normal post-save flow runs (progress, leaderboard, etc.).
	_save_student_profile()
	print("[Supabase] Restored missing student profile for: ", username)

# ─── LOGOUT ────────────────────────────────────────────
func logout() -> void:
	# Wait for the cloud save to complete before wiping local state.
	# This guarantees the cloud has the latest progress, even on a
	# slow network where the user closes the app quickly after logout.
	_save_progress_sync()
	update_leaderboard()
	student_id   = ""
	full_name    = ""
	username     = ""
	email        = ""
	section      = ""
	year_level   = ""
	last_login   = ""
	access_token = ""
	is_logged_in = false
	_auto_meta   = {}
	ProgressManager.reset_all_progress()
	logout_completed.emit()
	GameManager.go_to("login")
	print("[Supabase] Logged out.")

# Synchronous version of save_progress_to_cloud used at logout.
# Spins the message loop until the HTTP request completes (or times
# out after 5 seconds) so the caller can be sure the cloud is up to
# date before continuing.
func _save_progress_sync() -> void:
	if not is_logged_in:
		return
	var url  = SUPABASE_URL + "/rest/v1/progress"
	var body = JSON.stringify({
		"student_id":        student_id,
		"topic_states":      ProgressManager.topic_states,
		"time_spent":        ProgressManager.time_spent,
		"unlocked_towers":   ProgressManager.unlocked_towers,
		"campaign_progress": ProgressManager.campaign_progress,
		"updated_at":        Time.get_datetime_string_from_system()
	})
	var headers = _get_headers()
	headers.append("Prefer: resolution=merge-duplicates")
	var http := HTTPRequest.new()
	add_child(http)
	var done := [false]
	# Connect to the existing _on_progress_saved handler, then chain a
	# signal that flips our `done` flag so the wait loop can exit.
	http.request_completed.connect(_on_progress_saved.bind(http))
	http.request_completed.connect(
		func(_r, _c, _h, _b): done[0] = true
	)
	http.request(url, headers, HTTPClient.METHOD_POST, body)
	# Pump the message loop until the request finishes or times out.
	var elapsed := 0.0
	var timeout  := 5.0
	while not done[0] and elapsed < timeout:
		await get_tree().process_frame
		elapsed += 0.016

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
	# Use POST + merge-duplicates so the row is created if it doesn't
	# exist yet. PATCH on a non-existent row would silently update
	# nothing, which is what was losing progress on logout/login.
	var url  = SUPABASE_URL + "/rest/v1/progress"
	var body = JSON.stringify({
		"student_id":        student_id,
		"topic_states":      ProgressManager.topic_states,
		"time_spent":        ProgressManager.time_spent,
		"unlocked_towers":   ProgressManager.unlocked_towers,
		"campaign_progress": ProgressManager.campaign_progress,
		"updated_at":        Time.get_datetime_string_from_system()
	})
	var headers = _get_headers()
	headers.append("Prefer: resolution=merge-duplicates")
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_progress_saved.bind(http)
	)
	http.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_progress_saved(
		result: int, code: int,
		headers: PackedStringArray, body: PackedByteArray,
		http: HTTPRequest) -> void:
	http.queue_free()
	if code == 200 or code == 201:
		print("[Supabase] Progress saved.")
	else:
		print("[Supabase] Progress save FAILED: ", code, " — ", body.get_string_from_utf8())

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
		print("[Supabase] Failed to load progress: ", code)
		_navigate_after_login()
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array and parsed.size() > 0:
		var data = parsed[0]

		# Cloud is a backup, NOT the source of truth. Local was
		# already loaded from save.json in ProgressManager._ready().
		# We only apply cloud data when local is empty/reset (e.g.
		# the user logged in on a different device, or local save
		# was cleared by reset_all_progress). Otherwise we keep
		# local to avoid clobbering progress that hasn't synced yet.
		# A "freshly reset" local only has py_variables=unlocked and
		# max_level_unlocked=0, so we treat that as empty.
		var local_has_real_progress = false
		for topic_id in ProgressManager.topic_states:
			if ProgressManager.topic_states[topic_id] == "mastered":
				local_has_real_progress = true
				break
		if not local_has_real_progress:
			local_has_real_progress = (
				ProgressManager.unlocked_towers.size() > 0
				or ProgressManager.campaign_progress.get(
					"max_level_unlocked", 0
				) > 0
				or ProgressManager.campaign_progress.get(
					"waves_completed", 0
				) > 0
			)

		if not local_has_real_progress:
			# No local progress — pull everything from cloud.
			var cloud_states = data.get("topic_states", {})
			if cloud_states is Dictionary and cloud_states.size() > 0:
				ProgressManager.topic_states.clear()
				for key in cloud_states:
					ProgressManager.topic_states[str(key)] = str(cloud_states[key])

			var cloud_time = data.get("time_spent", {})
			if cloud_time is Dictionary and cloud_time.size() > 0:
				ProgressManager.time_spent = cloud_time

			var cloud_campaign = data.get("campaign_progress", {})
			if cloud_campaign is Dictionary and cloud_campaign.size() > 0:
				ProgressManager.campaign_progress = cloud_campaign

			var towers = data.get("unlocked_towers", [])
			if towers is Array and towers.size() > 0:
				ProgressManager.unlocked_towers.clear()
				for t in towers:
					ProgressManager.unlocked_towers.append(str(t))

			print("[Supabase] Progress loaded from cloud (local was empty).")
		else:
			# Local has progress — push it to cloud to make sure
			# cloud is up to date, but don't overwrite local.
			print("[Supabase] Local progress exists — keeping local, syncing to cloud.")
			ProgressManager.save_progress()
	else:
		print("[Supabase] No cloud progress found — keeping local.")

	# Always ensure base state after loading
	ProgressManager._ensure_base_state()
	_navigate_after_login()

func _navigate_after_login() -> void:
	print("[Supabase] Navigating to main menu.")
	GameManager.go_to("main_menu")

# ─── LEADERBOARD ───────────────────────────────────────
func _create_leaderboard_entry() -> void:
	var url  = SUPABASE_URL + "/rest/v1/leaderboard"
	var body = JSON.stringify({
		"student_id":     student_id,
		"full_name":      full_name,
		"username":       username,
		"section":        section,
		"year_level":     year_level,
		"score":          0,
		"total_stars":    0,
		"topics_mastered": 0,
		"campaign_levels_completed": 0,
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

	# ── Base score ──────────────────────────────
	var mastered := 0
	for topic_id in ProgressManager.topic_states:
		if ProgressManager.topic_states[topic_id] == "mastered":
			mastered += 1

	# ── Total stars from campaign ───────────────
	var star_map = ProgressManager.campaign_progress.get("level_stars", {})
	var total_stars := 0
	for level_num in star_map:
		total_stars += int(star_map[level_num])

	# ── Scoring: topics + stars ──────────────────
	var score = (mastered * 100) + (total_stars * 50)

	# ── Total time (kept for display only) ───────
	var total_time: float = 0.0
	for t in ProgressManager.time_spent:
		total_time += float(ProgressManager.time_spent[t])

	# ── Push to Supabase ────────────────────────
	var url  = SUPABASE_URL + \
		"/rest/v1/leaderboard?student_id=eq." + student_id
	var body = JSON.stringify({
		"topics_mastered":           mastered,
		"campaign_levels_completed": ProgressManager.campaign_progress.get("waves_completed", 0),
		"total_stars":               total_stars,
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

# ─── LEADERBOARD ───────────────────────────────────────
func fetch_leaderboard(section_filter: String = "") -> void:
	# Sort by score DESC (no time tiebreaker)
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
	else:
		leaderboard_loaded.emit([])
