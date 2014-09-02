$(document).ready ->
  $('div.sele_path input[type="checkbox"]').each ->
    $(this).on 'click', ->
      checked_value = $(this).prop('checked')
      $('div.sele_path input[type="checkbox"]').prop('checked',false)
      $(this).prop('checked', checked_value)

  #$('button#run').on 'click', ->
  #  $('div.sele_path input[type="checkbox"]').each ->
  #    alert "#{$(this).attr('name')} is checked" if $(this).prop('checked')

