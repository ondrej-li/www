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

    $(document).on('click', '#options li', function(event, ui) {
      var data_color = $(this).data('color');
      $("head link#theme").attr("href", 'css/style-' + data_color + '.css');
    });

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
