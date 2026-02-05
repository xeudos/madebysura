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

            // Draw floating particles with optimized rendering
            ctx.fillStyle = 'rgba(183, 69, 70, 0.2)';
            particles.forEach(particle => {
                ctx.beginPath();
                ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
                ctx.globalAlpha = particle.opacity;
                ctx.fill();
            });
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
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && aboutModal && aboutModal.classList.contains('active')) {
            closeAboutModal();
        }
    });

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
    // Scroll Effect for Filter Bar
    // ============================================
    const categoryFilter = document.querySelector('.category-filter');

    if (categoryFilter) {
        const handleScroll = throttle(function() {
            if (window.scrollY > 50) {
                categoryFilter.classList.add('scrolled');
            } else {
                categoryFilter.classList.remove('scrolled');
            }
        }, 100);

        window.addEventListener('scroll', handleScroll, { passive: true });
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
            
            const sortedItems = [...workItems].sort((a, b) => {
                const titleA = a.querySelector('h3').textContent;
                const titleB = b.querySelector('h3').textContent;
                const indexA = soundDesignOrder.indexOf(titleA);
                const indexB = soundDesignOrder.indexOf(titleB);
                return (indexA === -1 ? 999 : indexA) - (indexB === -1 ? 999 : indexB);
            });
            
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
    // Project Detail Modal
    // ============================================
    const projectModal = document.getElementById('projectModal');
    const projectModalClose = document.getElementById('projectModalClose');
    const projectVideoEmbed = document.getElementById('projectVideoEmbed');
    const projectTitle = document.querySelector('.project-title');
    const projectClient = document.querySelector('.project-client .meta-value');
    const projectDirector = document.querySelector('.project-director .meta-value');
    const projectSoundDesign = document.querySelector('.project-sound-design .meta-value');
    const projectContribution = document.querySelector('.project-contribution .meta-value');
    const projectDescription = document.querySelector('.project-description');
    
    // Open project modal on work item click
    document.querySelectorAll('.work-item').forEach(item => {
        item.addEventListener('click', function(e) {
            const title = this.dataset.title || '';
            const client = this.dataset.client || '';
            const director = this.dataset.director || '';
            const soundDesign = this.dataset.soundDesign || '';
            const contribution = this.dataset.contribution || '';
            const description = this.dataset.description || '';
            const url = this.dataset.url || '';
            
            // Update modal content
            if (projectTitle) projectTitle.textContent = title;
            if (projectClient) projectClient.textContent = client;
            if (projectDirector) {
                if (director) {
                    projectDirector.textContent = director;
                    projectDirector.parentElement.style.display = 'block';
                } else {
                    projectDirector.parentElement.style.display = 'none';
                }
            }
            if (projectSoundDesign) {
                if (soundDesign) {
                    projectSoundDesign.textContent = soundDesign;
                    projectSoundDesign.parentElement.style.display = 'block';
                } else {
                    projectSoundDesign.parentElement.style.display = 'none';
                }
            }
            if (projectContribution) projectContribution.textContent = contribution;
            if (projectDescription) projectDescription.textContent = description;
            
            // Set video embed
            if (projectVideoEmbed && url) {
                const embedUrl = convertToEmbedUrl(url);
                projectVideoEmbed.src = embedUrl;
            }
            
            // Open modal
            if (projectModal) {
                projectModal.classList.add('active');
                document.body.style.overflow = 'hidden';
            }
        });
    });
    
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
    
    // Escape key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && projectModal && projectModal.classList.contains('active')) {
            closeProjectModal();
        }
    });

    // ============================================
    // Video Modal
    // ============================================
    const videoModal = document.getElementById('videoModal');
    const videoEmbed = document.getElementById('videoEmbed');
    const videoModalClose = document.getElementById('videoModalClose');
    const videoErrorFallback = document.getElementById('videoErrorFallback');
    const errorRetryBtn = document.getElementById('errorRetryBtn');
    const errorDirectLink = document.getElementById('errorDirectLink');
    
    let currentVideoUrl = '';
    let retryCount = 0;
    const MAX_RETRIES = 3;
    
    // Convert URL to embed URL
    function convertToEmbedUrl(url) {
        // YouTube
        if (url.includes('youtube.com') || url.includes('youtu.be')) {
            let videoId = '';
            if (url.includes('youtu.be')) {
                videoId = url.split('/').pop();
            } else {
                const urlObj = new URL(url);
                videoId = urlObj.searchParams.get('v') || url.split('v=')[1]?.split('&')[0] || '';
            }
            const timestamp = url.includes('t=') ? url.split('t=')[1].split('&')[0] : '';
            return `https://www.youtube.com/embed/${videoId}${timestamp ? '?start=' + timestamp : ''}?rel=0&modestbranding=1`;
        }
        // Vimeo
        if (url.includes('vimeo.com')) {
            const videoId = url.split('/').pop();
            return `https://player.vimeo.com/video/${videoId}`;
        }
        // Spotify
        if (url.includes('spotify.com')) {
            return url.replace('open.spotify.com/', 'open.spotify.com/embed/');
        }
        // Bandcamp
        if (url.includes('bandcamp.com')) {
            // If it's already an EmbeddedPlayer URL, return as-is
            if (url.includes('EmbeddedPlayer')) {
                return url;
            }
            // Otherwise try to convert regular Bandcamp URLs
            return url.replace('album/', 'embed/album/');
        }
        return url;
    }
    
    // Show error fallback
    function showErrorFallback(url) {
        if (videoEmbed && videoErrorFallback) {
            videoEmbed.style.display = 'none';
            videoErrorFallback.style.display = 'flex';
            
            // Set direct link
            if (errorDirectLink) {
                errorDirectLink.href = url;
            }
        }
    }
    
    // Hide error fallback
    function hideErrorFallback() {
        if (videoEmbed && videoErrorFallback) {
            videoEmbed.style.display = 'block';
            videoErrorFallback.style.display = 'none';
        }
    }
    
    // Retry loading video
    function retryYouTubeEmbed() {
        if (retryCount >= MAX_RETRIES) {
            console.log('Max retries reached for video');
            return;
        }
        
        retryCount++;
        console.log(`Retrying video load (attempt ${retryCount}/${MAX_RETRIES})`);
        
        if (videoEmbed && currentVideoUrl) {
            // Clear src and add timestamp to force reload
            videoEmbed.src = '';
            setTimeout(() => {
                const embedUrl = convertToEmbedUrl(currentVideoUrl);
                videoEmbed.src = embedUrl;
            }, 500);
        }
    }
    
    // Handle YouTube iframe error
    function handleVideoError() {
        console.log('Video error detected, showing fallback');
        showErrorFallback(currentVideoUrl);
        
        // Auto-retry after 2 seconds if YouTube
        if (currentVideoUrl.includes('youtube') || currentVideoUrl.includes('youtu.be')) {
            setTimeout(() => {
                if (videoErrorFallback && videoErrorFallback.style.display !== 'none') {
                    console.log('Auto-retrying video after error');
                    hideErrorFallback();
                    retryYouTubeEmbed();
                }
            }, 2000);
        }
    }
    
    // Open project modal on play button click
    document.querySelectorAll('.play-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            // Find parent work-item and trigger its click handler
            const workItem = this.closest('.work-item');
            if (workItem) {
                workItem.click();
            }
        });
    });
    
    // Retry button click
    if (errorRetryBtn) {
        errorRetryBtn.addEventListener('click', function(e) {
            e.preventDefault();
            hideErrorFallback();
            retryYouTubeEmbed();
        });
    }
    
    // Close modal
    function closeModal() {
        if (videoModal && videoEmbed) {
            videoModal.classList.remove('active');
            videoEmbed.src = '';
            hideErrorFallback();
            document.body.style.overflow = '';
            currentVideoUrl = '';
            retryCount = 0;
        }
    }
    
    if (videoModalClose) {
        videoModalClose.addEventListener('click', closeModal);
    }
    
    if (videoModal) {
        videoModal.addEventListener('click', function(e) {
            if (e.target === videoModal) {
                closeModal();
            }
        });
    }
    
    // Escape key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeModal();
        }
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
        
        modalObserver.observe(document.querySelector('.about-modal'));
    }
});
