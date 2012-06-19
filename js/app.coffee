#               _   __                                
#              | | / /                                
#     _ __ ___ | |/ /  __ _ _ __ ___  _ __  _   _ ___ 
#    | '_ ` _ \|    \ / _` | '_ ` _ \| '_ \| | | / __|
#    | | | | | | |\  \ (_| | | | | | | |_) | |_| \__ \
#    |_| |_| |_\_| \_/\__,_|_| |_| |_| .__/ \__,_|___/
#                                    | |              
#                                    |_|              

################### CONFIGURATION ###################

StackMob.init
  appName: "mkampus2"
  clientSubdomain: "mobilefactorysa"
  apiVersion: 1
  
moment.lang('pl')

################### JAVASCRIPT EXTENSIONS ###################

do (String) ->
  
  String::startsWith or= (str) ->
    @indexOf(str) is 0
  
  templateCache = {}
  
  String::template = () ->
    templateCache[@] or= Handlebars.compile(@)
  
  String::render = (data) ->
    templateData = _.extend _.clone(window.globals), data
    @template()(templateData)
    
  String::toURL = ->
    encodeURIComponent(@)
  
  String::fromURL = ->
    decodeURIComponent(@)

################### HANDLEBARS PARTIALS ###################
  
partial = (sources) ->
  for name, source of sources
    Handlebars.registerPartial name, source

helper = (helpers) ->
  for name, fn of helpers
    Handlebars.registerHelper name, fn

partial navbar: """
<div class="navbar navbar-fixed-top">
  <div class="navbar-inner">
    <div class="container">
      <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </a>
      <div class="nav-collapse collapse">
        <ul class="nav">
          {{#links}}
            <li {{#if active}}class="active"{{/if}}>
              <a class="link" href="{{href}}">{{label}}</a>
            </li>
          {{/links}}
        </ul>
        <ul class="nav pull-right">
          {{#if current_user }}
            <li>
              <a href="/">
                <i class="icon-off icon-white"></i>
                Wyloguj ( {{ current_user }} )
              </a>
            </li>
          {{/if}}
        </ul>
      </div>
    </div>
  </div>
</div>
"""

helper if_eq: (context, options) ->
	if context is options.hash.compare
		options.fn(context)
	else
	  options.inverse(context)

helper restaurantNavbar: (context) ->
  "{{> navbar}}".render links: [
    {href: '#', label: 'Restauracja', active: true}
  ]

helper navbar: (context) ->
  "{{> navbar}}".render links: [
    {href: '#/notifications', label: 'Powiadomienia'}
    {href: '#/surveys',       label: 'Ankiety'}
    {href: '#/informations',  label: 'Informacje'}
    {href: '#/map',           label: 'Mapa'}
    {href: '#/restaurants',   label: 'Restauracje'}
    {href: '#/contact',       label: 'Kontakt'}
  ]

partial footer: """
<footer>
  <a href="http://www.mobilefactory.com/pl/mkampus/"><img src="/img/mkampus.png"/></a>
  <img src="/img/logo.png" />
</footer>
"""

helper footer: ->
  "{{> footer}}".render()

helper header: (title, options) ->
  """
  <header>
    <div class="container list-view">
      <div class="row">
        <div class="span4 category">
          <h1>{{title}}</h1>
        </div>
        
        <div class="span8 add-section">
          {{{add_section}}}
        </div>
      </div>
    </div>
  </header>
  """.render {title, add_section: options.fn(@)}


helper items: (id) ->
  """
  <div class="container">
    <section>
    <div class="row" id="{{id}}">
      ...
    </div>
    </section>
  </div>
  """.render {id}
  
helper layout: (options) ->
  """
  {{{navbar}}}
  {{{content}}}
  """.render {content: options.fn(@)}

helper timeHuman: (time) ->
  timestamp = moment(time)
  timestamp.format('LLL')

helper timeAgo: (time) ->
  timestamp = moment(time)
  timestamp.fromNow()

helper timeSwitch: (time) ->
  """
  <span class="hover-switch">
    <span class="hover-on">{{ timeHuman time }}</span>
    <span class="hover-off">{{ timeAgo time }}</span>
  </span>
  """.render {time}

################### LOGIN ########################

class User extends StackMob.User

class Users extends StackMob.Collection
  model: User

class LoginView extends Backbone.View

  template: """<div class="container" id="login">
    
      <form action="POST" class="form-horizontal login-form">
      <div class="modal login-modal" style="position: relative; top: auto; left: auto; margin: 0 auto; z-index: 1; max-width: 100%;">
        <div class="modal-header">
          <h3>Uniwersytet Ekonomiczny we Wrocławiu</h3>
        </div>
        <div class="modal-body">
            <fieldset>

              <div class="control-group">
                <label for="login-input" class="control-label">Login</label>
                <div class="controls"><input type="text" id="login-input" class="input-xlarge" autofocus /></div>
              </div>
              <div class="control-group">
                <label for="password-input" class="control-label">Hasło</label>
                <div class="controls"><input type="password" id="password-input" class="input-xlarge" /></div>
              </div>
            </fieldset>

        </div>
        <div class="modal-footer">
          <input id="login-button" type="submit" class="btn btn-big btn-primary" value="Zaloguj" />
        </div>
      </div>
      </form>
      {{{ footer }}}
    </div>"""

  events:
    submit: 'submit'

  submit: (e) =>
    # console.log "submited"
    e.preventDefault()
    $('#login-button').button('toggle')
    user = new User({username: @$('#login-input').val(), password: @$('#password-input').val()})
    # console.log "LOGIN user", user
    user.login false,
      success: (u) =>
        # $('#login-button').button('toggle')
        # console.log 'logged in user', user
        # console.log 'StackMob.getLoggedInUser()', StackMob.getLoggedInUser()
        @trigger 'login', user
      error: (u, e) =>
        @$('.control-group').addClass('error')
        $('#login-button').button('toggle')

  render: ->
    @$el.html @template.render()
    @$('#login-input').focus()
    @

################### BACKBONE EXTENSIONS ###################

class LoadableCollection extends StackMob.Collection
  load: ->
    unless @fetchPromise?
      @fetchPromise = $.Deferred()
      @fetch success: =>
        @fetchPromise.resolve(@)
    @fetchPromise

class SortableCollection extends LoadableCollection
  comparator: (model) ->
    model.get('position')

  parse: (response) ->
    _(response).reject (model) -> model.is_deleted

  newPosition: ->
    if @length > 0
      sorted = _(@pluck('position').sort((a, b) -> a - b))
      last = if sorted.last() > @length then sorted.last() else @length
      last + 1
    else
      1

  createNew: ->
    new @model({position: @newPosition()})

class View extends Backbone.View
  
  getImagePreview: -> @$('.image-preview')
  
  onImageChange: (e) ->
    e.stopPropagation()
    e.preventDefault()
    file = e.target.files[0]
    reader = new FileReader()
    reader.onload = (e) =>
      $image = @getImagePreview()
      
      # console.log '.image-preview', $image
      # console.log 'image', e.target.result
      
      $image.attr('src', e.target.result)
      setTimeout =>
        width = $image[0].clientWidth
        height = $image[0].clientHeight
        console.log 'WH after', width, height
        @model.set {image_width: width, image_height: height}
        base64Content = e.target.result.substring(e.target.result.indexOf(',') + 1, e.target.result.length)
        fileName = file.name
        fileType = file.type
        @model.setBinaryFile('image_url', fileName, fileType, base64Content)
        @model.setBinaryFile('image_content', fileName, fileType, base64Content)
      , 1000
    fileContent = reader.readAsDataURL(file)
  
class CollectionView extends View
  
  waitForCollection: ->
    if @$collection
      # console.log 'wait'
      @$collection.html """<section class="item loading"><img src="/img/progress.gif"/></section>"""
  
  initialize: ->
    # console.log 'CollectionView initialized'
    @waitForCollection()
    
    @itemView or= @options.itemView
    $.when(@collection).then (collection) =>
      # console.log 'collection', collection
      collection.on 'reset', @addAll
      collection.on 'add', @addAll
      collection.on 'remove', @addAll

  addAll: =>
    $collection = @$collection or @$el
    # console.log '$collection', $collection
    $.when(@collection).then (collection) =>
      # collection.sort()
      # console.log 'CollectionView addAll from collection', collection, collection.length, @itemView
      # if collection.length > 0
      $collection.empty()
      # console.log 'empty'
      collection.each @addOne

  addOne: (model) =>
    # console.log 'add', model
    options = _.extend(_.clone(@options), {model, @collection})
    view = new @itemView options
    # console.log 'view', view
    if @$collection?
      @$collection.append view.render().el
      # if @options.prepend?
      #   @$collection.prepend view.render().el
      # else
      #   # console.log '@$collection', @$collection 
      #   @$collection.append view.render().el

  render: ->
    # console.log 'CollectionView rendered', @
    @$collection or= @$el
    @waitForCollection()
    @addAll()
    @

class AddView extends Backbone.View

  template: """
    <input type="text" class="add" placeholder="{{ placeholder }}"/>
    """

  events:
    'click input': 'add'

  add: (event) ->
    @collection.trigger 'new'
    @trigger 'click'

  getPlaceholder: ->
    @options.placeholder or "Dodaj"

  render: ->
    @$el.html @template.render {placeholder: @getPlaceholder()}
    @

class MenuLayout extends Backbone.View # title, addView, listView
  
  template: """
    {{#layout}}
      <header>
        <div class="container list-view">
          <div class="row">
            <div class="span4 category">
              <h1>{{ title }}</h1>
            </div>
            <div class="span8 add-section">
            </div>
          </div>
        </div>
      </header>
      <div class="container">
        <section>
          <div class="row menu">
            <div class="progress"><img src="/img/progress.gif"></img></div>
          </div>
        </section>
      </div>
    {{/layout}}
    """
  
  render: ->
    collection = @collection
    title = @title or @options.title
    addView = @addView or @options.addView
    listView = @listView or @options.listView
    
    @$el.html @template.render {title}
    
    $addSection = @$('.add-section')
    $list = @$('.menu')
    
    
    addView.setElement $addSection
    listView.setElement $list
    
    addView.render()
    listView.render()
    # $list.html listView.render().el 
    @

class SidebarLayout extends Backbone.View
  template: """
    {{#layout}}
      <div class="container item-view">
        <div class="row">
          <div class="span4">
            <div class="category">
              <a href="{{ backLink }}"><h1>{{ title }}</h1></a>
            </div>
            <div class="row hidden-phone menu">
            </div>
          </div>
          <div class="span8 main">
          </div>
        </div>
      </div>
    {{/layout}}
  """
  
  render: ->
    title = @title or @options.title
    backLink = @backLink or @options.backLink
    mainView = @mainView or @options.mainView
    listView = @listView or @options.listView
    
    @$el.html @template.render {title, backLink}
    
    $main = @$('.main')
    $menu = @$('.menu')
    
    mainView.setElement $main
    mainView.render()
    listView.setElement $menu
    listView.render()
    
    @

class SelectableView extends View

  labelAttribute: 'name'
  placeholderLabel: 'Nowy element'
  
  className: 'selectable sortable span4'
  
  attributes: ->
    'data-id': @model.id
    'data-sortable-id': @model.id
  
  template: -> """
    <!-- <div class="selectable sortable span4" data-id="{{ id }}" data-sortable-id= "{{ id }}"> -->
    <!-- <div class="{{#if hasChanged}} waiting {{/if}}"> -->
      <p class="date">{{{ timeSwitch createddate }}}</p>
      <p class="content">
        {{#if #{@labelAttribute} }} {{ #{@labelAttribute} }} {{else}} #{@placeholderLabel} {{/if}}
      </p>
    <!-- </div> -->
    """

  initialize: ->
    @$el.data('id', @model.id)
    @$el.data('sortable-id', @model.id)
    
    @model.on 'change', @render
    @model.on 'reset', @render
    @model.on 'sync', @render

  events:
    'click': 'triggerSelect'

  triggerSelect: =>
    @model?.trigger 'select', @model
    @trigger 'select', @model

  render: =>
    @$el.html @template().render _.extend(@model.toJSON(), {id: @model.id, hasChanged: @model.hasChanged()})
    
    # if @model.hasChanged()
    #   # console.log 'waiting', @model.get 'name'
    #   @$el.addClass('waiting')
    # else
    #   # console.log 'not waiting', @model.get 'name'
    #   @$el.removeClass('waiting')
    @$el.toggleClass('waiting', @model.hasChanged())
    window.app.updateLinks()
    @    


class Image extends StackMob.Model
  schemaName: 'image'

class ModelWithImage extends StackMob.Model

  initialize: ->
    @on 'sync', @updateImageModel, @

  getImageId: ->
    "#{@constructor.name}_#{@id}"

  updateImageModel: =>
    image = new Image
      image_id: @get('image')
      width: @get('image_width')
      height: @get('image_height')
      url: @get('image_url')
    image.save {}, error: ->
      image.create()
    @fallbackToDefaultImage()
    if @hasChanged()
      @save()
  
  defaultImage: -> 
  
  getImageURL: ->
    if img = @get('image_url')
      # console.log 'ModelWithImage.getImageURL()', img
      imageData = img.split("\n")
      if imageData.length is 5
        type = imageData[0].split(" ")[1]
        # console.log 'image type', type
        content = imageData[4]
        "data:#{type};base64,#{content}"
      else
        img
    else
      @defaultImage()
  
  templateData: ->
    _.extend @toJSON(),
      { image_url: @getImageURL() }

  save: ->
    @beforeSave()
    super

  beforeSave: =>
    @preventImageDestruction()
    @fallbackToDefaultImage()

  preventImageDestruction: => # (yes, StackMob do this by default)
    content = @get('image_content')
    url = @get('image_url')
    if content and content isnt url
      @set image_url: content

  fallbackToDefaultImage: =>
    if @id and not @has('image')
      @set image: @getImageId()

################### NOTIFICATIONS ###################

class Notification extends StackMob.Model
  schemaName: 'notification'
  
  @maxLength: 200
  
  @maxDisplayLength: 100
  

class Notifications extends LoadableCollection
  model: Notification
  
  comparator: (model) ->
    -model.get('createddate')

class NotificationView extends Backbone.View
  className: 'notification span4'
  template: """
    <p class="date">{{{ timeSwitch createddate }}}</p>
    <p class="content">{{ content }}</p>
    """
    
  render: ->
    @$el.html @template.render @model.toJSON()
    @

class NotificationsView extends CollectionView
  
  itemView: NotificationView
  
  template: """
    {{#layout}}
      {{#header "Powiadomienia"}}
        <form action="" id="new-notification-form" class="editable">
          <textarea name="" id="new-notification-input" rows="1" class="add" placeholder="Treść nowego powiadomienia"></textarea>
          <div class="form-actions edit">
            <div class="row-fluid">
              <div class="span6">
                <div class="progress" id="new-notification-progress">
                  <div id="new-notification-bar" class="bar" style="width: 0%;"></div>
                </div>
              </div>
              <div class="span6">
                <button type="submit" id="new-notification-submit" data-loading-text="Wysyłam..." class="btn btn-primary btn-large pull-right">
                  <i class="icon-ok icon-white"></i>
                  Wyślij
                </button>
                <!-- <input type="submit" id="new-notification-submit" data-loading-text="Wysyłam..." class="btn btn-primary btn-large pull-right" value="Wyślij" /> -->
              </div>
            </div>
          </div>
        </form>
      {{/header}}
      {{{items "notifications"}}}
    {{/layout}}
    """
  
  events:
    'focus #new-notification-input': 'edit'
    'blur #new-notification-input': 'show'
    'keyup #new-notification-input': 'update'
    'submit #new-notification-form': 'submit'
  
  initialize: ->
    @options.prepend = true
    super
  
  edit: ->
    @$editable.addClass('active')
    @$input.attr('rows', 4)
      
  show: ->
    return if @$input.val().length > 0
    @$editable.removeClass('active')
    @$input.attr('rows', 1)
    
  update: ->
    max = Notification.maxLength
    letters = @$input.val().length
    percent = letters / max * 100
    barClass = if letters <= Notification.maxDisplayLength
      'progress-success'
    else if percent <= 100
      'progress-warning'
    else
      'progress-danger'
    @$submit.toggleClass('disabled', percent > 100 or letters == 0)
    if percent > 100
      percent = 100
    @$bar.attr('style', "width: #{percent}%;")
    @$progress.attr('class', "progress #{barClass}")
  
  reset: =>
    @$input.val('')
    @update()
    @$submit.button('reset')
    @show()
  
  submit: (e) ->
    e.preventDefault()
    content = @$input.val()
    return if content.length < 0 or content.length > Notification.maxLength
    @$submit.button('loading')
    # console.log 'StackMob.getLoggedInUser()', StackMob.getLoggedInUser()
    StackMob.customcode 'broadcast'
      , {content}
      , success: =>
        # console.log 'broadcast sent'
        @collection.create {content}, wait: true
          , success: =>
            @reset()
          , failure: =>
            alert('Powiadomienie wysłano, ale nastąpił problem z bazą danych w wyniku czego nie pojawi się na liście. Przepraszamy.')
            @reset()
      , error: =>
        alert('Błąd podczas wysyłania powiadomienia. Spróbuj ponownie później.')
        @$submit.button('reset') 
  
  render: ->
    @$el.html @template.render()
    @$input = @$('#new-notification-input')
    @$progress = @$('#new-notification-progress')
    @$bar = @$('#new-notification-bar')
    @$submit = @$('#new-notification-submit')
    @$editable = @$('.editable')
    @$collection = @$('#notifications')
    super
    @update()
    @

############################# SURVEYS #############################

class Survey extends StackMob.Model
  schemaName: 'survey'
  
  defaults: ->
    title: ''
  
  validate: ({title}) ->
    # console.log 'survey validation, title:', title
    if title.length < 1
      return "Ankieta musi mieć tytuł"
    null
  
  initialize: ->
    # @on 'show', => @getQuestions()
    @on 'sync', @saveQuestions
  
  saveQuestions: =>
    @questions.each (model) =>
      model.save {survey: @id}
      
  getQuestions: ->
    unless @fetchQuestionsPromise?
      @fetchQuestionsPromise = $.Deferred()
      @questions = new Questions()
      if @id?
        fetchMyQuestions = new StackMob.Collection.Query()
        fetchMyQuestions.equals('survey', @id)
        @questions.query(fetchMyQuestions)
        @questions.on 'reset', => @fetchQuestionsPromise.resolve(@questions)
      else
        @fetchQuestionsPromise.resolve(@questions)
    @fetchQuestionsPromise
    

class Surveys extends LoadableCollection
  model: Survey
  
  comparator: (model) ->
    -model.get('createddate')

  
class Answer extends StackMob.Model
  schemaName: 'answer'


class Answers extends StackMob.Collection
  model: Answer
  
  toJSON: ->
    null
  
  getContents: ->    
    _(@pluck('content').map((content) ->
      try
        JSON.parse(content)
      catch error
        content
    )).reject (element) -> _(element).isNull()


# class RadioAnswers extends Answers
#   
#   toJSON: ->
#     results = {}
#     _(@getContents()).each (id) ->
#       results[id] or= 0
#       results[id] += 1
#     results
# 
# 
# class CheckboxAnswers extends Answers
#   
#   toJSON: ->
#     results = {}
#     _(@getContents()).each (array) ->
#       _(array).each (id) ->
#         results[id] or= 0
#         results[id] += 1
#     results
# 
# 
# class TextAnswers extends Answers
#   
#   toJSON: ->
#     @getContents()
# 
# 
# class RateAnswers extends Answers
#   
#   toJSON: ->
#     contents = @getContents()
#     sum = _(contents).reduce(((memo, element) -> memo + element), 0)
#     sum / contents.length

  
class Question extends StackMob.Model
  schemaName: 'question'
  
  defaults:
    type: '1'
    content: ''
    answers: ''
  
  # Answers: ->
  #   switch @get('type')
  #     when '1' then new RateAnswers()
  #     when '2' then new CheckboxAnswers()
  #     when '3' then new TextAnswers()
  #     when '4' then new RadioAnswers()
  #     else new Answers()

  getUserAnswers: ->
    unless @fetchAnswersPromise?
      @fetchAnswersPromise = $.Deferred()
      @questions =  new Answers()
      if @id?
        fetchMyAnswers = new StackMob.Collection.Query()
        fetchMyAnswers.equals('question', @id)
        @questions.query(fetchMyAnswers)
        @questions.on 'reset', => @fetchAnswersPromise.resolve(@questions)
      else
        @fetchAnswersPromise.resolve(@questions)
    @fetchAnswersPromise
  
  getResults: ->
    promise = $.Deferred()
    $.when(@getUserAnswers()).then (userAnswers) =>
      # console.log 'Question.getUserAnswers() ->', answers.getContents(), @get('content')
      contents = userAnswers.getContents()
      promise.resolve switch @get('type')
        when '1' #rate
          avg = if contents.length is 0
            0
          else
            sum = _(contents).reduce(((memo, element) -> memo + Number(element)), 0)
            sum / contents.length
          # console.log 'rate', avg, @get('content')
          avg * 20
        when '4' #text
          # console.log 'text', contents, @get('content')
          # console.log 'text contents', contents
          contents
          
        when '3' # 'checkbox'
          results = {}
          # console.log '@getAnswerNames()', @getAnswerNames(), @
          _(@getAnswerNames()).each (name, index) ->
            results[index] = {name, votes: 0}
          _(contents).each (content) ->
            _(content).each (index) ->
              if results[index]
                results[index].votes += 1
          array = _(results).map (element) -> element
          # console.log 'checkbox/radio', array, @get('content')
          array
          
        when '2' # 'radio'
          results = {}
          # console.log '@getAnswerNames()', @getAnswerNames(), @
          
          _(@getAnswerNames()).each (name, index) ->
            results[index] = {name, votes: 0}
          
          _(contents).each (index) ->
            if results[index]
              results[index].votes += 1
          # console.log 'kot3', results
          array = _(results).map (element) -> element
          # console.log 'checkbox/radio', array, @get('content')
          array
        else
          null
    promise
  
  getAnswerNames: ->
    try
      JSON.parse(@get('answers'))
    catch error
      try
        @get('answers')[1...-1].split(',')
      catch error
        []
  
  setAnswerNames: (answersArray) ->
    @set answers: try
      JSON.stringify(answersArray)
    catch error
      try
        "[" + answersArray.join(",") + "]"
      catch error
        "[]"
      

class Questions extends StackMob.Collection
  model: Question
  
  types:
    1: 'rate'
    2: 'checkbox'
    3: 'text'
    4: 'radio'
      
  
  # initialize: ->
  #   super
  #   @on 'publish', @onPublish
  #   @savePromises = {}
  # 
  # onPublish: (survey) =>
  #   @each (question) =>
  #     unless @savePromises[question]?
  #       @savePromises[question] = promise = $.Deferred()
  #       question.save {survey: survey.id}, success: (model) =>
  #         promise.resolve model
      
class SurveyView extends Backbone.View
  
  template: """
    <div class="survey selectable span4 {{#if active}} active {{/if}}">
      <p class="date">{{{ timeSwitch createddate }}}</p>
      <p class="content">
        {{#if survey_id}}
        {{else}}
          {{#if active}}
            <i class="icon-pencil icon-white"></i>
          {{else}}
            <i class="icon-pencil"></i>
          {{/if}}
        {{/if}}
        {{ title }}
      </p>
    </div>
    """
  
  events:
    'click': 'select'
  
  initialize: ->
    @model.on 'change', @render
    $.when(@collection).then (collection) =>
      collection.on 'show', @onSelect
  
  onSelect: =>
    @render()

  select: ->
    $.when(@collection).then (collection) =>
      collection.trigger 'show', @model
  
  render: =>
    $.when(@collection).then (collection) =>
      active = collection.active and ((@model.id and collection.active.id is @model.id) or (collection.active.cid is @model.cid))
      @$el.html @template.render _.extend(@model.toJSON(), {active})
      # console.log 'render survey view', collection.active
    # if @collection.active
    #       if (@model.id and @collection.active.id is @model.id) or (@collection.active.cid is @model.cid)
    #         @$('.survey').addClass 'active'
    #       else
    #         @$('.survey').removeClass 'active'
    # 
    # @$('.survey').toggleClass 'active', @collection.active is @model
    # if @collection.active is @model
    @

class QuestionEditView extends Backbone.View
  
  template: """
    <section class="editable {{#if isOpen}} active {{/if}}">
      
      <div class="configurable show">
        <h3>
          <i class="icon-{{icon}}"></i>
          {{ content }}
        </h3>
      </div>
      <div class="row show">
        {{#checkAnswers}}
          <div class="span4 item">
            <label class="checkbox">
              <input type="checkbox" disabled="disabled" />
              {{ this }}
            </label>
          </div>
        {{/checkAnswers}}
        {{#radioAnswers}}
          <div class="span4 item">
            <label class="radio">
              <input type="radio" disabled="disabled" />
              {{ this }}
            </label>
          </div>
        {{/radioAnswers}}
      </div>
      
      <div class="add-section edit">
        <form action="">
          <input class="name add" type="text" autofocus="autofocus" placeholder="Treść nowego pytania" value="{{ content }}"/>
          <div class="form-actions toolbar">
            <div class="btn-group" >
              {{#types}}
                <button class="btn {{#if active}} active {{/if}} type" data-type="{{ type }}">
                  <i class="icon-{{ icon }}"></i>
                  {{ name }}
                </button>
              {{/types}}
            </div>
          </div>
          <textarea rows=3 class="add answers" placeholder="Jedna odpowiedź w jednej linijce">{{ textAnswers }}</textarea>
          <div class="form-actions">
            <button class="btn btn-large destroy-question">
              <i class="icon-remove"></i>
              Usuń pytanie
            </button>
            <button type="submit" class="btn btn-primary btn-large pull-right save">
              <i class="icon-pencil icon-white"></i>
              Zapisz pytanie
            </button>
          </div>
        </form>
      </div>
    </section>
    """
  
  events:
    'click .show': 'edit'
    'click .type': 'setType'
    'click .type > i': 'typeIcon'
    'submit form': 'save'
    'click .destroy-question': 'destroy'
  
  typeIcon: (e) ->
    e.target = $(e.target).parent()[0]
    @setType(e)
  
  initialize: ->
    @isOpen = not @model.get('content')
    @model.collection.on 'edit', @onEdit
    @model.on 'destroy', @onDestroy
  
  onEdit: (model) =>
    # console.log 'onEdit'
    if model is @model
      @open()
    else
      # console.log 'edit another question'
      @persist()
      if @model.get('content').length > 0
        # console.log 'has content -> save'
        @save()
      else
        # console.log 'no content -> destroy'
        @model.destroy()
  
  onDestroy: =>
    @remove()
  
  destroy: (e) =>
    e.preventDefault()
    # console.log 10
    @model.collection.trigger 'close'
    @model.destroy() 
  
  save: (event) =>
    event?.preventDefault?()
    # console.log 'save'
    @persist()
    if @model.get('content').length > 0
      # console.log 'has content'
      @close()
      @model.collection.trigger 'close'
    else
      # console.log "doesn't have content"
      @render()
  
  edit: ->
    @model.collection.trigger 'edit', @model
  
  open: ->
    @isOpen = true
    @render()  
  
  close: (event) ->
    event?.preventDefault?()
    @isOpen = false
    @render()
  
  setType: (e) ->
    e.preventDefault()
    type = $(e.target).data('type')
    return unless type
    type = type.toString()
    @model.set type: type
    @persist()
    @render()
  
  persist: ->
    name = @$('.name').val()
    answers = @serializeAnswers(@$('.answers').val().split("\n"))
    @model.set {content: name, answers}
  
  focus: ->
    @$name.focus()
  
  focusOnAnswers: ->
    @$answers.focus()
  
  icons:
    '1': 'star'
    '2': 'hand-right'
    '3': 'check'
    '4': 'comment'
  
  serializeAnswers: (answersArray) ->
    try
      JSON.stringify(answersArray)
    catch error
      try
        "[" + answersArray.join(",") + "]"
      catch error
        "[]"

  deserializeAnswers: (answersSerialized) ->
    try
      JSON.parse(answersSerialized)
    catch error
      try
        answersSerialized[1...-1].split(',')
      catch error
        []
    
  data: ->
    types = [
        {name: 'Ocena', type: '1', icon: @icons['1']}
        {name: '1 opcja', type: '2', icon: @icons['2']}
        {name: 'Wiele opcji', type: '3', icon: @icons['3']}
        {name: 'Komentarz', type: '4', icon: @icons['4']}
      ]
    type = Number(@model.get('type'))
    types[type - 1].active = true
    
    serializedAnswers = @model.get('answers')
    arrayAnswers = @deserializeAnswers(serializedAnswers)
    textAnswers = arrayAnswers.join("\n")
    
    arrayAnswers = textAnswers.split("\n")
    radioAnswers = if type is 2 then arrayAnswers
    checkAnswers = if type is 3 then arrayAnswers
    
    _.extend @model.toJSON(), {@isOpen, types, textAnswers, checkAnswers, radioAnswers, icon: @icons[type]}
  
  
  render: ->
    @$el.html @template.render @data()
    @$name = @$('.name')
    @$answers = @$('.answers')
    type = @model.get 'type'
    @$answers.toggleClass 'hidden', type not in ["2", "3"]
    @$('.type').each ->
      $(@).toggleClass 'active', $(@).data('type').toString() == type
    if type in ["2", "3"]
      @focusOnAnswers()
    else
      @focus()
    @

class QuestionView extends Backbone.View
  tagName: 'section'
  
  typeTemplates:
    '1': -> """
      {{#results}}
        <div class="span8 item">
          <div class="row-fluid">
            <div class="span10">
              <div class="progress">
                <div class="bar" style="width: {{this}}%;"></div>
              </div>
            </div>
            <div class="span2">
              <span class="badge">{{ this }} %</span>
            </div>
          </div>
        </div>
      {{/results}}
      """ # rate
    '2': -> """
      {{#results}}
        <div class="span8 item">
          <label class="radio">
            <input type="radio" disabled="disabled" />
            {{ name }}
            <span class="badge">{{ votes }}</span>
          </label>
        </div>
      {{/results}}
      """ # radio
    '3': -> """
      {{#results}}
        <div class="span8 item">
          <label class="checkbox">
            <input type="checkbox" disabled="disabled" />
            {{ name }}
            <span class="badge">{{ votes }}</span>
          </label>
        </div>
      {{/results}}
      """ # checkbox
    '4': -> """
      {{#results}}
        <div class="span8 item">
          {{ this }}
        </div>
      {{/results}}
      """ # text
  
  template: => """
    <div class="item">
      <h3>
        <i class="icon-{{icon}}"></i>
        {{ content }}
      </h3>
    </div>
    <div class="row">
      #{@typeTemplates[@model.get('type')]()}
    </div>"""
  
  icons:
    '1': 'star'
    '2': 'hand-right'
    '3': 'check'
    '4': 'comment'
  
  serializeAnswers: (answersArray) ->
    try
      JSON.stringify(answersArray)
    catch error
      try
        "[" + answersArray.join(",") + "]"
      catch error
        "[]"

  deserializeAnswers: (answersSerialized) ->
    try
      JSON.parse(answersSerialized)
    catch error
      try
        answersSerialized[1...-1].split(',')
      catch error
        []
  
  data: ->
    types = [
        {name: 'Ocena', type: '1', icon: @icons['1']}
        {name: 'Decyzja', type: '2', icon: @icons['2']}
        {name: 'Wiele opcji', type: '3', icon: @icons['3']}
        {name: 'Komentarz', type: '4', icon: @icons['4']}
      ]
      
    type = Number(@model.get('type'))
    types[type - 1].active = true
    
    serializedAnswers = @model.get('answers')
    arrayAnswers = @deserializeAnswers(serializedAnswers)
    textAnswers = arrayAnswers.join("\n")
    
    radioAnswers = if type is 2 then arrayAnswers
    checkAnswers = if type is 3 then arrayAnswers

    _.extend @model.toJSON(), {types, textAnswers, checkAnswers, radioAnswers, icon: @icons[type]}
  
  render: ->
    @$el.html """<div class="loading"><img src="/img/progress.gif"/></div>"""
    $.when(@model.getResults()).then (results) =>
      data = _.extend(@data(), {results: results})
      @$el.html @template().render data
    # @$el.html @template.render @data()
    @
  

class SurveyShowView extends CollectionView
  
  template: """
    <div id="title-show" class="category">
      <h1 id="title">{{ title }}</h1>
    </div>
    <div id="questions">
    </div>
    """
  
  itemView: QuestionView
  
  initialize: ->
    @collection = @model.getQuestions()
    $.when(@collection).then (collection) ->
      # console.log 'questions of survey', @model, collection
    super
  
  render: ->
    @$el.html @template.render @model.toJSON()
    @$collection = @$('#questions')
    super
    # console.log '@$collection', @$collection
    @

class SurveyEditView extends CollectionView
  
  template: """
    <div class="editable" id="title-section">
      <div class="add-section edit">
        <form id="title-edit" action="">
          <input id="title-input" type="text" class="add edit" placeholder="Tytuł nowej ankiety" autofocus="autofocus" value="{{ title }}"/>
          <div class="form-actions">
            <button type="submit" id="title-submit" class="btn btn-primary btn-large pull-right">
              <i class="icon-pencil icon-white"></i>
              Zapisz tytuł
            </button>
          </div>
        </form>
      </div>

      <div id="title-show" class="category show">
        <h1 id="title">{{ title }}</h1>
      </div>
    </div>
    <div id="questions">
    </div>
    <section class="top-level-action-block">
      <div>
        <div class="add-section ">
          <input type="text" class="new-question-button add top-level-actions" placeholder="Treść nowego pytania"/>
        </div>
      </div>
    </section>
    <div class="form-actions section">
      <button class="destroy btn btn-large">
        <i class="icon-remove"></i>
        Usuń ankietę
      </button>
      
      <button id="survey-submit" data-toggle="button" class="btn btn-large btn-primary pull-right top-level-actions">
        <i class="icon-ok icon-white"></i>
        Opublikuj ankietę
      </button>
      
    </div>
    """
  
  itemView: QuestionEditView
  
  initialize: ->
    @surveys = window.app.Surveys
    @collection = @model.getQuestions()
    @model.on 'change:title', @onSetTitle
    @model.on 'sync', @onSync
    $.when(@collection).then (collection) =>
      collection.on 'edit', @onEdit
      collection.on 'close', @onClose  
    super

  events:
    'click .new-question-button': 'createQuestion'
    'submit #title-edit': 'closeTitle'
    'click #title-show': 'openTitle'
    'click .destroy': 'destroy'
    'click #survey-submit': 'publish'
  
  onSetTitle: =>
    # console.log 'on set ttitle'
    collection = window.app.Surveys
    unless collection.include @model
      collection.add @model
  
  onSync: =>
    # $.when(@collection).then (collection) =>
    window.app.Surveys.trigger 'publish', @model
  
  publish: (e) =>
    e?.preventDefault()
    # console.log 'publish'
    @model.save()
    # @$('#survey-submit').button()
    
    button = @$('#survey-submit')
    # console.log 'survey submit', button
    
    # @$('#survey-submit').button('toggle')
    @$('#survey-submit').addClass('disabled')
  
  destroy: (e) =>
    e.preventDefault()
    # console.log 'destroy'
    @model.destroy()
    $.when(@collection).then (collection) =>
      collection.remove @model
      app.navigate '/surveys', true
    
  createQuestion: =>
    question = new Question()
    $.when(@collection).then (collection) =>
      collection.add question
      collection.trigger 'edit', question
  
  onEdit: (model) =>
    if model is @model
    else
      @closeTitle()
    @$('.top-level-action-block').addClass 'hidden'
    @$('.top-level-actions').attr 'disabled', 'disabled'
  
  onClose: =>
    @$('.top-level-action-block').removeClass 'hidden'
    @$('.top-level-actions').attr 'disabled', false
  
  closeTitle: (e) =>
    e?.preventDefault?()
    previousTitle = @model.get 'title'
    title = @$titleInput.val()
    if title.length is 0
      @openTitle()
    else
      @model.set {title}
      @$title.html title
      @$titleSection.removeClass('active')
      $.when(@collection).then (collection) =>
        collection.trigger 'close'

  openTitle: ->
    @$titleSection.addClass('active')
    @$titleInput.focus()
    $.when(@collection).then (collection) =>
      collection.trigger 'edit', @model
    
  updateState: ->
    title = @model.get('title') 
    unless title
      @openTitle()
  
  render: ->
    @$el.html @template.render @model.toJSON()
    @$collection = @$('#questions')
    @$newQuestionInput = @$('#new-question')
    @$submit = @$('#survey-submit')
    @$titleSection = @$('#title-section')
    @$title = @$('#title')
    @$titleInput = @$('#title-input')
    @$titleEdit = @$('#title-edit')
    @$titleShow = @$('#title-show')
    @$titleSubmit = @$('#title-submit')
    @updateState()
    super
    @

################### INFORMATIONS ########################

class InformationElement extends ModelWithImage
  schemaName: 'information_element'
  
  initialize: ->
    @isOpen = not @id
    super
  
  defaults:
    type: 'text'
  
  parse: (data) ->
    if typeof data is 'object'
      data
    else
      super

class InformationElements extends SortableCollection
  model: InformationElement

class InformationGroup extends StackMob.Model
  schemaName: 'information_group'
  collectionClass: InformationElements
  
  saveInformations: =>
    @informations.each (model) =>
      model.save {survey: @id}
  
  getInformations: ->
    unless @fetchElementsPromise?
      @fetchElementsPromise = $.Deferred()
      @informations = new @collectionClass()
      if @id?
        fetchMyElements = new StackMob.Collection.Query()
        # console.log '@id', @id
        fetchMyElements.equals(@schemaName, @id)
        @informations.query(fetchMyElements)
        # console.log 'waiting for reset', @informations
        @informations.on 'all', (event) =>
          # console.log 'informations event', event
        @informations.on 'reset', =>
          # console.log 'reset', @informations
          @fetchElementsPromise.resolve(@informations)
      else
        @fetchElementsPromise.resolve(@informations)
    @fetchElementsPromise

class InformationGroups extends SortableCollection
  model: InformationGroup
  
class InformationGroupView extends SelectableView

class ElementView extends View
  
  events: ->
    'click .show': 'open'
    'click .save-button': 'save'
    'submit': 'save'
    'click .destroy-button': 'destroy'
    'click .up-button': 'up'
    'click .down-button': 'down'
    # 'change .image-input': 'onImageChange'
  
  up: (event) ->
    event.preventDefault()
    # console.log 'up'
    sortedAbove = _(@model.collection.filter((model) => model.get('position') < @model.get('position'))).sortBy((m) -> m.get('position'))
    if sortedAbove.length > 0
      swapWith = _(sortedAbove).last()
      myPosition = @model.get('position')
      @model.set position: swapWith.get('position')
      swapWith.set position: myPosition
      @model.collection.sort()
      @model.save({}, {wait:true})
      swapWith.save({}, {wait:true})
  
  down: (event) ->
    event.preventDefault()
    # console.log 'down'
    sortedAbove = _(@model.collection.filter((model) => model.get('position') > @model.get('position'))).sortBy((m) -> m.get('position'))
    if sortedAbove.length > 0
      swapWith = _(sortedAbove).first()
      myPosition = @model.get('position')
      @model.set position: swapWith.get('position')
      swapWith.set position: myPosition
      @model.collection.sort()
      @model.save({}, {wait:true})
      swapWith.save({}, {wait:true})
  
  initialize: ->
    # @model.on 'change', @render, @
    @model.on 'sync', @onSync, @
    @model.on 'change', @render, @
  
  open: ->
    @model.isOpen = true
    @render()
  
  persist: ->
    type = @model.get('type')
    if type is "text"
      @model.set text: @$(".text-input").val()
    else if type is "title"
      @model.set title: @$(".title-input").val()
    @model.save({}, {wait: true})
  
  save: (event) ->
    event.preventDefault()
    @persist()
    # console.log 'after save'
    @close()
  
  destroy: (event) ->
    event.preventDefault()
    @model.collection?.sort()
    @model.collection?.remove @model
    @model.save is_deleted: true
    
  
  onSync: ->
    if @model.get('is_deleted') is true
      @model.collection?.remove @model
      @remove()
    else
      @render()
  
  close: ->
    @model.isOpen = false
    @render()
  
  render: ->
    # console.log 'model render', @model.toJSON(), @model.changedAttributes()
    data = if @model.templateData? then @model.templateData() else @model.toJSON()
    @$el.html @template().render _.extend(data, {isOpen: @model.isOpen, hasChanged: @model.changedAttributes()})
    @

class InformationElementView extends ElementView
  
  modelId: 'information_element_id'
  
  templateShow:
    text: -> """<p>{{ text }}</p>"""
    title: -> """<h3>{{ title }}</h3>"""
    image: -> """<img src="{{ image_url }}" />"""
  
  templateEdit:
    text: -> """<textarea class="text-input add" type="text" rows="5" autofocus="autofocus" placeholder="Treść nowego akapitu">{{ text }}</textarea>"""
    title: -> """<input class="title-input add" type="text" autofocus="autofocus" placeholder="Treść nowego tytułu" value="{{ title }}" />"""
    image: -> """
      <p><img class="image-preview" src="{{ image_url }}"/></p>
      <p><input type="file" class="image-input" name="image" /></p>
      """
  
  template: -> """
    <section class="editable sortable {{#if isOpen}} active {{/if}} {{#if hasChanged}} waiting {{/if}}" data-sortable-id="{{#{@modelId}}}">
      <div class="configurable show">
        #{if template = @templateShow[@model.get('type')] then template()}
      </div>
      <div class="add-section edit">
        <form class="edit-form" action="">
          #{if template = @templateEdit[@model.get('type')] then template()}
          <div class="form-actions">
            <div class="btn-toolbar pull-right">

              <!--<div class="btn-group">
                
                <button class="up-button btn btn-large">
                  <i class="icon-arrow-up"></i>
                </button>
                <button class="down-button btn btn-large">
                  <i class="icon-arrow-down"></i>
                </button>
                
              </div>-->

              <div class="btn-group">
                <button type="submit" class="save-button btn btn-primary btn-large">
                  <i class="icon-pencil icon-white"></i>
                  Zapisz element
                </button>
              </div>
            </div>

            <button class="destroy-button btn btn-large">
              <i class="icon-remove"></i>
              Usuń element
            </button>

          </div>
        </form>
      </div>
    </section>"""
  
  events: ->
    _.extend super,
      {'change .image-input': 'onImageChange'}
    
  open: ->
    super
    if @model.get('type') is 'image'
      @$('input[type=file]').click()

class SortableCollectionView extends CollectionView
  
  className: 'sortable-ui'
  
  events: ->
    {'sortstop': 'sort'}
  
  afterSort: (collection) ->
    
  sort: (event) =>
    # console.log 'sort stop', event
    $.when(@collection).then (collection) =>      
      @$('.sortable').each (index, element) =>
        # console.log '.sortable', element
        id = $(element).data('sortable-id')
        if model = collection.get(id)
          unless model.get('position') is index
            model.set({position: index})
            model.save()
      @afterSort collection
  
  render: ->
    super
    @$collection.sortable({})
    @$collection.disableSelection()
    @

class MenuCollectionView extends SortableCollectionView
  afterSort: (collection) ->
    collection.sort()

class GroupShowView extends SortableCollectionView
  
  titlePlaceholder: 'Tytuł nowego działu'
  labelAttribute: 'name'
  itemView: InformationElementView
  
  initialize: ->
    @collection = @model.getInformations()
    super
  
  actionsButtonGroupTemplate: -> ""
  
  events: ->
    _.extend super,
    { 'click #information-submit': 'save'
    , 'click .destroy': 'destroy'
    }
  
  persist: ->
    @model.set name: @$('#title-input').val()

  save: ->
    @persist()
    @model.save()

  destroy: ->
    @model.save({is_deleted: true})
    # @model.collection.remove @model
    # console.log 'before sort', @model.collection.pluck('position')
    @model.collection.sort()
    @model.collection?.remove @model
    # console.log 'after sort', @model.collection.pluck('position')
    app.navigate @navigateToAfterDelete, true
  
  template: -> """
    <div class="editable active" id="title-section">
      <div class="add-section edit">
        <form id="title-edit" action="">
          <input id="title-input" type="text" class="input-title add edit" placeholder="#{@titlePlaceholder}" autofocus="autofocus" value="{{ #{@labelAttribute} }}"/>
        </form>
      </div>

      <div id="title-show" class="category show">
        <h1 id="title">{{#if #{@labelAttribute} }}{{ #{@labelAttribute} }}{{else}}Nowa kategoria{{/if}}</h1>
      </div>
    </div>

    <div id="elements"></div>

    <div class="form-actions section">

      <div class="btn-toolbar pull-right">

        #{@actionsButtonGroupTemplate()}

        <div class="btn-group">
          <button id="information-submit" class="btn btn-large btn-primary top-level-actions">
            <i class="icon-ok icon-white"></i>
            Zapisz
          </button>
        </div>
      </div>

      <button class="destroy btn btn-large">
        <i class="icon-remove"></i>
        Usuń
      </button>
    </div>
    """

  render: ->
    @$el.html @template().render @model.toJSON()
    @$collection = @$('#elements')
    @$("[rel='tooltip']").tooltip({animation: false})
    super


class InformationGroupShowView extends GroupShowView
  
  navigateToAfterDelete: 'informations'
  
  events: ->
    _.extend super,
      'click .create-text': @createElement('text')
      'click .create-title': @createElement('title')
      'click .create-image': @createElement('image')
  
  createElement: (type) -> (event) =>
    event.preventDefault()
    $.when(@model.getInformations()).then (informations) =>
      informations.add({type, position: informations.newPosition(), information_group: @model.id})

  actionsButtonGroupTemplate: -> """
    <div class="btn-group">
      
      <button class="create-title btn btn-large" rel="tooltip" title="Dodaj tytuł">
        <i class="icon-bookmark"></i>
      </button>
      
      <button class="create-text btn btn-large" rel="tooltip" title="Dodaj tekst">
        <i class="icon-align-left"></i>
      </button>
      
      <button class="create-image btn btn-large" rel="tooltip" title="Dodaj obrazek">
        <i class="icon-picture"></i>
      </button>
      
    </div>
    """
     
################### CONTACTS ########################

class ContactElement extends StackMob.Model
  schemaName: 'contact_element'

  parse: (data) ->
    if typeof data is 'object'
      data
    else
      super
  
  @types: [
      {name: 'header', id: "200", icon: 'bookmark', add: 'nagłówek'}
    , {name: 'person', id: "100", icon: 'user', add: 'osobę'}
    , {name: 'address', id: "4", icon: 'home', add: 'adres'}
    , {name: 'phone', id: "1", icon: 'headphones', add: 'telefon'}
    , {name: 'email', id: "2", icon: 'envelope', add: 'email'}
    , {name: 'url', id: "3", icon: 'globe', add: 'stronę www'}
    , {name: 'text', id: "5", icon: 'pencil', add: 'własną etykietę'}
    ]
  
  setDefaultKey: ->
    unless @has 'key'
      @set key: switch @get('type')
        when "1" then 'telefon'
        when "2" then 'email'
        when "3" then 'www'
        when "4" then 'adres'
        when "5" then 'etykieta'
        else undefined
  
  initialize: ->
    @isOpen = not @id
    @setDefaultKey()
    super

class ContactElements extends InformationElements
  model: ContactElement

class ContactGroup extends InformationGroup
  schemaName: 'contact_group'
  collectionClass: ContactElements

class ContactGroups extends SortableCollection
  model: ContactGroup
  
  comparator: (model) ->
    model.get('location')

class ContactGroupView extends InformationGroupView

class ContactElementView extends InformationElementView
  
  modelId: 'contact_element_id'
  
  types: 
    "200": 'header1'
    "100": 'person'
    "5": 'text'
    "4": 'address'
    "3": 'url'
    "2": 'email'
    "1": 'phone'
  
  templateShow:
    "200": -> """<h3>{{ value }}"""
    "100": -> """<h4><i class="icon-user"></i> {{ value }}</h4>"""
    "5": -> """<p><span class="info-label"><i class="icon-pencil"></i> {{ key }}</span> {{ value }}</p>"""
    "4": -> """<p><span class="info-label"><i class="icon-home"></i> {{ key }}</span> {{ value }}</p>"""
    "3": -> """<p><span class="info-label"><i class="icon-globe"></i> {{ key }}</span> <a href="http://{{ value }}">{{ value }}</a></p>"""
    "2": -> """<p><span class="info-label"><i class="icon-envelope"></i> {{ key }}</span> <a href="mailto:{{ value }}">{{ value }}</a></p>"""
    "1": -> """<p><span class="info-label"><i class="icon-headphones"></i> {{ key }}</span> {{ value }}</p>"""
  
  templateEditWithKey = (placeholder) -> -> """
    <div class="row-fluid">
      <div class="span2">
        <input class="key add" type="text" placeholder="#{placeholder}" value="{{ key }}"/>
      </div>
      <div class="span10">
        <input class="value add" type="text" autofocus="autofocus" placeholder="" value="{{ value }}"/>
      </div>
    </div>
    """
  
  templateEditWithoutKey = (placeholder) -> ->
    """<input class="value add" type="text" autofocus="autofocus" placeholder="#{placeholder}" value="{{ value }}"/>"""
  
  templateEdit:
    "1": templateEditWithKey 'telefon'
    "2": templateEditWithKey 'email'
    "3": templateEditWithKey 'www'
    "4": templateEditWithKey 'adres'
    "5": -> """
      <div class="row-fluid">
        <div class="span2">
          <input class="key add" type="text" autofocus="autofocus" placeholder="etykieta" value="{{ key }}"/>
        </div>
        <div class="span10">
          <input class="value add" type="text" placeholder="" value="{{ value }}"/>
        </div>
      </div>
      """
    "100": templateEditWithoutKey 'Nazwa osoby lub jednostki'
    "200": templateEditWithoutKey 'Nazwa działu'
  
  persist: ->
    @model.set key: @$('.key').val(), value: @$('.value').val()
    @model.save()
    # console.log 'save'

class ContactGroupShowView extends GroupShowView

  titlePlaceholder: 'Tytuł nowego działu'
  labelAttribute: 'name'
  navigateToAfterDelete: 'contact'  
  itemView: ContactElementView

  creationEvents: ->
    events = {}
    _(ContactElement.types).each (type) =>
      events["click .create-#{type.name}"] = (event) =>
        event.preventDefault()
        $.when(@model.getInformations()).then (informations) =>
          # console.log 'informations', informations
          newPosition = informations.newPosition()
          # console.log 'newPosition', newPosition
          informations.create({type: type.id, position: newPosition, contact_group: @model.id})
    # console.log 'events', events
    events
  
  events: =>
    _.extend super, @creationEvents()

  actionsButtonGroupTemplate: -> """
    <div class="btn-group">
      
      {{#types}}
        <button class="create-{{name}} btn btn-large" rel="tooltip" title="Dodaj {{add}}">
          <i class="icon-{{icon}}"></i>
        </button>
      {{/types}}

      <!--
      <button class="btn btn-large dropdown-toggle" data-toggle="dropdown">
        <div class="caret"></div>
      </button>
      <ul class="dropdown-menu">
        {{#types}}
          <li>
            <a class="create-{{name}}" href="#"><i class="icon-{{icon}}"></i> Dodaj {{add}}</a>
          </li>
        {{/types}}
      </ul>
      -->
      
    </div>
    """.render {types: ContactElement.types}

################### PLACES ###################

class Place extends StackMob.Model
  schemaName: 'location'

class Places extends LoadableCollection
  model: Place
  
  parse: (response) ->
    _(response).reject (model) -> model.is_deleted

class PlaceView extends SelectableView

class PlaceShowView extends Backbone.View
  
  labelAttribute: 'name'
  titlePlaceholder: 'Nazwa nowego miejsca'
  
  template: -> """
    <div id="title-section">
      <div class="add-section">
        <form id="title-edit" action="">
          <input type="text" class="input-title add edit" placeholder="#{@titlePlaceholder}" autofocus="autofocus" value="{{ #{@labelAttribute} }}"/>
        </form>
      </div>
    </div>
    
    <div id="elements">
    </div>
    
    <section class="item">
      <form action="#" class="form-horizontal">
        <div class="row-fluid">
          <div class="span12">
            <div class="control-group">
              <label for="" class="control-label">Opis</label>
              <div class="controls"><textarea class="span12 input-description">{{ description }}</textarea></div>
            </div>
            <div class="control-group">
              <label for="" class="control-label">Szerokość geograficzna</label>
              <div class="controls"><input type="text" class="span6 input-latitude" value="{{ latitude }}" placeholder="51.110195"/></div>
            </div>
            <div class="control-group">
              <label for="" class="control-label">Długość geograficzna</label>
              <div class="controls"><input type="text" class="span6 input-longitude" value="{{ longitude }}" placeholder="17.031404"/></div>
            </div>
          </div>
        </div>
        
      </form>
    </section>
    
    
    <div id="elements"></div>
      
    <div class="form-actions section">
      
      <button class="destroy btn btn-large">
        <i class="icon-remove"></i>
        Usuń
      </button>
      
      <button class="save btn btn-large btn-primary pull-right">
        <i class="icon-ok icon-white"></i>
        Zapisz
      </button>
    </div>
    """
  
  events:
    'click .save': 'save'
    'click .destroy': 'destroy'
  
  initialize: ->
    @model.on 'change', @render
    @model.on 'reset', @render
  
  save: (e) =>
    e.preventDefault()
    # console.log 'save'
    attributes =
      name: @$('.input-title').val()
      description: @$('.input-description').val()
      latitude: Number(@$('.input-latitude').val())
      longitude: Number(@$('.input-longitude').val())
    @model.set attributes
    @trigger 'save', @model
  
  destroy: (e) =>
    e.preventDefault()
    # console.log 'destroy'
    @model.set is_deleted: true
    @trigger 'destroy', @model
  
  render: =>
    @$el.html @template().render @model.toJSON()
    @

################### RESTAURANTS ###################

class RestaurantUser extends StackMob.User
  
  defaults:
    role: "restaurant"
  
  validate: (attrs) ->
    return "role: restaurant" if attrs.role isnt "restaurant"
    return "Nazwa new zabroniona" if attrs.username is "new"

class RestaurantUsers extends LoadableCollection
  model: RestaurantUser
  
  parse: (response) ->
    _(response).reject (model) -> model.is_deleted or model.role isnt "restaurant"

class RestaurantUserView extends SelectableView
  labelAttribute: 'username'
  
  initialize: ->
    super
    @model.on 'sync', @render, @

class RestaurantUserShowView extends Backbone.View
  labelAttribute: 'username'
  titlePlaceholder: 'Nazwa nowej restauracji'
  
  template: -> """
    <div id="title-section">
      <div class="add-section">
        <input type="text" class="input-title add edit" {{#if #{@labelAttribute} }}disabled{{/if}} placeholder="#{@titlePlaceholder}" autofocus="autofocus" value="{{ #{@labelAttribute} }}"/>
      </div>
    </div>
    
    <section class="item row-fluid">
      <div class="span12 form-horizontal">
        <legend>
          Dedykowany użytkownik
          <small>mogący aktualizować dane teleadresowe i menu</small>
        </legend>
        <div class="control-group">
          <label for="" class="control-label">Identyfikator</label>
          <div class="controls"><input type="text" disabled class="span12 input-username" value="{{ #{@labelAttribute} }}"/></div>
        </div>
        
        <div class="control-group">
          <label for="" class="control-label">Hasło</label>
          <div class="controls"><input type="password" class="span12 input-password"/></div>
        </div>
      
        <div class="control-group">
          <label for="" class="control-label">Hasło ponownie</label>
          <div class="controls"><input type="password" class="span12 input-password-confirmation"/></div>
        </div>
        
        
      </div>
    </section>
      
    <div class="form-actions section">
      
      <button class="destroy btn btn-large">
        <i class="icon-remove"></i>
        Usuń
      </button>
      
      <button class="save btn btn-large btn-primary pull-right">
        <i class="icon-ok icon-white"></i>
        Zapisz
      </button>
    </div>
    """
  
  events:
    'click .save': 'save'
    'click .destroy': 'destroy'
    'keyup .input-title': 'updateName'

  initialize: ({@user}) ->
    @model.on 'change', @render
    @model.on 'reset', @render
    
  
  updateName: (e) =>
    @$('.input-username').val(@$('.input-title').val())  
  
  save: (e) =>
    e.preventDefault()
    # console.log 'save'
    
    if @model.isNew()
      username = @$('.input-title').val()
      unless username
        alert('Musisz podać nazwę restauracji')
        @$('.input-title').focus()
        return
    else
      username = @model.get('username')
      # oldPassword = @$('.input-password-old').val()
      # alert('Musisz podać stare hasło')
      # @$('.input-password-old').focus()
      # return
      
    password = @$('.input-password').val()
    unless password
      alert('Musisz podać hasło użytkownika')
      @$('.input-password').focus()
      return
    passwordConfirmation = @$('.input-password-confirmation').val()
    if password isnt passwordConfirmation
      alert('Oba hasła muszą być jednakowe')
      @$('.input-password-confirmation').focus()
      return
    
    @model.set {username, password}
    
    @trigger 'save', @model, username, password

  destroy: (e) =>
    e.preventDefault()
    @trigger 'destroy', @model
  
  render: =>
    @$el.html @template().render @model.toJSON()
    @


################### Admin Router ###################

class App extends Backbone.Router
  
  routes:
    '': 'index'
    'notifications': 'notifications'
    'surveys': 'surveys'
    'surveys/new': 'newSurvey'
    'surveys/:id': 'showSurveyById'
    'informations': 'informations'
    'informations/:id': 'informations'
    'map': 'map'
    'map/:id': 'map'
    'restaurants': 'restaurants'
    'restaurants/:id*': 'restaurants'
    'contact': 'contact'
    'contact/:id': 'contact'
   
  initialize: ->
    @on 'all', @updateLinks
    @$main = $('body')
    
    @Notifications = new Notifications()
    
    @Surveys = new Surveys()
    @Surveys.on 'new', => @navigate '/surveys/new', true
    @Surveys.on 'show', @onSelectSurvey
    @Surveys.on 'publish', (model) =>
      @Surveys.add model
      @navigate "/surveys/#{model.id}", true
    
    @InformationGroups = new InformationGroups()
    @InformationGroups.on 'select', (model) =>
      @navigate "/informations/#{model.id}", true
    
    @ContactGroups = new ContactGroups()
    @ContactGroups.on 'select', (model) =>
      @navigate "/contact/#{model.id}", true
    
    @Places = new Places()
    @Places.on 'select', (model) =>
      @navigate "/map/#{model.id}", true
    
    @RestaurantUsers = new RestaurantUsers()
    @RestaurantUsers.on 'select', (model) =>
      @navigate "/restaurants/#{model.id}", true
  
  onSelectSurvey: (model) =>
    @Surveys.active = model
    @navigate "/surveys/#{model.id or model.cid}"
    @showSurvey(model)
  
  setView: (view) ->
    @$main.html(view.render().el)
    @updateLinks()
  
  notifications: ->
    @setView new NotificationsView({collection: @Notifications.load()})
    @Notifications.fetch()
  
  surveys: ->
    collection = @Surveys
    collection.active = null
    listView = new CollectionView({collection: collection.load(), itemView: SurveyView})
    addView = new AddView({collection, placeholder: 'Tytuł nowej ankiety'})
    view = new MenuLayout({title: 'Ankiety', listView, addView})
    @setView view
  
  newSurvey: ->
    model = new Survey()
    collection = @Surveys
    collection.active = model
    # $.when(@Surveys.load()).then (collection) =>
    #   collection.add model
    mainView = new SurveyEditView({model})
    listView = new CollectionView({collection, itemView: SurveyView, active: model})
    view = new SidebarLayout({title: 'Ankiety', backLink: '#/surveys', mainView, listView})
    @setView view
    collection.load()
    mainView.openTitle()
    
  showSurvey: (model) => 
    window.model = model 
    collection = @Surveys
    # console.log 'showSurvey', model
    mainView = if model.id? then new SurveyShowView({model}) else new SurveyEditView({model})
    listView = new CollectionView({collection, itemView: SurveyView})
    view = new SidebarLayout({title: 'Ankiety', backLink: '#/surveys', mainView, listView})
    @setView view
    # @Surveys.load()
    # model.getQuestions()
  
  showSurveyById: (id) =>
    # console.log 'showSurveyById', id
    $.when(@Surveys.load()).then (collection) =>
      model = collection.get(id) or collection.getByCid(id)
      # console.log 'showSurveyById', model
      if model?
        @showSurvey model
      else
        @navigate '/surveys', true
  
  informations: (id) =>
    collection = @InformationGroups
    
    listView = new MenuCollectionView({collection: collection.load(), itemView: InformationGroupView})
    
    if id? # pokaż dany element
      if id is 'new'
        $.when(collection.load()).then (collection) =>
          window.model = model = collection.createNew()
          collection.add model
          model.save {}, success: =>
            # mainView = new InformationGroupShowView({model})
            # view = new SidebarLayout({title: 'Informacje', backLink: '#/informations', mainView, listView})
            # @setView view
            @navigate "/informations/#{model.id}", true
      else
        $.when(collection.load()).then (collection) =>
          if window.model = model = collection.get(id)
            # console.log 'existing information', model
            mainView = new InformationGroupShowView({model})
            view = new SidebarLayout({title: 'Informacje', backLink: '#/informations', mainView, listView})
            @setView view
          else
            console.warn "Nie ma elementu o identyfikatorze #{id}. Przekierowuję do listy elementów."
            @navigate '/informations', true
    else # pokaż listę elementów
      addView = new AddView({collection, placeholder: 'Tytuł nowego działu'})
      addView.on 'click', =>
        @navigate('informations/new', true)
      view = new MenuLayout({title: 'Informacje', listView, addView})
      # console.log 'info'
      @setView view
      collection.load()
  
  contact: (id) =>
    collection = @ContactGroups

    listView = new SortableCollectionView({collection: collection.load(), itemView: ContactGroupView})

    if id? # pokaż dany element
      if id is 'new'
        $.when(collection.load()).then (collection) =>
          window.model = model = new ContactGroup()
          collection.add model
          model.save {}, success: =>
            @navigate "/contact/#{model.id}", true
      else
        $.when(collection.load()).then (collection) =>
          if window.model = model = collection.get(id)
            mainView = new ContactGroupShowView({model})
            view = new SidebarLayout({title: 'Kontakt', backLink: '#/contact', mainView, listView})
            @setView view
          else
            console.warn "Nie ma elementu o identyfikatorze #{id}. Przekierowuję do listy elementów."
            @navigate '/contact', true
    else # pokaż listę elementów
      addView = new AddView({collection, placeholder: 'Tytuł nowego działu'})
      addView.on 'click', =>
        @navigate('contact/new', true)
      view = new MenuLayout({title: 'Kontakt', listView, addView})
      @setView view
      collection.load()
    
  map: (id) =>
    collection = @Places

    listView = new CollectionView({collection: collection.load(), itemView: PlaceView})
    
    if id is "new" # utwórz nowy element
      model = new Place()
      mainView = new PlaceShowView({model})
      view = new SidebarLayout({title: 'Mapa', backLink: '#/map', mainView, listView})
      @setView view
      mainView.on 'save', (model) =>
        collection.create model
      mainView.on 'destroy', (model) =>
        @navigate "/map", true
      model.on 'sync', =>
        @navigate "/map/#{model.id}", true
    else if id? # pokaż dany element
      $.when(collection.load()).then (collection) =>
        if model = collection.get(id)
          # console.log 'existing place', model
          mainView = new PlaceShowView({model})
          mainView.on 'save', (model) =>
            model.save()
          mainView.on 'destroy', (model) =>
            model.save()
            collection.remove(model)
            @navigate "/map", true
          view = new SidebarLayout({title: 'Mapa', backLink: '#/map', mainView, listView})
          @setView view
        else
          console.warn "Nie ma elementu o identyfikatorze #{id}. Przekierowuję do listy elementów."
          @navigate '/map', true
    else # pokaż listę elementów
      addView = new AddView({collection, placeholder: 'Nazwa nowego miejsca'})
      addView.on 'click', => @navigate '/map/new', true
      view = new MenuLayout({title: 'Mapa', listView, addView})
      @setView view
      collection.load()
  
  restaurants: (id) =>
    
    # id = id.fromURL()
    
    collection = @RestaurantUsers
    
    title = "Restauracje"
    
    placeholder = "Nazwa nowej restauracji"
    
    path = "/restaurants"
    
    ShowView = RestaurantUserShowView
    
    MenuItemView = RestaurantUserView
    
    listView = new CollectionView({collection: collection.load(), itemView: MenuItemView})

    if id is "new" # utwórz nowy element
      model = new RestaurantUser({username: undefined})
      mainView = new ShowView({model, collection})
      view = new SidebarLayout({title, backLink: "##{path}", mainView, listView})
      @setView view
      mainView.on 'save', (model) =>
        collection.create model
      mainView.on 'destroy', (model) =>
        #TODO delete restaurant as well
        model.destroy()
        @navigate path, true
      model.on 'sync', =>
        @navigate "#{path}/#{model.id.toURL()}", true
            
    else if id? # pokaż dany element
      $.when(collection.load()).then (collection) =>
        if model = collection.get(id)
          mainView = new ShowView({model})
          mainView.on 'save', (model, username, password) =>
            model.destroy success: =>
              collection.create {username, password}, success: =>
                # console.log 'after creation'
                @navigate "#{path}/#{model.id.toURL()}", true
              
          mainView.on 'destroy', (model) =>
            # collection.remove model
            model.destroy()
            @navigate path, true
            #TODO usunięcie restauracji
            $.when(@Restaurants.load()).then (restaurants) =>
              if restaurant = restaurants.find((r) -> r.get('name') is model.id)
                restaurant.save({is_deleted: true})
            
          view = new SidebarLayout({title, backLink: "##{path}", mainView, listView})
          @setView view
        else
          console.warn "Nie ma elementu o identyfikatorze #{id}. Przekierowuję do listy elementów."
          @navigate path, true
    else # pokaż listę elementów
      addView = new AddView({collection, placeholder})
      addView.on 'click', => @navigate "#{path}/new", true
      view = new MenuLayout({title, listView, addView})
      @setView view
    
    collection.load()
  
  index: ->
    @navigate '/notifications', true
    
  updateLinks: =>
    hash = window.location.hash
    unless hash.startsWith('#/')
      hash = '#/' + hash[1..]
    $("a[href].link").each ->
      href = $(@).attr('href')
      active = hash is href or hash.startsWith(href) and hash.charAt(href.length) is '/'
      $(@).parent().toggleClass 'active', active
    
    $("[data-id]").each ->
      parts = hash.split('/')
      id = parts[parts.length-1]
      $el = $(@)
      $el.toggleClass 'active', $el.data('id') is id

############################### Restaurant Router ###############################
  

class Restaurant extends ModelWithImage
  schemaName: 'restaurant'
  
  # defaults:
  #   image_url: '/img/restaurant.png'
  #   image_width: 122
  #   image_height: 124

class Restaurants extends StackMob.Collection
  model: Restaurant
  
  getById: (id, callback) ->
    q = new Restaurants.Query()
    q.equals('restaurant_id', id)
    @query q
    , success: (collection) =>
      callback(null, collection.first())
    , error: (e) =>
      callback(e)

class MenuItem extends ModelWithImage
  schemaName: 'menu_item'
  
  # defaults:
  #   image_url: '/img/menu-item.png'
  #   image_width: 88
  #   image_height: 88

class MenuItems extends StackMob.Collection
  model: MenuItem
  
  parse: (response) ->
    _(response).reject (model) -> model.is_deleted
  
  comparator: (menuItem) ->
    a = (if menuItem.get('is_featured') then -1000 else 0) + menuItem.get('price')
    a
  
  defaults:
    is_featured: false
  
  getByRestaurantId: (id, callback) ->
    q = new MenuItems.Query()
    q.equals('restaurant', id)
    @query q
    , success: (collection) =>
      callback(null, collection)
    , error: (e) =>
      callback(e)

class RestaurantMenuItemView extends View
  template: -> """
    <section class="menu-item editable {{#if name}} {{else}} active {{/if}}">
      <div class="configurable show">
        <h3>
          {{#if is_featured}}
            <i class="icon-star"></i>
          {{/if}}
          {{ name }}
          <small>{{ price }} zł</small>
        </h3>
        <p>{{ description }}</p>
      </div>
      <div class="row-fluid edit">
        <form class="span12 item compact-bottom">
          
          <div class="control-group">
            <label for="" class="control-label"></label>
            <div class="controls">
              <img class="image-preview" src="{{ image_url }}"/>
            </div>
          </div>
        
          <div class="control-group">
            <label for="" class="control-label">Zdjęcie</label>
            <div class="controls">
              <input type="file" class="input-image" name="image" />
            </div>
          </div>
        
          <div class="control-group">
            <label for="" class="control-label">Nazwa</label>
            <div class="controls"><input type="text" class="span12 input-name" value="{{ name }}"/></div>
          </div>
          
          <div class="control-group">
            <label for="" class="control-label">Cena</label>
            <div class="controls"><input type="text" class="span12 input-price" value="{{ price }}" placeholder="9.99"/></div>
          </div>
          
          <div class="control-group">
            <label for="" class="control-label">Opis</label>
            <div class="controls">
              <textarea rows="3" class="span12 input-description">{{ description }}</textarea>
            </div>
          </div>
          
          <div class="control-group">
            <label for="" class="control-label"><i class="icon-star"></i> Polecane</label>
            <div class="controls">
                <input type="checkbox" class="span12 input-featured" {{#if is_featured}}checked{{/if}}/>
            </div>
          </div>
          
          <div class="form-actions compact">
            <button class="btn btn-primary btn-large save pull-right">
              <i class="icon-ok icon-white"></i>
              Zapisz
            </button>
            <button class="btn btn-large destroy">
              <i class="icon-remove"></i>
              Usuń
            </button>
          </div>
          
        </form>
      </div>
    </section>
  """
  
  initialize: ->
    @model.on 'sync', @onSync
  
  events:
    'click .show': 'edit'
    'click .save': 'save'
    'submit form': 'save'
    'click .destroy': 'destroy'
    'change .input-image': 'onImageChange'
  
  onSync: (e) =>
    # console.log 'onSync in menu item view'
    @$('section').removeClass('waiting')
    @render()
    
  edit: (e) =>
    @$('section').addClass 'active'
  
  show: (e) =>
    @$('section').removeClass 'active'
  
  save: (e) =>
    # console.log 'save'
    e.preventDefault()
    e.stopPropagation()
    @model.set
      name: @$('.input-name').val()
      description: @$('.input-description').val()
      price: Number(@$('.input-price').val())
      is_featured: !! @$('.input-featured').attr('checked')
      restaurant: @options.restaurant
    @model.save {},
      success: =>
        @onSync()
      error: =>
        alert('Aktualizacja nie powiodła się, spróbuj ponownie później')
        @$('section').removeClass 'active'
    @$('section').addClass('waiting')
  
  destroy: (e) =>
    e.preventDefault()
    @model.set is_deleted: true
    @model.save()
    @remove()
    @collection.remove @model
  
  initialize: ->
    @model.on 'save', @render
  
  render: =>
    # console.log 'is_featured', @model.get('is_featured')
    @$el.html @template().render @model.toJSON()
    @

class RestaurantView extends CollectionView
  
  itemView: RestaurantMenuItemView
  
  getImagePreview: ->
    @$('.restaurant-image-preview')
  
  template: -> """
    {{{ restaurantNavbar }}}
    
    <div class="container">
      
      <div class="row">
        <div class="span6">
            <div class="category">
              <h1>
                {{ name }}
                <small>Informacje o restauracji</small>
              </h1>
            </div>
          <form id="restaurant-info-form">
          
            <section class="row-fluid item restaurant-form-section">
              <div class="span12 form-horizontal">
                
                <div class="control-group">
                  <label for="" class="control-label"></label>
                  <div class="controls">
                    <img class="restaurant-image-preview" src="{{ image_url }}"/>
                  </div>
                </div>
                
                <div class="control-group">
                  <label for="" class="control-label">Zdjęcie</label>
                  <div class="controls">
                    <input type="file" class="restaurant-input-image" name="image" />
                  </div>
                </div>
                
                <div class="control-group">
                  <label for="" class="control-label">Nazwa</label>
                  <div class="controls">
                    <input type="text" disabled class="span12" value="{{ name }}"/>
                  </div>
                </div>

                <div class="control-group">
                  <label for="" class="control-label">Adres</label>
                  <div class="controls">
                    <input type="text" class="span12 input-address" value="{{ address }}"/>
                  </div>
                </div>
              
                <div class="control-group">
                  <label for="" class="control-label">Telefon</label>
                  <div class="controls">
                    <input type="text" class="span12 input-phone" value="{{ phone }}"/>
                  </div>
                </div>
              
                <div class="control-group">
                  <label for="" class="control-label">Strona www</label>
                  <div class="controls">
                    <input type="text" class="span12 input-url" value="{{ url }}"/>
                  </div>
                </div>
              
              </div>
            </section>
            
            <div class="form-actions section">
              <button class="btn btn-primary btn-large pull-right save">
                <i class="icon-ok icon-white"></i>
                Zapisz
              </button>
            </div>
            
          </form>
        </div>
        <div class="span6">
          <div class="category">
            <h1>
              Menu
            </h1>
          </div>
          
          <div id="menu" class="clearfix">
            <section class="item">
              Brak pozycji menu
            </section>
          </div>          
          <div class="form-actions section">
            <button class="btn btn-primary btn-large pull-right create">
              <i class="icon-plus icon-white"></i>
              Dodaj do menu
            </button>
          </div>
        </div>
      </div>
      <!-- {{{footer}}} -->
    </div>"""
  
  initialize: ->
    @model.on 'reset', @render
    @model.on 'sync', @render
    window.model = @model
    super
    
  events:
    'click .save': 'save'
    'submit #restaurant-info-form': 'save'
    'click .create': 'create'
    'change .restaurant-input-image': 'onImageChange'
  
  save: (e) =>
    # console.log 'save'
    @$('.restaurant-form-section').addClass('waiting')    
    e.preventDefault()
    # console.log 'save'
    @model.set
      address: @$('.input-address').val()
      phone: @$('.input-phone').val()
      url: @$('.input-url').val()
    # @model.beforeSave()
    @model.save()
  
  create: (e) =>
    e.preventDefault()
    # console.log '@collection', @collection
    @collection.create new MenuItem
  
  render: =>
    @$el.html @template().render @model.toJSON()
    @$collection = @$('#menu')
    # console.log @$collection
    super
  
$ ->
  window.globals = {}
  
  $("[rel='tooltip']").tooltip()
  
  displayRestaurantPanelById = (id, user) ->
    new Restaurants().getById id, (error, model) =>
      if error
        console.error "Nie mogę ściągnąć restauracji o id #{id}", error
      else
        unless model
          model = new Restaurant({restaurant_id: id, name: id})
          model.create()
        new MenuItems().getByRestaurantId id, (e, collection) ->
          if e
            console.error "Nie mogę ściągnąć menu dla restauracji o id #{id}", e
          else
            view = new RestaurantView({model, collection, restaurant: id})
            $('body').html view.render().el
  
  bazylia = off
  auth = on
  
  if bazylia
    window.globals.current_user = "Bazylia"
    displayRestaurantPanelById 'Bazylia', new User({username: "Bazylia", role: "restaurant", restaurant: "Bazylia"})
  else  
    if auth
      loginView = new LoginView()
      $('body').html loginView.render().el
      loginView.on 'login', (user) ->
        window.globals.current_user = user.get('username')
        # console.log 'login', user
        user.fetch success: =>
          if user.get('role') is "restaurant"
            id = user.id
            displayRestaurantPanelById id, user
          else # admin
            window.app = new App({user})
            Backbone.history?.start()
    else
      window.app = new App()
      Backbone.history?.start()
    