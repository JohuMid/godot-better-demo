# res://LanguageSelector.gd
extends OptionButton

var locale_names = {
	"zh_CN": "简体中文",
	"zh_TW": "繁體中文",
	"en": "English",
	"es": "Español",
}
var locale_flags = {
	"zh_CN": "1f1e8-1f1f3",
	"zh_TW": "1f1e8-1f1f3",
	"en": "1f1fa-1f1f8",
	"es": "1f1ea-1f1f8",
}

func _ready():
	var locales = TranslationServer.get_loaded_locales()
	var current = TranslationServer.get_locale()

	if !locales.has(current):
		locales.append(current)

	clear()
	for locale in locales:
		if locale in locale_names:
			var flag_texture = load("res://resources/gui/flags/" + locale_flags[locale] + ".png")
			add_icon_item(flag_texture,locale_names[locale])
			var idx = get_item_count() - 1          # 获取刚添加项的索引
			set_item_metadata(idx, locale)          # 绑定 locale 数据
			if locale == current:
				select(idx)

	item_selected.connect(_on_item_selected)


func _on_item_selected(index: int):
	var locale = get_item_metadata(index)
	TranslationServer.set_locale(locale)
	# 通知根节点更新翻译
	EventManager.emit(EventNames.TRANSLATION_CHANGED, [])
	get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
