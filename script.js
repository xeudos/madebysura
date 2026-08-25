/* Made by Sura — Studio Ledger interactions */

document.addEventListener('DOMContentLoaded', function() {
    // ============================================
    // Utility Functions
    // ============================================
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

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    const previewIframe = document.querySelector('[data-autoplay-preview]');
    if (previewIframe && !prefersReducedMotion) {
        const loadPreview = () => {
            if (!previewIframe.hasAttribute('src')) previewIframe.src = previewIframe.dataset.src;
        };
        const unloadPreview = () => {
            if (!previewIframe.hasAttribute('src')) return;
            previewIframe.src = 'about:blank';
            previewIframe.removeAttribute('src');
        };

        if ('IntersectionObserver' in window) {
            const previewObserver = new IntersectionObserver(entries => {
                entries.forEach(entry => entry.isIntersecting ? loadPreview() : unloadPreview());
            }, { threshold: .25 });
            previewObserver.observe(previewIframe.closest('.selected-work-card'));
        } else {
            loadPreview();
        }
    }

    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', event => {
            const href = link.getAttribute('href');
            if (!href || href === '#') return;

            const target = document.querySelector(href);
            if (!target) return;

            event.preventDefault();
            target.scrollIntoView({
                behavior: prefersReducedMotion ? 'auto' : 'smooth',
                block: 'start'
            });
        });
    });
    
    // ============================================
    // Scroll Reveal Animations
    // ============================================
    const revealElements = document.querySelectorAll('.reveal');
    
    if (prefersReducedMotion || !('IntersectionObserver' in window)) {
        revealElements.forEach(el => el.classList.add('visible'));
    } else {
        const revealObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                    revealObserver.unobserve(entry.target);
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        revealElements.forEach(el => revealObserver.observe(el));
    }

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
    
    function getItemCategories(item) {
        return [item.dataset.category, item.dataset.categorySecondary].filter(Boolean);
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
        if (category === 'all' || category === 'commercials' || category === 'produced' || category === 'audio-cleanup') {
            restoreOriginalOrder();
        } else if (category === 'sound-design') {
            sortWorkItems(category);
        }
        
        // Filter work items
        const currentItems = Array.from(workGrid.querySelectorAll('.work-item'));
        currentItems.forEach(item => {
            const categories = getItemCategories(item);
            const shouldShow = category === 'all' || categories.includes(category);
            
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
    const projectModalVideo = document.querySelector('.project-modal-video');
    const projectModalContent = document.querySelector('.project-modal-content');
    const projectTitle = document.querySelector('.project-title');
    const projectClient = document.querySelector('.project-client .meta-value');
    const projectDirector = document.querySelector('.project-director .meta-value');
    const projectSoundDesign = document.querySelector('.project-sound-design .meta-value');
    const projectContribution = document.querySelector('.project-contribution .meta-value');
    const projectDescription = document.querySelector('.project-description');
    const projectExternal = document.getElementById('projectExternal');

    let currentProjectIndex = 0;

    const featuredModalOrder = [
        'ING: Money Laundering',
        'Zo veel Rotterdam',
        'Bruut Showreel 2025'
    ];

    // Keep the opening modal sequence aligned with the homepage hierarchy,
    // while preserving the grid order for every other visible project.
    function getVisibleWorkItems() {
        const visibleItems = Array.from(document.querySelectorAll('.work-item:not(.hidden)'));
        const featuredItems = visibleItems
            .filter(item => featuredModalOrder.indexOf(item.dataset.title) !== -1)
            .sort((a, b) => featuredModalOrder.indexOf(a.dataset.title) - featuredModalOrder.indexOf(b.dataset.title));
        const remainingItems = visibleItems.filter(item => featuredModalOrder.indexOf(item.dataset.title) === -1);
        return [...featuredItems, ...remainingItems];
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

        // Spotify: open.spotify.com/album/ID, /artist/ID, /track/ID or /episode/ID
        const spotifyMatch = url.match(/open\.spotify\.com\/(album|artist|track|episode)\/([\w]+)/);
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
        const embedType = item.dataset.embedType || '';
        const externalLabel = item.dataset.externalLabel || '';

        function setMetaValue(element, value) {
            if (!element) return;
            const metaRow = element.closest('p');
            element.textContent = value || '';
            if (metaRow) metaRow.hidden = !value;
        }

        if (projectTitle) projectTitle.textContent = title;
        setMetaValue(projectClient, client);
        setMetaValue(projectDirector, director);
        setMetaValue(projectSoundDesign, soundDesign);
        setMetaValue(projectContribution, contribution);
        if (projectDescription) projectDescription.textContent = description;
        if (projectModalVideo) {
            projectModalVideo.classList.toggle('spotify-episode', embedType === 'spotify-episode');
        }
        if (projectExternal) {
            projectExternal.hidden = !externalLabel || !url;
            projectExternal.href = url || '#';
            projectExternal.textContent = externalLabel;
        }
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
        item.addEventListener('keydown', function(e) {
            if (e.key !== 'Enter' && e.key !== ' ') return;
            e.preventDefault();
            e.stopPropagation();
            this.click();
        });
    });

    // Reuse the matching portfolio item so featured projects open in the same
    // on-site video modal, with one source of truth for project metadata.
    document.querySelectorAll('.selected-project-trigger').forEach(trigger => {
        trigger.addEventListener('click', event => {
            event.preventDefault();
            const featuredCard = trigger.closest('.selected-work-card');
            const projectTitleToOpen = featuredCard?.dataset.projectTitle;
            const matchingProject = workItems.find(item => item.dataset.title === projectTitleToOpen);

            if (matchingProject) matchingProject.click();
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
                if (projectModalVideo) projectModalVideo.classList.remove('spotify-episode');
                if (projectExternal) {
                    projectExternal.hidden = true;
                    projectExternal.href = '#';
                    projectExternal.textContent = '';
                }
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
    // Audio Player v2.0 - Mufaro EP Player
    // ============================================
    const audioPlayer = {
        audio: null,
        tracks: [],
        currentTrackIndex: 0,
        isPlaying: false,
        albumCircle: null,

        init() {
            this.audio = document.getElementById('releaseAudio');
            this.albumCircle = document.getElementById('albumCircle');

            const tracklist = document.getElementById('releaseTracklist');
            if (tracklist) {
                this.tracks = Array.from(tracklist.querySelectorAll('.track'));
            }

            if (!this.audio || !this.tracks.length) {
                console.warn('Audio player elements not found');
                return;
            }

            this.loadTrack(0);

            this.bindEvents();
            this.updatePlayIcon();
        },

        bindEvents() {
            this.tracks.forEach((track, index) => {
                track.addEventListener('click', (e) => {
                    if (e.target.closest('.track-play-btn')) {
                        e.preventDefault();
                        this.togglePlay();
                    } else if (index === this.currentTrackIndex) {
                        this.togglePlay();
                    } else {
                        this.selectTrack(index);
                    }
                });
            });

            this.audio.addEventListener('play', () => this.onPlay());
            this.audio.addEventListener('pause', () => this.onPause());
            this.audio.addEventListener('ended', () => this.onEnded());
            this.audio.addEventListener('error', (e) => this.onError(e));

            document.addEventListener('keydown', (e) => {
                if (e.code === 'Space' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
                    const anyModalActive = document.querySelector('.project-modal-overlay.active');
                    if (!anyModalActive) {
                        e.preventDefault();
                        this.togglePlay();
                    }
                }
            });
        },

        loadTrack(index) {
            if (index < 0) index = this.tracks.length - 1;
            if (index >= this.tracks.length) index = 0;
            this.currentTrackIndex = index;

            const track = this.tracks[this.currentTrackIndex];
            if (!track) return;

            const src = track.dataset.src;
            this.audio.src = src;
            this.audio.load();

            this.tracks.forEach((t, i) => {
                t.classList.toggle('active', i === this.currentTrackIndex);
                t.classList.remove('playing');
            });

        },

        togglePlay() {
            if (!this.audio.src || this.audio.src === window.location.href) {
                this.loadTrack(this.currentTrackIndex);
            }

            if (this.isPlaying) {
                this.audio.pause();
            } else {
                this.audio.play().catch(err => {
                    console.warn('Play failed:', err);
                });
            }
        },

        playNext() {
            this.loadTrack((this.currentTrackIndex + 1) % this.tracks.length);
            if (this.isPlaying) {
                this.audio.play().catch(() => {});
            }
        },

        playPrev() {
            this.loadTrack((this.currentTrackIndex - 1 + this.tracks.length) % this.tracks.length);
            if (this.isPlaying) {
                this.audio.play().catch(() => {});
            }
        },

        selectTrack(index) {
            const wasPlaying = this.isPlaying;
            if (this.currentTrackIndex !== index) {
                this.loadTrack(index);
            }
            if (!wasPlaying || this.currentTrackIndex === index) {
                this.audio.play().catch(() => {});
            }
        },

        onPlay() {
            this.isPlaying = true;
            this.updatePlayIcon();
            if (this.albumCircle) {
                this.albumCircle.classList.add('playing');
                this.albumCircle.classList.remove('paused');
            }
        },

        onPause() {
            this.isPlaying = false;
            this.updatePlayIcon();
            if (this.albumCircle) {
                this.albumCircle.classList.remove('playing');
                this.albumCircle.classList.add('paused');
            }
        },

        onEnded() {
            this.playNext();
        },

        onError(e) {
            console.warn('Audio error:', e);
            this.isPlaying = false;
            this.updatePlayIcon();
            if (this.albumCircle) {
                this.albumCircle.classList.remove('playing');
            }
        },

        updatePlayIcon() {
            if (this.isPlaying) {
                this.tracks.forEach((track, i) => {
                    track.classList.toggle('playing', i === this.currentTrackIndex);
                });
            } else {
                this.tracks.forEach(track => track.classList.remove('playing'));
            }
        }
    };

    audioPlayer.init();

});
