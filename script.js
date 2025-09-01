// OSQ HTML Email Preview - GitHub Pages Version
class EmailPreviewApp {
    constructor() {
        this.emails = this.loadEmails();
        this.checkUrlParams();
        this.init();
    }

    init() {
        this.bindEvents();
        this.renderEmailsList();
    }

    checkUrlParams() {
        // Проверяем, нужно ли показать письмо
        const urlParams = new URLSearchParams(window.location.search);
        const emailId = urlParams.get('email');

        if (emailId) {
            this.showEmailPreview(emailId);
        }
    }

    bindEvents() {
        const form = document.getElementById('emailForm');
        if (form) {
            form.addEventListener('submit', (e) => this.handleSubmit(e));
        }
    }

    handleSubmit(e) {
        e.preventDefault();

        const title = document.getElementById('emailTitle').value.trim();
        const html = document.getElementById('htmlCode').value.trim();

        if (!title || !html) {
            alert('Пожалуйста, заполните все поля');
            return;
        }

        const emailId = this.generateId();
        const email = {
            id: emailId,
            title: title,
            html: html,
            createdAt: new Date().toISOString(),
            url: this.generateEmailUrl(emailId, title, html)
        };

        // Сохраняем данные
        this.emails.unshift(email);
        this.saveEmails();

        // Очищаем форму
        document.getElementById('emailTitle').value = '';
        document.getElementById('htmlCode').value = '';

        // Показываем ссылку
        this.showSuccessMessage(email);

        // Обновляем список
        this.renderEmailsList();
    }

    generateEmailUrl(emailId, title, html) {
        // Для GitHub Pages используем viewer.html с URL параметрами
        const encodedTitle = encodeURIComponent(title);
        const encodedHtml = encodeURIComponent(html);
        const baseUrl = window.location.origin + window.location.pathname.replace('index.html', '');
        return `${baseUrl}viewer.html?title=${encodedTitle}&html=${encodedHtml}`;
    }

    generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }

    showEmailPreview(emailId) {
        const email = this.emails.find(e => e.id === emailId);
        if (!email) {
            document.body.innerHTML = '<div style="text-align: center; padding: 50px;"><h1>Письмо не найдено</h1><a href="index.html">Вернуться на главную</a></div>';
            return;
        }

        this.displayEmail(email.html, email.title);
    }

    displayEmail(html, title) {
        // Создаем чистую страницу только с HTML-кодом пользователя
        document.body.innerHTML = `
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    font-family: Arial, sans-serif;
                }
                /* Добавляем базовые стили для корректного отображения email */
                img {
                    max-width: 100%;
                    height: auto;
                }
                table {
                    border-collapse: collapse;
                }
                /* Скрываем любые потенциальные элементы управления */
                .email-preview-controls {
                    display: none !important;
                }
            </style>
            ${html}
        `;

        // Меняем title страницы
        document.title = title;
    }

    showSuccessMessage(email) {
        // Показываем сообщение с ссылкой
        const message = document.createElement('div');
        message.className = 'success-message';
        message.innerHTML = `
            <p>Письмо успешно создано!</p>
            <p><strong>Ссылка для просмотра:</strong></p>
            <p><a href="${email.url}" target="_blank">${email.url}</a></p>
            <div class="message-actions">
                <button onclick="app.copyUrl('${email.url}')" class="btn btn-outline">Копировать ссылку</button>
                <button onclick="this.parentElement.remove()" class="btn btn-danger">Закрыть</button>
            </div>
        `;

        const container = document.querySelector('.create-section') || document.body;
        container.appendChild(message);

        // Автоматически скрываем через 30 секунд
        setTimeout(() => {
            if (message.parentElement) {
                message.remove();
            }
        }, 30000);
    }

    loadEmails() {
        const emails = localStorage.getItem('osq_emails');
        return emails ? JSON.parse(emails) : [];
    }

    saveEmails() {
        localStorage.setItem('osq_emails', JSON.stringify(this.emails));
    }

    renderEmailsList() {
        const container = document.getElementById('emailsContainer');
        if (!container) return;

        if (this.emails.length === 0) {
            container.innerHTML = '<p class="no-emails">Пока нет созданных писем</p>';
            return;
        }

        container.innerHTML = this.emails.map(email => `
            <div class="email-item">
                <h3>${email.title}</h3>
                <p class="email-date">Создано: ${new Date(email.createdAt).toLocaleString('ru-RU')}</p>
                <div class="email-actions">
                    <a href="${email.url}" target="_blank" class="btn btn-secondary">Просмотреть</a>
                    <button onclick="app.copyUrl('${email.url}')" class="btn btn-outline">Копировать ссылку</button>
                    <button onclick="app.deleteEmail('${email.id}')" class="btn btn-danger">Удалить</button>
                </div>
            </div>
        `).join('');
    }

    copyUrl(url) {
        navigator.clipboard.writeText(url).then(() => {
            alert('Ссылка скопирована в буфер обмена!');
        }).catch(() => {
            // Fallback для старых браузеров
            const textArea = document.createElement('textarea');
            textArea.value = url;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            alert('Ссылка скопирована в буфер обмена!');
        });
    }

    deleteEmail(emailId) {
        if (confirm('Вы уверены, что хотите удалить это письмо?')) {
            this.emails = this.emails.filter(email => email.id !== emailId);
            this.saveEmails();
            this.renderEmailsList();
        }
    }
}

// Инициализация приложения
const app = new EmailPreviewApp();
