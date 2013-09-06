# Variable Names have been changed to pretect features

class Foundersuite.Views.EntityAddForm extends Backbone.View

  el: "#EntityForms"

  template:
    errors:     JST['inline_errors/form_inline_error']

  events:
    'click form .cancel a'        : 'reset'
    'submit'                      : 'formController'
    'click .control-group input'  : 'removeErrorClasses'
    'focus .control-group input'  : 'removeErrorClasses'

  initialize: ->
    @collection.on 'remove', =>
      @clearNotice()
      @notice = new Foundersuite.Mixins.Notifications(messages: ['Entity was successfully deleted'], alert_type: 'success', el: "#addEntityModal" )

  init: ->
    @$EntityNameField = @$("#Entity_name")
    @formAdd = if @$el.find('form').hasClass('formAdd') then true else false
    if @$EntityNameField.data().autocomplete
      @$EntityNameField.data().autocomplete.term = null;
    if @formAdd
      @$EntityNameField.typeahead(
        ajax:
          url: @$EntityNameField.data('url')
          method: 'get'
          triggerLength: 2
          loadingClass: 'loading-autocomplete'
        itemSelected: (item, val, text) =>
          @searchEntityData(text)
      )

  searchEntityData: (name) ->
    @toggleWhiteWall()
    $.get(@$EntityNameField.data('url-Entity'), Entity: {name: name}, (data) =>
      @model.set data
      @formAddController()
    )

  reset: (event) =>
    event.preventDefault()
    target = $(event.target).attr 'href'
    $('#addEntityModal .modal-body #EntityForms').load target, =>
      id = (@$el.find('form')[0]).id
      if id
        @model = @collection.get id
      else
        @model = new Foundersuite.Models.Entity
      @init()

  clearNotice: ->
    if @notice
      clearInterval(@notice.timer)
      @notice.$el.find('.alert .close').trigger('click')

  # On Submit
  formController: (event) ->
    event.preventDefault()
    if @$EntityNameField.data().autocomplete
      @$EntityNameField.data().autocomplete.term = null;
    @model.set {"name" : @$EntityNameField.val()}, silent: true
    if @model.isValid()
      if $(event.target).hasClass 'formAdd'
        @searchEntityData(@$EntityNameField.val())
      else
        @toggleWhiteWall()
        @addEntity()
    else
      @displayValidationError()


  toggleWhiteWall: ->
    element = @$el.find('.white-wall')
    if element.length > 0
      element.remove()
    else
      @$el.append('<div class="white-wall"></div>')

  formAddController: ()->
    _attr = @model.attributes
    if _attr.url && _attr.blog && _attr.twitter && _attr.rss
      @addEntity(true)
    else
      @$el.find('form').removeClass('formAdd').addClass('formEdit')
      @formAdd = false
      $('#Entity_url').val(_attr.url)
      $('#Entity_blog').val(_attr.blog)
      $('#Entity_rss').val(_attr.rss)
      $('#Entity_twitter').val(_attr.twitter)
      @toggleWhiteWall()
      @clearNotice()
      @notice = new Foundersuite.Mixins.Notifications(messages: ['Found it, but some info is missing...'], alert_type: 'success', el: "#addEntityModal")
      @$el.find('#EntityData').slideDown 'fast'

  addEntity: (directAdd) ->
    valid = true
    unless directAdd
      valid = @model.set @parseForm(@$el.find('form')).Entity
    # Front End Backbone Validation
    if valid
      @model.save(@model.attributes,
        wait: true
        success: (attributes) =>
          @toggleWhiteWall()
          @clearNotice()
          noticeMessage = if @formAdd then 'added' else 'updated'
          @notice = new Foundersuite.Mixins.Notifications(messages: ["Entity was successfully #{noticeMessage}" ], alert_type: 'success', el: "#addEntityModal" )
          @$el.find('form .cancel a').trigger 'click'
          if @formAdd
            @trigger 'addModel', @model
          else
            @model.set attributes
            @model.trigger 'updateView'
            @model.fetchApiData()
        error: (model, xhr, options) =>
          @clearNotice()
          @toggleWhiteWall()
          new Foundersuite.Views.InlineErrors(
            el: @$el.find('form')
            attWithErrors: JSON.parse xhr.responseText
            modelName: 'Entity'
          )
          @clearNotice()
          @notice = new Foundersuite.Mixins.Notifications(messages: ['Entity was not added'], alert_type: 'alert', el: "#addEntityModal" )
      )
    else # Didn't pass Backbone validation
      @toggleWhiteWall()
      @displayValidationError()
      @clearNotice()
      @notice = new Foundersuite.Mixins.Notifications(messages: ['Invalid inputs'], alert_type: 'alert', el: "#addEntityModal" )

  displayValidationError: ->
    errors = @model.validationError
    for key of errors
      @displayInlineError @$el.find("#Entity_#{key}"), errors[key], 'error'

  removeErrorClasses: (e) ->
    element = if e.target then $(e.target) else e
    element.closest('.control-group').removeClass 'error success warning'
    if element.next().hasClass("inline-error")
      element.next().remove()
    false

  displayInlineError: (element, errorMsg, errorClass) ->
    @removeErrorClasses(element)
    if element.next().hasClass("inline-error")
      element.next().remove()
    element.after(@template.errors(error: errorMsg))
    element.closest('.control-group').addClass errorClass
