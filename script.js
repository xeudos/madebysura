/* ============================================
   Sura Portfolio v2.0 - Vertical Scroll JavaScript
   Noise Particles, Category Filtering, Video Modal
   ============================================ */

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

    // ============================================
    // About Modal
    // ============================================
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
        if (category === 'all' || category === 'commercials' || category === 'produced' || category === 'audio-cleanup') {
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
    // Audio Player v2.0 - Mufaro EP Player
    // ============================================
    const audioPlayer = {
        audio: null,
        playBtn: null,
        prevBtn: null,
        nextBtn: null,
        tracks: [],
        currentTrackIndex: 0,
        isPlaying: false,
        isScrubbing: false,
        progressFill: null,
        progressGlow: null,
        playhead: null,
        currTimeEl: null,
        totalTimeEl: null,
        albumCircle: null,

        init() {
            this.audio = document.getElementById('releaseAudio');
            this.playBtn = document.getElementById('playBtn');
            this.prevBtn = document.getElementById('prevBtn');
            this.nextBtn = document.getElementById('nextBtn');
            this.progressFill = document.getElementById('progressFill');
            this.progressGlow = document.getElementById('progressGlow');
            this.playhead = document.getElementById('playhead');
            this.currTimeEl = document.getElementById('currTime');
            this.totalTimeEl = document.getElementById('totalTime');
            this.albumCircle = document.getElementById('albumCircle');
            this.albumPlayBtn = document.getElementById('albumPlayBtn');

            const tracklist = document.getElementById('releaseTracklist');
            if (tracklist) {
                this.tracks = Array.from(tracklist.querySelectorAll('.track'));
            }

            if (!this.audio || !this.playBtn) {
                console.warn('Audio player elements not found');
                return;
            }

            this.generateWaveform();
            this.loadTrack(0);

            this.bindEvents();
            this.updatePlayIcon();
        },

        generateWaveform() {
            const container = document.getElementById('progressWaveform');
            if (!container) return;
            const heights = [40,65,45,80,55,70,50,85,60,75,45,90,55,70,40,65,80,50,75,45,60,85,55,70,40,65,80,50,75,45,60,85,55,70,40,65,80,50,75,45,60,85,55,70,40,65,80,50,75,45,60,85,55,70,40,65,80,50,75,45,60,85,55,70,40,65,80,50,75,45,60,85,55,70,40,65,80,50];
            heights.forEach(h => {
                const bar = document.createElement('div');
                bar.className = 'waveform-bar';
                bar.style.height = h + '%';
                container.appendChild(bar);
            });
        },

        bindEvents() {
            this.playBtn.addEventListener('click', () => this.togglePlay());
            
            if (this.albumPlayBtn) {
                this.albumPlayBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.togglePlay();
                });
            }
            
            if (this.prevBtn) {
                this.prevBtn.addEventListener('click', () => this.playPrev());
            }
            
            if (this.nextBtn) {
                this.nextBtn.addEventListener('click', () => this.playNext());
            }

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

            const progressTrack = document.querySelector('.waveform-container');
            if (progressTrack) {
                progressTrack.addEventListener('click', (e) => this.handleSeek(e));
                progressTrack.addEventListener('mousedown', (e) => this.startScrub(e));
                document.addEventListener('mousemove', (e) => this.scrub(e));
                document.addEventListener('mouseup', (e) => this.endScrub(e));
            }

            this.audio.addEventListener('play', () => this.onPlay());
            this.audio.addEventListener('pause', () => this.onPause());
            this.audio.addEventListener('ended', () => this.onEnded());
            this.audio.addEventListener('timeupdate', () => this.updateProgress());
            this.audio.addEventListener('loadedmetadata', () => this.onLoadedMetadata());
            this.audio.addEventListener('error', (e) => this.onError(e));

            document.addEventListener('keydown', (e) => {
                if (e.code === 'Space' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
                    const anyModalActive = document.querySelector('.about-modal-overlay.active, .project-modal-overlay.active');
                    if (!anyModalActive) {
                        e.preventDefault();
                        this.togglePlay();
                    }
                }
            });
        },

        formatTime(seconds) {
            if (isNaN(seconds) || !isFinite(seconds)) return '0:00';
            const mins = Math.floor(seconds / 60);
            const secs = Math.floor(seconds % 60);
            return `${mins}:${secs.toString().padStart(2, '0')}`;
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

            if (this.currTimeEl) {
                this.currTimeEl.textContent = '0:00';
            }
            if (this.progressFill) {
                this.progressFill.style.width = '0%';
            }
            if (this.playhead) {
                this.playhead.style.left = '0%';
            }
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

        handleSeek(e) {
            const bar = e.currentTarget;
            const rect = bar.getBoundingClientRect();
            const percent = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
            
            if (!this.audio.src || this.audio.src === window.location.href) {
                this.loadTrack(this.currentTrackIndex);
            }
            
            if (this.audio.duration) {
                this.audio.currentTime = percent * this.audio.duration;
                if (!this.isPlaying) {
                    this.audio.play().catch(err => {
                        console.warn('Play failed:', err);
                    });
                }
            }
        },

        startScrub(e) {
            this.isScrubbing = true;
            this.handleSeek(e);
        },

        scrub(e) {
            if (!this.isScrubbing) return;
            const progressTrack = document.querySelector('.waveform-container');
            if (!progressTrack) return;
            const rect = progressTrack.getBoundingClientRect();
            const percent = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
            if (this.audio.duration && this.progressFill) {
                this.progressFill.style.width = `${percent * 100}%`;
                if (this.playhead) {
                    this.playhead.style.left = `${percent * 100}%`;
                }
                if (this.progressGlow) {
                    this.progressGlow.style.left = `${percent * 100}%`;
                }
                if (this.currTimeEl) {
                    this.currTimeEl.textContent = this.formatTime(percent * this.audio.duration);
                }
            }
        },

        endScrub(e) {
            if (this.isScrubbing) {
                this.isScrubbing = false;
                this.handleSeek(e);
            }
        },

        onPlay() {
            this.isPlaying = true;
            this.updatePlayIcon();
            if (this.albumCircle) {
                this.albumCircle.classList.add('playing');
                this.albumCircle.classList.remove('paused');
            }
            if (this.playhead) {
                this.playhead.classList.add('visible');
            }
            if (this.progressGlow) {
                this.progressGlow.classList.add('visible');
            }
            const progressBar = document.querySelector('.release-progress');
            if (progressBar) progressBar.classList.add('visible');
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
            if (this.playhead) {
                this.playhead.classList.remove('visible');
            }
            if (this.progressGlow) {
                this.progressGlow.classList.remove('visible');
            }
            this.playNext();
        },

        updateProgress() {
            if (this.audio.duration) {
                const percent = (this.audio.currentTime / this.audio.duration) * 100;
                if (this.progressFill) {
                    this.progressFill.style.width = `${percent}%`;
                }
                if (this.playhead) {
                    this.playhead.style.left = `${percent}%`;
                }
                if (this.progressGlow) {
                    this.progressGlow.style.left = `${percent}%`;
                }
                if (this.currTimeEl) {
                    this.currTimeEl.textContent = this.formatTime(this.audio.currentTime);
                }
            }
        },

        onLoadedMetadata() {
            if (this.totalTimeEl) {
                this.totalTimeEl.textContent = this.formatTime(this.audio.duration);
            }
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
            const iconPlay = this.playBtn.querySelector('.icon-play');
            const iconPause = this.playBtn.querySelector('.icon-pause');
            
            if (this.isPlaying) {
                if (iconPlay) iconPlay.style.display = 'none';
                if (iconPause) iconPause.style.display = 'block';
                this.tracks.forEach((track, i) => {
                    track.classList.toggle('playing', i === this.currentTrackIndex);
                });
            } else {
                if (iconPlay) iconPlay.style.display = 'block';
                if (iconPause) iconPause.style.display = 'none';
                this.tracks.forEach(track => track.classList.remove('playing'));
            }
        }
    };

    audioPlayer.init();

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
