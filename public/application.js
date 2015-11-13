$(document).ready(function() {
  $(document).on('click', '#hit_form input', function () {
    $('#player_well img:last-child').animate({
      marginLeft: '-=140px'}, 1000).promise().done(function () {
      $.ajax({
        type: 'POST',
        url: '/game/player/hit'
        }).done(function(msg) {
          $('#game').replaceWith(msg);
        });
        return false;
    });
    return false;
  });
  $(document).on('click', '#stand_form input', function () {
    $.ajax({
      type: 'POST',
      url: '/game/player/stand'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });
  $(document).on('click', '#dealer_form input', function () {
    $('#dealer_well img:last-child').animate({
      marginLeft: '-=140px'}, 1000).promise().done(function () {
        $.ajax({
          type: 'POST',
          url: '/game/dealer/hit'
          }).done(function(msg) {
            $('#game').replaceWith(msg);
          });
          return false;
    });
    return false;
  });
});