/**
 *
 *  Main JavaScript
 *  @package gleesik_scripts
 *
 */

 // IIFE - Immediately Invoked Function Expression
(function($, window, document) {

  // The $ is now locally scoped

  // Listen for the jQuery ready event on the document
  $(function() {

    // The DOM is ready!

    // Options
    var $options = $('#options');
    var $toggle = $('#options #toggle_options');

    // Toggle Options Panel
    $toggle.on('click', () => {
      $options.toggleClass('closed');
    });

    $(document).on('click', '#options li[data-color]', function(event, ui) {
      var data_color = $(this).data('color');
      $("head link#theme").attr("href", 'css/style-' + data_color + '.css');
    });

    // Light / dark mode. The choice is stored so it survives reloads; without
    // a stored choice the page follows the system preference.
    var $modes = $('#options .modes li');
    var dark_query = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

    var storedMode = function() {
      try {
        var value = window.localStorage.getItem('ondralinek-mode');
        return value === 'dark' || value === 'light' ? value : null;
      } catch (error) {
        return null;
      }
    };

    var currentMode = function() {
      return storedMode() || (dark_query && dark_query.matches ? 'dark' : 'light');
    };

    var markMode = function() {
      var mode = storedMode() || 'auto';
      $modes.removeClass('is-active').filter('[data-mode="' + mode + '"]').addClass('is-active');
    };

    var setMode = function(mode) {
      if (mode === 'auto') {
        try { window.localStorage.removeItem('ondralinek-mode'); } catch (error) {}
      } else {
        try { window.localStorage.setItem('ondralinek-mode', mode); } catch (error) {}
      }
      document.documentElement.setAttribute('data-theme', currentMode());
      markMode();
    };

    markMode();

    $modes.on('click', function() {
      setMode($(this).data('mode'));
    });

    if (dark_query) {
      var followSystem = function() {
        if (storedMode()) return;
        document.documentElement.setAttribute('data-theme', currentMode());
        markMode();
      };
      if (dark_query.addEventListener) dark_query.addEventListener('change', followSystem);
      else if (dark_query.addListener) dark_query.addListener(followSystem);
    }

    // Progress Donut
    var $donut_circle = $('.progress-donut .circle');

    $.each( $donut_circle, function(index) {
      var $percent = $( this ).data('pct');
      $(this).find('svg').find('circle.front').css( "stroke-dashoffset", 565.2 - 5.652*$percent);
      // console.log($percent);
    });

    // Smooth Scrolling Links
    $('a[href*="#"]:not([href="#"])').click(function() {
      if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
        var target = $(this.hash);
        target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
        if (target.length) {
          $('html, body').animate({
           scrollTop: target.offset().top
          }, 1000);
          return false;
        }
      }
    });

  });

  // The rest of the code goes here!

}(window.jQuery, window, document));
// The global jQuery object is passed as a parameter
