(function() {
  $(document).ready(function() {
    return $('div.sele_path input[type="checkbox"]').each(function() {
      return $(this).on('click', function() {
        var checked_value;

        checked_value = $(this).prop('checked');
        $('div.sele_path input[type="checkbox"]').prop('checked', false);
        return $(this).prop('checked', checked_value);
      });
    });
  });

}).call(this);

