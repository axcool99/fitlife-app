// Navbar scroll effect
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Smooth scroll for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Add fade-in animation to elements
document.querySelectorAll('.feature-card, .benefit-item, .section-header').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
});

// Animate stats on scroll
const animateValue = (element, start, end, duration) => {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        const value = Math.floor(progress * (end - start) + start);

        if (element.dataset.suffix === 'K+') {
            element.textContent = value + 'K+';
        } else if (element.dataset.suffix === 'M+') {
            element.textContent = value + 'M+';
        } else if (element.dataset.suffix === '.') {
            element.textContent = (value / 10).toFixed(1);
        } else {
            element.textContent = value;
        }

        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
};

// Stats animation observer
const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const statNumber = entry.target;
            const text = statNumber.textContent;

            if (text.includes('K+')) {
                statNumber.dataset.suffix = 'K+';
                const value = parseInt(text.replace('K+', ''));
                animateValue(statNumber, 0, value, 2000);
            } else if (text.includes('M+')) {
                statNumber.dataset.suffix = 'M+';
                const value = parseInt(text.replace('M+', ''));
                animateValue(statNumber, 0, value, 2000);
            } else if (text.includes('.')) {
                statNumber.dataset.suffix = '.';
                const value = parseFloat(text) * 10;
                animateValue(statNumber, 0, value, 2000);
            }

            statsObserver.unobserve(entry.target);
        }
    });
}, { threshold: 0.5 });

document.querySelectorAll('.stat-number').forEach(stat => {
    statsObserver.observe(stat);
});

// CTA button clicks
document.querySelectorAll('.btn-primary, .nav-cta').forEach(button => {
    button.addEventListener('click', (e) => {
        if (!button.closest('a')) {
            e.preventDefault();
            document.querySelector('#download').scrollIntoView({ behavior: 'smooth' });
        }
    });
});

// Store button hover effects
document.querySelectorAll('.store-button').forEach(button => {
    button.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-4px) scale(1.02)';
    });

    button.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0) scale(1)';
    });
});

// Feature card interaction
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mouseenter', function() {
        this.style.borderColor = 'rgba(0, 255, 133, 0.5)';
    });

    card.addEventListener('mouseleave', function() {
        this.style.borderColor = 'rgba(255, 255, 255, 0.05)';
    });
});

// Bar chart animation on scroll
const chartObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const bars = entry.target.querySelectorAll('.bar');
            bars.forEach((bar, index) => {
                setTimeout(() => {
                    bar.style.animation = `growBar 0.8s ease-out forwards`;
                }, index * 100);
            });
            chartObserver.unobserve(entry.target);
        }
    });
}, { threshold: 0.3 });

const chartContainer = document.querySelector('.bar-chart');
if (chartContainer) {
    chartObserver.observe(chartContainer);
}

// Add parallax effect to hero
let lastScrollY = window.scrollY;

window.addEventListener('scroll', () => {
    const scrollY = window.scrollY;
    const hero = document.querySelector('.hero');

    if (hero && scrollY < window.innerHeight) {
        hero.style.transform = `translateY(${scrollY * 0.5}px)`;
        hero.style.opacity = 1 - (scrollY / window.innerHeight);
    }

    lastScrollY = scrollY;
});

// Mobile menu toggle (for future implementation)
const createMobileMenu = () => {
    const navLinks = document.querySelector('.nav-links');
    const menuButton = document.createElement('button');
    menuButton.classList.add('mobile-menu-button');
    menuButton.innerHTML = '☰';
    menuButton.style.cssText = `
        display: none;
        background: none;
        border: none;
        color: white;
        font-size: 24px;
        cursor: pointer;
    `;

    if (window.innerWidth <= 968) {
        menuButton.style.display = 'block';
        document.querySelector('.nav-content').insertBefore(
            menuButton,
            document.querySelector('.nav-cta')
        );
    }
};

// Initialize on load
window.addEventListener('load', () => {
    createMobileMenu();
});

// Resize handler
window.addEventListener('resize', () => {
    createMobileMenu();
});
