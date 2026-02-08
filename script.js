/* ============================================
   Sura Portfolio v2.0 - Vertical Scroll JavaScript
   Noise Particles, Category Filtering, Video Modal
   ============================================ */

document.addEventListener('DOMContentLoaded', function() {
    // ============================================
    // Utility Functions
    // ============================================
    // Debounce function for performance
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    // Throttle function for performance
    function throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    // ============================================
    // Noise Particles Background
    // ============================================
    const noiseCanvas = document.getElementById('noiseCanvas');
    if (noiseCanvas) {
        const ctx = noiseCanvas.getContext('2d');
        let particles = [];
        let animationId;
        let mouseX = 0;
        let mouseY = 0;

        function resizeCanvas() {
            noiseCanvas.width = window.innerWidth;
            noiseCanvas.height = window.innerHeight;
            initParticles();
        }

        function initParticles() {
            particles = [];
            const particleCount = Math.floor((noiseCanvas.width * noiseCanvas.height) / 10000);
            
            for (let i = 0; i < particleCount; i++) {
                particles.push({
                    x: Math.random() * noiseCanvas.width,
                    y: Math.random() * noiseCanvas.height,
                    size: Math.random() * 2 + 0.5,
                    speedX: (Math.random() - 0.5) * 0.5,
                    speedY: (Math.random() - 0.5) * 0.5,
                    opacity: Math.random() * 0.3 + 0.1
                });
            }
        }

        function drawNoise() {
            ctx.clearRect(0, 0, noiseCanvas.width, noiseCanvas.height);

            // Draw static noise - optimized with less noise pixels for performance
            const imageData = ctx.createImageData(noiseCanvas.width, noiseCanvas.height);
            const data = imageData.data;

            // Only draw noise every 4 pixels for better performance
            for (let i = 0; i < data.length; i += 16) {
                const value = Math.random() * 20;
                data[i] = value;
                data[i + 1] = value;
                data[i + 2] = value;
                data[i + 3] = 15;
            }
            ctx.putImageData(imageData, 0, 0);

            // Draw floating particles with glow effect
            particles.forEach(particle => {
                ctx.beginPath();
                ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
                ctx.globalAlpha = particle.opacity;
                ctx.shadowColor = 'rgba(183, 69, 70, 0.4)';
                ctx.shadowBlur = 8;
                ctx.fillStyle = 'rgba(183, 69, 70, 0.3)';
                ctx.fill();
            });
            ctx.shadowBlur = 0;
            ctx.shadowColor = 'transparent';
            ctx.globalAlpha = 1;
        }

        function updateParticles() {
            particles.forEach(particle => {
                // Move towards mouse slightly
                const dx = mouseX - particle.x;
                const dy = mouseY - particle.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < 200) {
                    particle.speedX += (dx / distance) * 0.01;
                    particle.speedY += (dy / distance) * 0.01;
                }
                
                // Apply friction
                particle.speedX *= 0.99;
                particle.speedY *= 0.99;
                
                // Update position
                particle.x += particle.speedX;
                particle.y += particle.speedY;
                
                // Bounce off edges
                if (particle.x < 0 || particle.x > noiseCanvas.width) {
                    particle.speedX *= -1;
                }
                if (particle.y < 0 || particle.y > noiseCanvas.height) {
                    particle.speedY *= -1;
                }
            });
        }

        function animateNoise() {
            updateParticles();
            drawNoise();
            animationId = requestAnimationFrame(animateNoise);
        }

        // Track mouse position with throttle for performance
        const updateMousePosition = throttle(function(e) {
            mouseX = e.clientX;
            mouseY = e.clientY;
        }, 50);

        document.addEventListener('mousemove', updateMousePosition, { passive: true });

        // Initialize
        resizeCanvas();
        animateNoise();

        // Handle resize with debounce for performance
        window.addEventListener('resize', debounce(resizeCanvas, 250));
    }

    // ============================================
    // About Modal
    // ============================================
    const aboutBtn = document.getElementById('aboutBtn');
    const aboutBtnHeader = document.getElementById('aboutBtnHeader');
    const aboutModal = document.getElementById('aboutModal');
    const aboutModalClose = document.getElementById('aboutModalClose');
    
    function openAboutModal() {
        if (aboutModal) {
            aboutModal.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }
    
    function closeAboutModal() {
        if (aboutModal) {
            aboutModal.classList.remove('active');
            document.body.style.overflow = '';
            statsAnimated = false; // Allow re-animation on next open
        }
    }
    
    // Support both floating button and header icon
    if (aboutBtn) {
        aboutBtn.addEventListener('click', openAboutModal);
    }
    
    if (aboutBtnHeader) {
        aboutBtnHeader.addEventListener('click', openAboutModal);
    }
    
    if (aboutModalClose) {
        aboutModalClose.addEventListener('click', closeAboutModal);
    }
    
    if (aboutModal) {
        aboutModal.addEventListener('click', function(e) {
            if (e.target === aboutModal) {
                closeAboutModal();
            }
        });
    }
    
    // ============================================
    // Scroll Reveal Animations
    // ============================================
    const revealElements = document.querySelectorAll('.reveal');
    
    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });
    
    revealElements.forEach(el => {
        revealObserver.observe(el);
    });

    // ============================================
    // Sticky Pill Filter Bar — detect when stuck
    // ============================================
    const categoryFilterBar = document.getElementById('categoryFilterBar');
    if (categoryFilterBar) {
        const stickyOffset = 16; // matches CSS top: 1rem
        const handleStickyCheck = throttle(function() {
            const rect = categoryFilterBar.getBoundingClientRect();
            categoryFilterBar.classList.toggle('is-sticky', rect.top <= stickyOffset + 1);
        }, 100);
        window.addEventListener('scroll', handleStickyCheck, { passive: true });
    }

    // ============================================
    // Category Filtering
    // ============================================
    const filterButtons = document.querySelectorAll('.filter-btn');
    const filterOptions = document.querySelectorAll('.filter-option');
    const filterToggle = document.getElementById('filterToggle');
    const filterCurrent = document.querySelector('.filter-current');
    const filterDropdown = document.getElementById('filterDropdown');
    const workGrid = document.querySelector('.work-grid');
    const workItems = Array.from(document.querySelectorAll('.work-item'));
    
    // Store original order of items
    const originalWorkItems = [...workItems];
    
    function getItemCategory(item) {
        return item.dataset.category || '';
    }
    
    function sortWorkItems(category) {
        if (category === 'sound-design') {
            // Custom sort order for Sound Design
            const soundDesignOrder = [
                'Essent',
                'IKEA x Van Gogh',
                'TOTO: Koningawayday',
                'IZ - Big Dreams',
                'Ghetts - Twin Sister',
                'Loredana - Oft Vertaut'
            ];
            
            // Cache titles to avoid repeated DOM queries during sort
            const itemsWithTitles = workItems.map(item => ({
                el: item,
                title: item.querySelector('h3')?.textContent || ''
            }));
            itemsWithTitles.sort((a, b) => {
                const indexA = soundDesignOrder.indexOf(a.title);
                const indexB = soundDesignOrder.indexOf(b.title);
                return (indexA === -1 ? 999 : indexA) - (indexB === -1 ? 999 : indexB);
            });
            const sortedItems = itemsWithTitles.map(i => i.el);
            
            // Re-append items in new order
            sortedItems.forEach(item => workGrid.appendChild(item));
        }
    }
    
    function restoreOriginalOrder() {
        // Restore items to original order
        originalWorkItems.forEach(item => workGrid.appendChild(item));
    }
    
    function updateFilter(category) {
        // Update dropdown toggle text
        if (filterCurrent) {
            const activeOption = document.querySelector(`.filter-option[data-category="${category}"]`);
            if (activeOption) {
                filterCurrent.textContent = activeOption.textContent;
            }
        }
        
        // Update dropdown active state
        filterOptions.forEach(opt => {
            opt.classList.toggle('active', opt.dataset.category === category);
        });
        
        // Update desktop buttons active state
        filterButtons.forEach(btn => {
            btn.classList.toggle('active', btn.dataset.category === category);
        });
        
        // Sort items if needed
        if (category === 'all') {
            restoreOriginalOrder();
        } else if (category === 'sound-design') {
            sortWorkItems(category);
        }
        
        // Filter work items
        const currentItems = Array.from(workGrid.querySelectorAll('.work-item'));
        currentItems.forEach(item => {
            const itemCategory = getItemCategory(item);
            const shouldShow = category === 'all' || itemCategory === category;
            
            if (shouldShow) {
                item.classList.remove('hidden');
            } else {
                item.classList.add('hidden');
            }
        });
        
        // Close dropdown after selection
        if (filterDropdown) {
            filterDropdown.classList.remove('active');
        }

    }

    // Desktop filter buttons
    filterButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            updateFilter(btn.dataset.category);
        });
    });
    
    // Mobile filter dropdown options
    filterOptions.forEach(opt => {
        opt.addEventListener('click', () => {
            updateFilter(opt.dataset.category);
        });
    });
    
    // Filter dropdown toggle
    if (filterToggle && filterDropdown) {
        filterToggle.addEventListener('click', (e) => {
            e.stopPropagation();
            filterDropdown.classList.toggle('active');
        });
        
        // Close dropdown when clicking outside
        document.addEventListener('click', (e) => {
            if (!filterDropdown.contains(e.target)) {
                filterDropdown.classList.remove('active');
            }
        });
    }

    // ============================================
    // Project Detail Modal (with navigation)
    // ============================================
    const projectModal = document.getElementById('projectModal');
    const projectModalClose = document.getElementById('projectModalClose');
    const projectModalPrev = document.getElementById('projectModalPrev');
    const projectModalNext = document.getElementById('projectModalNext');
    const projectVideoEmbed = document.getElementById('projectVideoEmbed');
    const projectModalContent = document.querySelector('.project-modal-content');
    const projectTitle = document.querySelector('.project-title');
    const projectClient = document.querySelector('.project-client .meta-value');
    const projectDirector = document.querySelector('.project-director .meta-value');
    const projectSoundDesign = document.querySelector('.project-sound-design .meta-value');
    const projectContribution = document.querySelector('.project-contribution .meta-value');
    const projectDescription = document.querySelector('.project-description');

    let currentProjectIndex = 0;

    // Get currently visible (non-hidden) work items
    function getVisibleWorkItems() {
        return Array.from(document.querySelectorAll('.work-item:not(.hidden)'));
    }

    // Convert a URL to an embeddable format
    function convertToEmbedUrl(url) {
        if (!url) return '';
        // Clean trailing slashes
        url = url.replace(/\/+$/, '');

        // YouTube: youtube.com/watch?v=ID or youtu.be/ID
        const ytMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([\w-]+)/);
        if (ytMatch) {
            let embedUrl = 'https://www.youtube.com/embed/' + ytMatch[1];
            // Preserve timestamp if present (e.g. &t=30)
            const tMatch = url.match(/[?&]t=(\d+)/);
            if (tMatch) {
                embedUrl += '?start=' + tMatch[1];
            }
            return embedUrl;
        }

        // Vimeo: vimeo.com/ID
        const vimeoMatch = url.match(/vimeo\.com\/(\d+)/);
        if (vimeoMatch) {
            return 'https://player.vimeo.com/video/' + vimeoMatch[1];
        }

        // Spotify: open.spotify.com/album/ID or /artist/ID or /track/ID
        const spotifyMatch = url.match(/open\.spotify\.com\/(album|artist|track)\/([\w]+)/);
        if (spotifyMatch) {
            return 'https://open.spotify.com/embed/' + spotifyMatch[1] + '/' + spotifyMatch[2];
        }

        return url;
    }

    // Populate modal from a work-item element
    function populateProjectModal(item) {
        const title = item.dataset.title || '';
        const client = item.dataset.client || '';
        const director = item.dataset.director || '';
        const soundDesign = item.dataset.soundDesign || '';
        const contribution = item.dataset.contribution || '';
        const description = item.dataset.description || '';
        const url = item.dataset.url || '';

        if (projectTitle) projectTitle.textContent = title;
        if (projectClient) projectClient.textContent = client;
        if (projectDirector) {
            if (director) {
                projectDirector.textContent = director;
                projectDirector.parentElement.style.display = 'contents';
            } else {
                projectDirector.parentElement.style.display = 'none';
            }
        }
        if (projectSoundDesign) {
            if (soundDesign) {
                projectSoundDesign.textContent = soundDesign;
                projectSoundDesign.parentElement.style.display = 'contents';
            } else {
                projectSoundDesign.parentElement.style.display = 'none';
            }
        }
        if (projectContribution) projectContribution.textContent = contribution;
        if (projectDescription) projectDescription.textContent = description;

        // Clear old video first, then set new with slight delay to force browser reload
        if (projectVideoEmbed) {
            projectVideoEmbed.src = 'about:blank';
            if (url) {
                setTimeout(function() {
                    projectVideoEmbed.src = convertToEmbedUrl(url);
                }, 50);
            }
        }
    }

    // Navigate to next/previous project with fade transition
    function navigateProject(direction) {
        const visibleItems = getVisibleWorkItems();
        if (visibleItems.length <= 1) return;

        // Fade out
        if (projectModalContent) {
            projectModalContent.classList.add('navigating');
        }

        setTimeout(function() {
            // Calculate new index (wrapping)
            currentProjectIndex = (currentProjectIndex + direction + visibleItems.length) % visibleItems.length;

            // Populate with new item
            populateProjectModal(visibleItems[currentProjectIndex]);

            // Fade in
            if (projectModalContent) {
                projectModalContent.classList.remove('navigating');
            }
        }, 200);
    }

    // Open project modal on work item click
    workItems.forEach(item => {
        item.addEventListener('click', function(e) {
            // Determine index within currently visible items
            const visibleItems = getVisibleWorkItems();
            currentProjectIndex = visibleItems.indexOf(this);
            if (currentProjectIndex === -1) currentProjectIndex = 0;

            populateProjectModal(this);

            // Open modal
            if (projectModal) {
                projectModal.classList.add('active');
                document.body.style.overflow = 'hidden';
            }
        });
    });

    // Nav button click handlers
    if (projectModalPrev) {
        projectModalPrev.addEventListener('click', function(e) {
            e.stopPropagation();
            navigateProject(-1);
        });
    }
    if (projectModalNext) {
        projectModalNext.addEventListener('click', function(e) {
            e.stopPropagation();
            navigateProject(1);
        });
    }

    // Close project modal
    function closeProjectModal() {
        if (projectModal) {
            projectModal.classList.remove('active');
            if (projectVideoEmbed) projectVideoEmbed.src = '';
            document.body.style.overflow = '';
        }
    }

    if (projectModalClose) {
        projectModalClose.addEventListener('click', closeProjectModal);
    }

    if (projectModal) {
        projectModal.addEventListener('click', function(e) {
            if (e.target === projectModal) {
                closeProjectModal();
            }
        });
    }

    // Consolidated keyboard handler for all modals
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            if (projectModal && projectModal.classList.contains('active')) {
                closeProjectModal();
            } else if (aboutModal && aboutModal.classList.contains('active')) {
                closeAboutModal();
            }
        }
        if (projectModal && projectModal.classList.contains('active')) {
            if (e.key === 'ArrowLeft') {
                e.preventDefault();
                navigateProject(-1);
            } else if (e.key === 'ArrowRight') {
                e.preventDefault();
                navigateProject(1);
            }
        }
    });

    // ============================================
    // Play Button Delegation (triggers project modal)
    // ============================================
    document.querySelectorAll('.play-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            const workItem = this.closest('.work-item');
            if (workItem) {
                workItem.click();
            }
        });
    });

    // ============================================
    // Stats Counter Animation
    // ============================================
    const statNumbers = document.querySelectorAll('.about-modal .stat-number');
    let statsAnimated = false;
    
    function animateStats() {
        if (statsAnimated || !statNumbers.length) return;
        
        const modal = document.querySelector('.about-modal');
        if (!modal) return;
        
        const rect = modal.getBoundingClientRect();
        if (rect.top < window.innerHeight && rect.bottom > 0) {
            statsAnimated = true;
            
            statNumbers.forEach(stat => {
                const target = stat.textContent;
                const numericValue = parseInt(target.replace(/\D/g, ''));
                const suffix = target.replace(/[0-9]/g, '');
                let current = 0;
                const increment = numericValue / 50;
                const duration = 2000;
                const stepTime = duration / 50;
                
                const counter = setInterval(() => {
                    current += increment;
                    if (current >= numericValue) {
                        stat.textContent = target;
                        clearInterval(counter);
                    } else {
                        stat.textContent = Math.floor(current) + suffix;
                    }
                }, stepTime);
            });
        }
    }
    
    // Observe modal for animation
    if (aboutModal) {
        const modalObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    setTimeout(animateStats, 300);
                }
            });
        }, { threshold: 0.3 });
        
        modalObserver.observe(aboutModal);
    }

});
