const supportedLanguages = ['ko', 'en', 'ja', 'zh'];

function getInitialLanguage() {
  const params = new URLSearchParams(window.location.search);
  const queryLanguage = params.get('lang');

  if (queryLanguage && supportedLanguages.includes(queryLanguage)) {
    return queryLanguage;
  }

  const savedLanguage = localStorage.getItem('pomu-language');

  if (savedLanguage && supportedLanguages.includes(savedLanguage)) {
    return savedLanguage;
  }

  const browserLanguage = navigator.language.toLowerCase();

  if (browserLanguage.startsWith('ko')) return 'ko';
  if (browserLanguage.startsWith('ja')) return 'ja';
  if (browserLanguage.startsWith('zh')) return 'zh';

  return 'en';
}

function applyLanguage(language) {
  const safeLanguage = supportedLanguages.includes(language)
    ? language
    : 'en';

  document.documentElement.lang = safeLanguage;

  document.querySelectorAll('[data-lang]').forEach((element) => {
    element.hidden = element.dataset.lang !== safeLanguage;
  });

  document.querySelectorAll('[data-set-lang]').forEach((button) => {
    const isActive = button.dataset.setLang === safeLanguage;

    button.classList.toggle('active', isActive);
    button.setAttribute('aria-pressed', String(isActive));
  });

  localStorage.setItem('pomu-language', safeLanguage);
}

document.addEventListener('DOMContentLoaded', () => {
  applyLanguage(getInitialLanguage());

  document.querySelectorAll('[data-set-lang]').forEach((button) => {
    button.addEventListener('click', () => {
      const language = button.dataset.setLang;

      if (!supportedLanguages.includes(language)) return;

      applyLanguage(language);

      const url = new URL(window.location.href);
      url.searchParams.set('lang', language);
      window.history.replaceState({}, '', url);
    });
  });
});
