extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	test_desktop_export_presets_exist()
	test_release_presets_exclude_development_only_resources()
	test_release_project_has_no_development_autoload()
	test_desktop_texture_compression_setting_allows_macos_export()
	if failures.is_empty():
		print("All export readiness tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_desktop_export_presets_exist() -> void:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	_expect_eq(error, OK, "export_presets.cfg should load")
	if error != OK:
		return

	var required := {
		"macOS": {
			"platform": "macOS",
			"path_suffix": "builds/desktop/macos/SisyphusDownhill.zip",
		},
		"Windows Desktop": {
			"platform": "Windows Desktop",
			"path_suffix": "builds/desktop/windows/SisyphusDownhill.exe",
		},
		"Linux": {
			"platform": "Linux",
			"path_suffix": "builds/desktop/linux/SisyphusDownhill.x86_64",
		},
	}
	var found := {}
	for section in config.get_sections():
		if not section.begins_with("preset.") or section.contains(".options"):
			continue
		var preset_name: String = str(config.get_value(section, "name", ""))
		if not required.has(preset_name):
			continue
		found[preset_name] = true
		var preset: Dictionary = required[preset_name]
		_expect_eq(str(config.get_value(section, "platform", "")), preset["platform"], "%s should use the expected export platform" % preset_name)
		_expect_eq(bool(config.get_value(section, "runnable", false)), true, "%s preset should be runnable" % preset_name)
		var export_path := str(config.get_value(section, "export_path", ""))
		_expect_true(export_path.ends_with(preset["path_suffix"]), "%s export path should target %s, got %s" % [preset_name, preset["path_suffix"], export_path])

	for preset_name in required.keys():
		_expect_true(found.has(preset_name), "missing desktop export preset: %s" % preset_name)


func test_release_presets_exclude_development_only_resources() -> void:
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		return
	for section in config.get_sections():
		if not section.begins_with("preset.") or section.contains(".options"):
			continue
		var preset_name: String = str(config.get_value(section, "name", ""))
		var exclude_filter := str(config.get_value(section, "exclude_filter", ""))
		_expect_true(exclude_filter.contains("addons/*"), "%s should exclude editor addons from release exports" % preset_name)
		_expect_true(exclude_filter.contains("tests/*"), "%s should exclude test scripts from release exports" % preset_name)
		_expect_true(exclude_filter.contains(".godot/*"), "%s should exclude editor cache from release exports" % preset_name)


func test_release_project_has_no_development_autoload() -> void:
	var autoloads := ProjectSettings.get_property_list().filter(func(property): return str(property.name).begins_with("autoload/"))
	for property in autoloads:
		var value := str(ProjectSettings.get_setting(property.name, ""))
		_expect_true(not value.contains("res://addons/"), "release project autoload should not depend on editor addon code: %s=%s" % [property.name, value])


func test_desktop_texture_compression_setting_allows_macos_export() -> void:
	var enabled := bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false))
	_expect_true(enabled, "ETC2 ASTC import should be enabled so macOS universal/arm64 exports are not blocked by project settings")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
