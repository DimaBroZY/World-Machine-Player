const translations = {
  ru: {
    title: "World Machine Player - скачать Jukebox из OneShot WME",
    description: "World Machine Player - фанатская реализация Jukebox из OneShot: World Machine Edition на Godot. Прямое скачивание, GitHub, баг-репорты и предложения.",
    nav_features: "Возможности",
    nav_help: "Помощь",
    nav_radio: "Радио",
    nav_home: "Главная",
    nav_issues: "Issues",
    nav_download: "Скачать",
    hero_eyebrow: "Godot fan project для Windows",
    hero_title: "World Machine Player",
    hero_lead: "Фанатская реализация Jukebox из OneShot: World Machine Edition. Запускай свою папку с музыкой, переключай треки, меняй скорость, громкость и тему оформления.",
    btn_download: "Скачать",
    hero_github: `<span class="button-icon" aria-hidden="true">↗</span>
              GitHub`,
    hero_formats_dt: "Форматы",
    hero_platform_dt: "Платформа",
    download_kicker: "Последний публичный релиз",
    download_title: "Скачать World Machine Player",
    download_desc: "Прямая ссылка ведет на <code>World.Machine.Player.zip</code> из GitHub Releases. Распакуй архив и запусти <code>WorldMachinePlayer.exe</code>.",
    features_kicker: "Возможности",
    features_title: "Плеер для своей папки с музыкой",
    feat_playback_title: "Воспроизведение",
    feat_playback_desc: "Поддержка <code>.ogg</code>, <code>.mp3</code>, <code>.flac</code> и <code>.opus</code> — воспроизведение локальных треков из папки.",
    feat_playlists_title: "Плейлисты",
    feat_playlists_desc: "Создавай плейлисты и собирай треки в подборки — удобно для альбомов, сетов и любимых композиций.",
    feat_radio_title: "Интернет-радио",
    feat_radio_desc: 'Добавляй станции по URL — MP3-потоки из каталогов вроде <code>radio-browser.info</code>. Инструкция в <a href="docs/radio.html">docs/radio.html</a>.',
    feat_theme_title: "Кастомизация",
    feat_theme_desc: "Несколько визуальных тем для внешнего вида плеера и настроения.",
    feat_settings_title: "Настройки",
    feat_settings_desc: "Можно указать свою папку с музыкой. Настройки сохраняются автоматически.",
    how_kicker: "Быстрый старт",
    how_title: "Запуск в четыре шага",
    step_1: "Скачай последнюю версию из GitHub Releases.",
    step_2: "Запусти <code>WorldMachinePlayer.exe</code>.",
    step_3: "Через настройки укажи папку с музыкой.",
    step_4: "Положи туда аудиофайлы, плеер просканирует их сам.",
    feedback_kicker: "GitHub Issues",
    feedback_title: "Баги и идеи кидай прямо в репозиторий",
    feedback_desc: "Issues ведут в тот же проект, где лежит исходный код. Так репорт или предложение не потеряется.",
    bug_span: "Баг",
    bug_strong: "Сообщить о проблеме",
    idea_span: "Идея",
    idea_strong: "Предложить фичу",
    credits_kicker: "Фан-проект",
    credits_title: "Сделано для сообщества OneShot",
    credits_desc: "World Machine Player основан на OneShot: World Machine Edition. Права на персонажей, музыку и материалы принадлежат Team OneShot и Future Cat LLC.",
    radio_title: "World Machine Player — как добавить радио",
    radio_description: "Как добавить интернет-радио в World Machine Player: поиск станций на radio-browser.info и добавление MP3-потоков.",
    radio_kicker: "Помощь",
    radio_page_title: "Как добавить радиостанции",
    radio_lead: 'World Machine Player умеет воспроизводить интернет-радио. Добавь станцию по имени и URL потока — ниже пошаговая инструкция для плеера и для поиска ссылок на <a href="https://www.radio-browser.info/" target="_blank" rel="noreferrer">radio-browser.info</a>.',
    radio_player_kicker: "World Machine Player",
    radio_player_title: "Добавление станции в плеере",
    radio_player_step1: "Открой вкладку <strong>Radio</strong> в плеере.",
    radio_player_step2: "Нажми кнопку <strong>[+ADD RADIO]</strong>.",
    radio_player_step3: "В диалоге заполни поля <strong>Name</strong> (название) и <strong>URL</strong> (ссылка на поток).",
    radio_player_step4: "Подтверди добавление — станция появится в списке, её можно выбрать и слушать.",
    radio_fig_tab: "Вкладка Radio и кнопка [+ADD RADIO]",
    radio_fig_tab_alt: "Вкладка Radio в World Machine Player с кнопкой добавления станции",
    radio_fig_dialog: "Диалог Add Radio: поля Name и URL",
    radio_fig_dialog_alt: "Диалог добавления радиостанции с полями Name и URL",
    radio_fig_list: "Станция в списке после добавления",
    radio_fig_list_alt: "Добавленная радиостанция в списке World Machine Player",
    radio_browser_kicker: "radio-browser.info",
    radio_browser_title: "Где взять URL радиостанции",
    radio_browser_intro: '<a href="https://www.radio-browser.info/" target="_blank" rel="noreferrer">radio-browser.info</a> — открытый каталог интернет-радио. Найди станцию с потоком в формате <strong>MP3</strong> и скопируй прямую ссылку.',
    radio_mp3_label: "Важно: только MP3",
    radio_mp3_desc: "World Machine Player поддерживает радиопотоки в формате MP3. При выборе станции ищи тег <code>MP3</code> в списке — потоки AAC, OGG и других форматов могут не воспроизводиться.",
    radio_browser_step1: 'Открой <a href="https://www.radio-browser.info/" target="_blank" rel="noreferrer">radio-browser.info</a>.',
    radio_browser_step2: "Перейди в раздел <strong>By category</strong> → <strong>By tag</strong> или воспользуйся поиском.",
    radio_browser_step3: "Найди интересующий тег, например <code>lofi</code>, и открой список станций.",
    radio_browser_step4: "Выбери станцию с тегом <strong>MP3</strong> в строке списка.",
    radio_browser_step5: "Нажми кнопку <strong>Save</strong> в строке станции.",
    radio_browser_step6: "Браузер откроет страницу потока — скопируй URL из адресной строки (например, <code>https://usa9.fastcast4u.com/proxy/jamz?mp=/1</code>).",
    radio_browser_step7: "Вставь скопированный URL в поле <strong>URL</strong> при добавлении радио в World Machine Player.",
    radio_fig_home: "Главная страница radio-browser.info",
    radio_fig_home_alt: "Главная страница каталога radio-browser.info",
    radio_fig_browse: "By category → By tag",
    radio_fig_browse_alt: "Навигация By category и By tag на radio-browser.info",
    radio_fig_search: "Поиск тега, например lofi",
    radio_fig_search_alt: "Поиск радиостанций по тегу lofi",
    radio_fig_mp3: "Список станций — обрати внимание на тег MP3",
    radio_fig_mp3_alt: "Список радиостанций с видимым тегом MP3",
    radio_fig_save: "Кнопка Save в строке станции",
    radio_fig_save_alt: "Кнопка Save для получения ссылки на поток",
    radio_fig_url: "Страница потока — копируй URL из адресной строки",
    radio_fig_url_alt: "Страница MP3-потока с URL в адресной строке браузера",
    radio_end_note: "Если станция не играет, проверь формат (MP3) и что ссылка скопирована полностью из адресной строки после нажатия Save.",
    radio_back_home: "На главную",
    docs_title: "World Machine Player — помощь",
    docs_description: "Помощь по World Machine Player: радио, настройки и ответы на частые вопросы.",
    docs_kicker: "Помощь",
    docs_page_title: "Руководства World Machine Player",
    docs_lead: "Пошаговые инструкции по функциям плеера. Выбери раздел ниже.",
    docs_hub_radio_title: "Радио",
    docs_hub_radio_desc: "Как добавить интернет-радиостанции и найти MP3-потоки на radio-browser.info.",
    docs_hub_settings_title: "Настройки",
    docs_hub_settings_desc: "Папка с музыкой, темы оформления и сохранение параметров плеера.",
    docs_hub_faq_title: "FAQ",
    docs_hub_faq_desc: "Ответы на частые вопросы о форматах, платформе и устранении неполадок.",
    docs_hub_read: "Читать →",
    settings_title: "World Machine Player — настройки",
    settings_description: "Настройки World Machine Player: папка с музыкой, темы и сохранение параметров.",
    settings_kicker: "Помощь",
    settings_page_title: "Настройки",
    settings_lead: "Руководство по настройкам плеера появится здесь.",
    settings_menu_title: "Главное меню и настройки",
    settings_menu_step1: "Для открытия меню нажми на иконку лампочки в правом нижнем углу.",
    settings_menu_step2: "В открывшемся меню доступны кнопки <strong>Settings</strong> (Настройки) и <strong>Theme</strong> (Темы).",
    settings_menu_step3: "В окне настроек можно выбрать папку с музыкой, а в окне тем — изменить внешний вид плеера.",
    settings_fig_sun: "Иконка лампочки для открытия меню",
    settings_fig_sun_alt: "Клик по иконке лампочки в правом нижнем углу",
    settings_fig_menu: "Главное меню с кнопками Settings и Theme",
    settings_fig_menu_alt: "Окно главного меню плеера",
    settings_fig_settings: "Окно настроек плеера",
    settings_fig_settings_alt: "Окно настроек с выбором папки",
    settings_fig_theme: "Окно выбора темы оформления",
    settings_fig_theme_alt: "Окно тем оформления",
    settings_track_kicker: "Плейлисты",
    settings_track_title: "Список песен и плейлисты",
    settings_track_step1: "Для просмотра списка песен и плейлистов нажми на название текущего трека сверху.",
    settings_track_step2: "Откроется панель со всеми найденными треками и возможностью управления плейлистами.",
    settings_fig_title: "Нажатие на название трека",
    settings_fig_title_alt: "Клик по названию текущего трека",
    settings_fig_panel: "Панель списка песен и плейлистов",
    settings_fig_panel_alt: "Открытая панель со списком треков",
    settings_back_help: "К помощи",
    faq_title: "World Machine Player — FAQ",
    faq_description: "Частые вопросы о World Machine Player: форматы, платформа, радио и устранение неполадок.",
    faq_kicker: "Помощь",
    faq_page_title: "Частые вопросы",
    faq_lead: "Ответы на популярные вопросы о плеере появятся здесь.",
    faq_stub_label: "Скоро",
    faq_stub_desc: 'Раздел в разработке. Если возникла проблема — создай issue на <a href="https://github.com/DimaBroZY/World-Machine-Player/issues" target="_blank" rel="noreferrer">GitHub</a>.',
    faq_back_help: "К помощи",
    faq_cat_general: "Общие",
    faq_q_game: "Что за игра?",
    faq_a_game: "OneShot: WME",
    faq_q_download: "Где скачать?",
    faq_a_download: 'Последнюю версию можно скачать на странице <a href="https://github.com/DimaBroZY/World-Machine-Player/releases/latest" target="_blank" rel="noreferrer">GitHub Releases</a>.',
    faq_q_updates: "Как часто будут выходить обновления?",
    faq_a_updates: "Когда не лень xd",
    faq_cat_platforms: "Платформы и совместимость",
    faq_q_win7: "Работает ли на Windows 7 и ниже?",
    faq_a_win7: "Нет, для работы версия Windows должна быть не ниже Windows 10.",
    faq_q_linux: "Будет ли Linux версия?",
    faq_a_linux: "Возможно, если сильно надо.",
    faq_q_android: "Будет ли андроид версия?",
    faq_a_android: "Не планируется.",
    faq_cat_media: "Функции и медиа",
    faq_q_own_music: "Можно слушать свою музыку?",
    faq_a_own_music: 'Да, смотрите <a href="settings.html">гайд по настройкам</a>.',
    faq_q_formats: "Какие форматы аудио поддерживаются?",
    faq_a_formats: "MP3, OGG, FLAC, OPUS.",
    faq_q_streaming: "Будет ли поддержка стриминговых сервисов? (Spotify, SoundCloud, YouTube и т.д.)",
    faq_a_streaming: "Возможно в будущем.",
    faq_q_radio: "Как добавить свое радио?",
    faq_a_radio: 'Смотрите <a href="radio.html">гайд по добавлению радио</a>.',
    lightbox_close: "Закрыть",
  },
  en: {
    title: "World Machine Player - download Jukebox from OneShot WME",
    description: "World Machine Player is a fan-made Godot implementation of the Jukebox from OneShot: World Machine Edition. Direct download, GitHub, bug reports and suggestions.",
    nav_features: "Features",
    nav_help: "Help",
    nav_radio: "Radio",
    nav_home: "Home",
    nav_issues: "Issues",
    nav_download: "Download",
    hero_eyebrow: "Godot fan project for Windows",
    hero_title: "World Machine Player",
    hero_lead: "Fan implementation of the Jukebox from OneShot: World Machine Edition. Play your own music folder, switch tracks, change speed, volume, and theme.",
    btn_download: "Download",
    hero_github: `<span class="button-icon" aria-hidden="true">↗</span>
              GitHub`,
    hero_formats_dt: "Formats",
    hero_platform_dt: "Platform",
    download_kicker: "Latest public release",
    download_title: "Download World Machine Player",
    download_desc: "Direct link points to <code>World.Machine.Player.zip</code> from GitHub Releases. Extract the archive and run <code>WorldMachinePlayer.exe</code>.",
    features_kicker: "Features",
    features_title: "Player for your own music folder",
    feat_playback_title: "Playback",
    feat_playback_desc: "Support for <code>.ogg</code>, <code>.mp3</code>, <code>.flac</code>, and <code>.opus</code> — play local tracks from your folder.",
    feat_playlists_title: "Playlists",
    feat_playlists_desc: "Create playlists and organize tracks into collections — handy for albums, sets, and favorites.",
    feat_radio_title: "Internet Radio",
    feat_radio_desc: 'Add stations by URL — MP3 streams from directories like <code>radio-browser.info</code>. See <a href="docs/radio.html">docs/radio.html</a> for a guide.',
    feat_theme_title: "Customization",
    feat_theme_desc: "Multiple visual themes for player appearance and mood.",
    feat_settings_title: "Settings",
    feat_settings_desc: "You can specify your own music folder. Settings are saved automatically.",
    how_kicker: "Quick Start",
    how_title: "Launch in four steps",
    step_1: "Download the latest version from GitHub Releases.",
    step_2: "Run <code>WorldMachinePlayer.exe</code>.",
    step_3: "Specify your music folder in the settings.",
    step_4: "Put audio files there, the player will scan them automatically.",
    feedback_kicker: "GitHub Issues",
    feedback_title: "Drop bugs and ideas right into the repository",
    feedback_desc: "Issues lead to the same project where the source code is hosted. This way, your report or suggestion won't get lost.",
    bug_span: "Bug",
    bug_strong: "Report an issue",
    idea_span: "Idea",
    idea_strong: "Suggest a feature",
    credits_kicker: "Fan project",
    credits_title: "Made for the OneShot community",
    credits_desc: "World Machine Player is based on OneShot: World Machine Edition. Rights to characters, music, and materials belong to Team OneShot and Future Cat LLC.",
    radio_title: "World Machine Player — how to add radio",
    radio_description: "How to add internet radio to World Machine Player: find stations on radio-browser.info and add MP3 streams.",
    radio_kicker: "Help",
    radio_page_title: "How to add radio stations",
    radio_lead: 'World Machine Player can play internet radio. Add a station by name and stream URL — step-by-step guide for the player and for finding links on <a href="https://www.radio-browser.info/" target="_blank" rel="noreferrer">radio-browser.info</a>.',
    radio_player_kicker: "World Machine Player",
    radio_player_title: "Adding a station in the player",
    radio_player_step1: "Open the <strong>Radio</strong> tab in the player.",
    radio_player_step2: "Click the <strong>[+ADD RADIO]</strong> button.",
    radio_player_step3: "In the dialog, fill in <strong>Name</strong> and <strong>URL</strong> (stream link).",
    radio_player_step4: "Confirm — the station appears in the list and you can select and listen to it.",
    radio_fig_tab: "Radio tab and [+ADD RADIO] button",
    radio_fig_tab_alt: "Radio tab in World Machine Player with add station button",
    radio_fig_dialog: "Add Radio dialog: Name and URL fields",
    radio_fig_dialog_alt: "Add radio station dialog with Name and URL fields",
    radio_fig_list: "Station in the list after adding",
    radio_fig_list_alt: "Added radio station in the World Machine Player list",
    radio_browser_kicker: "radio-browser.info",
    radio_browser_title: "Where to get a radio station URL",
    radio_browser_intro: '<a href="https://www.radio-browser.info/" target="_blank" rel="noreferrer">radio-browser.info</a> is an open internet radio directory. Find a station with an <strong>MP3</strong> stream and copy the direct link.',
    radio_mp3_label: "Important: MP3 only",
    radio_mp3_desc: "World Machine Player supports MP3 radio streams. When choosing a station, look for the <code>MP3</code> tag in the list — AAC, OGG, and other formats may not play.",
    radio_browser_step1: 'Open <a href="https://www.radio-browser.info/" target="_blank" rel="noreferrer">radio-browser.info</a>.',
    radio_browser_step2: "Go to <strong>By category</strong> → <strong>By tag</strong> or use search.",
    radio_browser_step3: "Find a tag you like, e.g. <code>lofi</code>, and open the station list.",
    radio_browser_step4: "Pick a station with the <strong>MP3</strong> tag in the row.",
    radio_browser_step5: "Click the <strong>Save</strong> button on the station row.",
    radio_browser_step6: "The browser opens the stream page — copy the URL from the address bar (e.g. <code>https://usa9.fastcast4u.com/proxy/jamz?mp=/1</code>).",
    radio_browser_step7: "Paste the copied URL into the <strong>URL</strong> field when adding radio in World Machine Player.",
    radio_fig_home: "radio-browser.info homepage",
    radio_fig_home_alt: "radio-browser.info catalog homepage",
    radio_fig_browse: "By category → By tag",
    radio_fig_browse_alt: "By category and By tag navigation on radio-browser.info",
    radio_fig_search: "Tag search, e.g. lofi",
    radio_fig_search_alt: "Searching radio stations by lofi tag",
    radio_fig_mp3: "Station list — note the MP3 tag",
    radio_fig_mp3_alt: "Radio station list with visible MP3 tag",
    radio_fig_save: "Save button on the station row",
    radio_fig_save_alt: "Save button to get the stream link",
    radio_fig_url: "Stream page — copy URL from the address bar",
    radio_fig_url_alt: "MP3 stream page with URL in the browser address bar",
    radio_end_note: "If a station won't play, check the format (MP3) and that the link was copied fully from the address bar after clicking Save.",
    radio_back_home: "Back to home",
    docs_title: "World Machine Player — help",
    docs_description: "World Machine Player help: radio, settings, and frequently asked questions.",
    docs_kicker: "Help",
    docs_page_title: "World Machine Player guides",
    docs_lead: "Step-by-step guides for player features. Pick a section below.",
    docs_hub_radio_title: "Radio",
    docs_hub_radio_desc: "How to add internet radio stations and find MP3 streams on radio-browser.info.",
    docs_hub_settings_title: "Settings",
    docs_hub_settings_desc: "Music folder, visual themes, and saving player preferences.",
    docs_hub_faq_title: "FAQ",
    docs_hub_faq_desc: "Answers about supported formats, platform, and troubleshooting.",
    docs_hub_read: "Read →",
    settings_title: "World Machine Player — settings",
    settings_description: "World Machine Player settings: music folder, themes, and saving preferences.",
    settings_kicker: "Help",
    settings_page_title: "Settings",
    settings_lead: "A settings guide will appear here soon.",
    settings_menu_title: "Main Menu and Settings",
    settings_menu_step1: "To open the menu, click on the lightbulb icon in the bottom right corner.",
    settings_menu_step2: "The menu provides access to <strong>Settings</strong> and <strong>Theme</strong> buttons.",
    settings_menu_step3: "In the settings window you can select your music folder, and in the theme window you can change the player's appearance.",
    settings_fig_sun: "Lightbulb icon to open the menu",
    settings_fig_sun_alt: "Clicking the lightbulb icon in the bottom right corner",
    settings_fig_menu: "Main menu with Settings and Theme buttons",
    settings_fig_menu_alt: "Main menu window of the player",
    settings_fig_settings: "Player settings window",
    settings_fig_settings_alt: "Settings window with folder selection",
    settings_fig_theme: "Theme selection window",
    settings_fig_theme_alt: "Theme selection window",
    settings_track_kicker: "Playlists",
    settings_track_title: "Track List and Playlists",
    settings_track_step1: "To view the list of songs and playlists, click on the current track title at the top.",
    settings_track_step2: "A panel will open showing all found tracks and playlist management options.",
    settings_fig_title: "Clicking on the track title",
    settings_fig_title_alt: "Click on the current track title",
    settings_fig_panel: "Track list and playlists panel",
    settings_fig_panel_alt: "Open panel with the list of tracks",
    settings_back_help: "Back to help",
    faq_title: "World Machine Player — FAQ",
    faq_description: "Frequently asked questions about World Machine Player: formats, platform, radio, and troubleshooting.",
    faq_kicker: "Help",
    faq_page_title: "Frequently asked questions",
    faq_lead: "Answers to common questions about the player will appear here.",
    faq_stub_label: "Coming soon",
    faq_stub_desc: 'This section is in progress. If you run into a problem, open an issue on <a href="https://github.com/DimaBroZY/World-Machine-Player/issues" target="_blank" rel="noreferrer">GitHub</a>.',
    faq_back_help: "Back to help",
    faq_cat_general: "General",
    faq_q_game: "What is this game?",
    faq_a_game: "OneShot: WME",
    faq_q_download: "Where to download?",
    faq_a_download: 'You can download the latest version from <a href="https://github.com/DimaBroZY/World-Machine-Player/releases/latest" target="_blank" rel="noreferrer">GitHub Releases</a>.',
    faq_q_updates: "How often will updates be released?",
    faq_a_updates: "Whenever I feel like it xd",
    faq_cat_platforms: "Platforms & Compatibility",
    faq_q_win7: "Does it work on Windows 7 and below?",
    faq_a_win7: "No, Windows 10 or higher is required.",
    faq_q_linux: "Will there be a Linux version?",
    faq_a_linux: "Maybe, if there's enough demand.",
    faq_q_android: "Will there be an Android version?",
    faq_a_android: "Not planned.",
    faq_cat_media: "Features & Media",
    faq_q_own_music: "Can I listen to my own music?",
    faq_a_own_music: 'Yes, see the <a href="settings.html">settings guide</a>.',
    faq_q_formats: "What audio formats are supported?",
    faq_a_formats: "MP3, OGG, FLAC, OPUS.",
    faq_q_streaming: "Will streaming services be supported? (Spotify, SoundCloud, YouTube, etc.)",
    faq_a_streaming: "Maybe in the future.",
    faq_q_radio: "How do I add my own radio?",
    faq_a_radio: 'See the <a href="radio.html">radio guide</a>.',
    lightbox_close: "Close",
  }
};

const copyButtons = document.querySelectorAll("[data-copy]");

copyButtons.forEach((button) => {
  const originalText = button.textContent;

  button.addEventListener("click", async () => {
    const value = button.dataset.copy;

    try {
      await navigator.clipboard.writeText(value);
      button.textContent = document.documentElement.lang === 'ru' ? "SHA скопирован" : "SHA copied";
    } catch {
      button.textContent = value;
    }

    window.setTimeout(() => {
      button.textContent = originalText;
    }, 2200);
  });
});

// Localization logic
const langSwitch = document.getElementById('lang-switch');

const pageMeta = {
  radio: { title: "radio_title", description: "radio_description" },
  docs: { title: "docs_title", description: "docs_description" },
  settings: { title: "settings_title", description: "settings_description" },
  faq: { title: "faq_title", description: "faq_description" },
};

function setLanguage(lang) {
  document.documentElement.lang = lang;
  const page = document.body.dataset.page;
  const strings = translations[lang];

  if (langSwitch) {
    langSwitch.textContent = lang === "ru" ? "EN" : "RU";
  }

  const meta = pageMeta[page];
  if (meta) {
    document.title = strings[meta.title];
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.content = strings[meta.description];
    const ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.content = strings[meta.title];
    const ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc) ogDesc.content = strings[meta.description];
  } else {
    document.title = strings.title;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.content = strings.description;
    const ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.content = strings.title;
    const ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc) ogDesc.content = strings.description;
  }

  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    if (strings[key]) {
      el.innerHTML = strings[key];
    }
  });

  document.querySelectorAll("[data-i18n-alt]").forEach((el) => {
    const key = el.getAttribute("data-i18n-alt");
    if (strings[key]) {
      el.alt = strings[key];
    }
  });
}

function initLanguage() {
  const savedLang = localStorage.getItem('app_lang');
  if (savedLang) {
    setLanguage(savedLang);
    return;
  }

  // Auto-detect based on system language
  const sysLang = navigator.language || navigator.userLanguage;
  if (sysLang && sysLang.toLowerCase().startsWith('ru')) {
    setLanguage('ru');
  } else {
    setLanguage('en'); // Default to English if not Russian
  }
}

if (langSwitch) {
  langSwitch.addEventListener('click', () => {
    const currentLang = document.documentElement.lang;
    const newLang = currentLang === 'ru' ? 'en' : 'ru';
    localStorage.setItem('app_lang', newLang);
    setLanguage(newLang);
  });
}

initLanguage();

// Docs screenshot lightbox
function initDocsLightbox() {
  const figures = document.querySelectorAll(".docs-figure img");
  if (!figures.length) return;

  const overlay = document.createElement("div");
  overlay.className = "docs-lightbox";
  overlay.hidden = true;
  overlay.setAttribute("role", "dialog");
  overlay.setAttribute("aria-modal", "true");

  const closeBtn = document.createElement("button");
  closeBtn.type = "button";
  closeBtn.className = "docs-lightbox-close";
  closeBtn.setAttribute("aria-label", translations.ru.lightbox_close);

  const lightboxImg = document.createElement("img");
  lightboxImg.className = "docs-lightbox-img";
  lightboxImg.alt = "";

  overlay.append(closeBtn, lightboxImg);
  document.body.appendChild(overlay);

  let lastFocused = null;

  function updateCloseLabel() {
    const lang = document.documentElement.lang === "en" ? "en" : "ru";
    closeBtn.setAttribute("aria-label", translations[lang].lightbox_close);
  }

  function openLightbox(img) {
    lastFocused = document.activeElement;
    lightboxImg.src = img.currentSrc || img.src;
    lightboxImg.alt = img.alt;
    overlay.hidden = false;
    document.body.classList.add("docs-lightbox-open");
    updateCloseLabel();
    closeBtn.focus();
  }

  function closeLightbox() {
    overlay.hidden = true;
    lightboxImg.removeAttribute("src");
    document.body.classList.remove("docs-lightbox-open");
    if (lastFocused && typeof lastFocused.focus === "function") {
      lastFocused.focus();
    }
  }

  figures.forEach((img) => {
    img.classList.add("docs-figure-zoomable");
    img.setAttribute("tabindex", "0");
    img.setAttribute("role", "button");
    img.addEventListener("click", () => openLightbox(img));
    img.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        openLightbox(img);
      }
    });
  });

  closeBtn.addEventListener("click", closeLightbox);
  overlay.addEventListener("click", (event) => {
    if (event.target === overlay) closeLightbox();
  });
  document.addEventListener("keydown", (event) => {
    if (!overlay.hidden && event.key === "Escape") closeLightbox();
  });
}

initDocsLightbox();
