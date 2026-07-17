
const buttons = document.querySelectorAll('[data-set-lang]');
const blocks = document.querySelectorAll('[data-lang]');
function setLang(lang) {
  blocks.forEach(el => el.classList.toggle('active', el.dataset.lang === lang));
  buttons.forEach(btn => btn.classList.toggle('active', btn.dataset.setLang === lang));
  document.documentElement.lang = lang === 'zh' ? 'zh-CN' : lang;
  localStorage.setItem('pomu_lang', lang);
}
const supported = ['ko','en','ja','zh'];
const saved = localStorage.getItem('pomu_lang');
const browser = (navigator.language || 'en').toLowerCase();
let initial = saved || (browser.startsWith('ko') ? 'ko' : browser.startsWith('ja') ? 'ja' : browser.startsWith('zh') ? 'zh' : 'en');
if (!supported.includes(initial)) initial = 'en';
buttons.forEach(btn => btn.addEventListener('click', () => setLang(btn.dataset.setLang)));
setLang(initial);
