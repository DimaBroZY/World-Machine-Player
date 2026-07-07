const translations = {
  ru: {
    title: "World Machine Player - скачать Jukebox из OneShot WME",
    description: "World Machine Player - фанатская реализация Jukebox из OneShot: World Machine Edition на Godot. Прямое скачивание, GitHub, баг-репорты и предложения.",
    nav_features: "Возможности",
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
    feat_playback_desc: "Поддержка <code>.ogg</code>, <code>.mp3</code>, <code>.flac</code> и <code>.opus</code>, переключение треков вперед/назад, play, pause, stop и restart.",
    feat_audio_title: "Аудио контроль",
    feat_audio_desc: "Точная громкость, изменение скорости от 50% до 150% и автоматическое зацикливание трека.",
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
  },
  en: {
    title: "World Machine Player - download Jukebox from OneShot WME",
    description: "World Machine Player is a fan-made Godot implementation of the Jukebox from OneShot: World Machine Edition. Direct download, GitHub, bug reports and suggestions.",
    nav_features: "Features",
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
    feat_playback_desc: "Support for <code>.ogg</code>, <code>.mp3</code>, <code>.flac</code>, and <code>.opus</code>, track switching forward/backward, play, pause, stop, and restart.",
    feat_audio_title: "Audio Control",
    feat_audio_desc: "Precise volume, speed adjustment from 50% to 150%, and automatic track looping.",
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

function setLanguage(lang) {
  document.documentElement.lang = lang;
  
  // Update button text to the other language
  if (langSwitch) {
    langSwitch.textContent = lang === 'ru' ? 'EN' : 'RU';
  }

  // Update meta tags and title
  document.title = translations[lang].title;
  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc) metaDesc.content = translations[lang].description;
  const ogTitle = document.querySelector('meta[property="og:title"]');
  if (ogTitle) ogTitle.content = translations[lang].title;
  const ogDesc = document.querySelector('meta[property="og:description"]');
  if (ogDesc) ogDesc.content = translations[lang].description;

  // Update all elements with data-i18n
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    if (translations[lang][key]) {
      el.innerHTML = translations[lang][key];
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
