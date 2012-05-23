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
    @template()(data)

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
            <li>
              <a class="link" href="{{href}}">{{label}}</a>
            </li>
          {{/links}}
        </ul>
      </div>
    </div>
  </div>
</div>
"""

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
<footer class="hidden-phone">
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
  {{{footer}}}
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

################### BACKBONE EXTENSIONS ###################

class CollectionView extends Backbone.View
  initialize: ->
    console.log 'CollectionView initialized'
    
    @itemView or= @options.itemView
    $.when(@collection).then (collection) =>
      console.log 'collection', collection
      collection.on 'reset', @addAll
      collection.on 'add', @addAll
      collection.on 'remove', @addAll

  addAll: =>
    $collection = @$collection or @$el
    $.when(@collection).then (collection) =>
      $collection.empty()
      collection.each @addOne

  addOne: (model) =>
    options = _.extend(_.clone(@options), {model, @collection})
    view = new @itemView options
    $collection = @$collection or @$el
    if @options.prepend?
      $collection.prepend view.render().el
    else
      $collection.append view.render().el

  render: ->
    console.log 'CollectionView rendered', @
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
            <div class="span12 empty">...</div>
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
    

################### NOTIFICATIONS ###################

class Notification extends StackMob.Model
  schemaName: 'notification'
  
  @maxLength: 200
  
  @maxDisplayLength: 100
  

class Notifications extends StackMob.Collection
  model: Notification

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
          <textarea name="" id="new-notification-input" rows="1" class="add" placeholder="Nowe powiadomienie"></textarea>
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
    StackMob.customcode 'broadcast'
      , {content}
      , success: =>
        console.log 'broadcast sent'
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
    console.log 'survey validation, title:', title
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
    

class Surveys extends StackMob.Collection
  model: Survey
  
  load: ->
    unless @fetchPromise?
      @fetchPromise = $.Deferred()
      @fetch success: =>
        @fetchPromise.resolve(@)
    @fetchPromise
  
class Question extends StackMob.Model
  schemaName: 'question'
  
  validate: (attrs) ->  
  
  defaults:
    type: "1"
    content: ''
    answers: ''

class Questions extends StackMob.Collection
  model: Question
  
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
    <div class="survey selectable span4 {{#if active}}active{{/if}}">
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
    @collection.on 'show', @onSelect
  
  onSelect: =>
    @render()

  select: ->
    @collection.trigger 'show', @model
  
  render: =>
    $.when(@collection).then (collection) =>
      active = collection.active and ((@model.id and collection.active.id is @model.id) or (collection.active.cid is @model.cid))
      @$el.html @template.render _.extend(@model.toJSON(), {active})
      console.log 'render survey view', collection.active
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
    console.log 'onEdit'
    if model is @model
      @open()
    else
      console.log 'edit another question'
      @persist()
      if @model.get('content').length > 0
        console.log 'has content -> save'
        @save()
      else
        console.log 'no content -> destroy'
        @model.destroy()
  
  onDestroy: =>
    @remove()
  
  destroy: (e) =>
    e.preventDefault()
    console.log 10
    @model.collection.trigger 'close'
    @model.destroy() 
  
  save: (event) =>
    event?.preventDefault?()
    console.log 'save'
    @persist()
    if @model.get('content').length > 0
      console.log 'has content'
      @close()
      @model.collection.trigger 'close'
    else
      console.log "doesn't have content"
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
    "[" + answersArray.join(",") + "]"

  deserializeAnswers: (answersSerialized) ->
    answersSerialized[1...-1].split(',')
    
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
  
  template: """
    <div class="item">
      <h3>
        <i class="icon-{{icon}}"></i>
        {{ content }}
      </h3>
    </div>
    <div class="row">
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
    </div>"""
  
  icons:
    '1': 'star'
    '2': 'hand-right'
    '3': 'check'
    '4': 'comment'
  
  serializeAnswers: (answersArray) ->
    "[" + answersArray.join(",") + "]"

  deserializeAnswers: (answersSerialized) ->
    answersSerialized[1...-1].split(',')
  
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
    @$el.html @template.render @data()
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
      console.log 'questions of survey', @model, collection
    super
  
  render: ->
    @$el.html @template.render @model.toJSON()
    @$collection = @$('#questions')
    super
    console.log '@$collection', @$collection
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
      
      <button id="survey-submit" class="btn btn-large btn-primary pull-right top-level-actions">
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
    console.log 'on set ttitle'
    collection = window.app.Surveys
    unless collection.include @model
      collection.add @model
  
  onSync: =>
    # $.when(@collection).then (collection) =>
    window.app.Surveys.trigger 'publish', @model
  
  publish: (e) =>
    e?.preventDefault()
    console.log 'publish'
    @model.save()
  
  destroy: (e) =>
    e.preventDefault()
    console.log 'destroy'
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
      # $.when(@collection).then (collection) =>
      #   if collection.length > 0
      #     collection.trigger 'close'
      #   else
      #     question = new Question
      #     collection.add question
      #     collection.trigger 'edit', question

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



################### LOGIN ########################

class User extends StackMob.User
  

class LoginView extends Backbone.View
  
  template: """<div class="container" id="login">
      <form action="POST" class="form-horizontal">
      <div class="modal" style="position: relative; top: auto; left: auto; margin: 0 auto; z-index: 1; max-width: 100%;">
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
    </div>"""
  
  events:
    submit: 'submit'
  
  submit: (e) =>
    console.log "submited"
    e.preventDefault()
    $('#login-button').button('toggle')
    user = new User({username: @$('#login-input').val(), password: @$('#password-input').val()})
    user.login false,
      success: (u) =>
        $('#login-button').button('toggle')
        @trigger 'login', user
      error: (u, e) =>
        @$('.control-group').addClass('error')
        $('#login-button').button('toggle')
  
  render: ->
    @$el.html @template.render()
    @$('#login-input').focus()
    @


################### PAGE ROUTER ###################

class App extends Backbone.Router
  
  routes:
    '': 'index'
    'notifications': 'notifications'
    'surveys': 'surveys'
    'surveys/new': 'newSurvey'
    'surveys/:id': 'showSurveyById'
   
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
  
  onSelectSurvey: (model) =>
    @Surveys.active = model
    @navigate "/surveys/#{model.id or model.cid}"
    @showSurvey(model)
  
  setView: (view) ->
    @$main.html(view.render().el)
    @updateLinks()
  
  notifications: ->
    @setView new NotificationsView({collection: @Notifications})
    @Notifications.fetch()
  
  surveys: ->
    collection = @Surveys
    collection.active = null
    listView = new CollectionView({collection, itemView: SurveyView, prepend: true})
    addView = new AddView({collection, placeholder: 'Tytuł nowej ankiety'})
    view = new MenuLayout({title: 'Ankiety', listView, addView})
    @setView view
    collection.load()
  
  newSurvey: ->
    model = new Survey()
    collection = @Surveys
    collection.active = model
    # $.when(@Surveys.load()).then (collection) =>
    #   collection.add model
    mainView = new SurveyEditView({model})
    listView = new CollectionView({collection, itemView: SurveyView, prepend: true, active: model})
    view = new SidebarLayout({title: 'Ankiety', backLink: '#/surveys', mainView, listView})
    @setView view
    collection.load()
    mainView.openTitle()
    
  showSurvey: (model) =>  
    collection = @Surveys
    console.log 'showSurvey', model
    mainView = if model.id? then new SurveyShowView({model}) else new SurveyEditView({model})
    listView = new CollectionView({collection, itemView: SurveyView, prepend: true})
    view = new SidebarLayout({title: 'Ankiety', backLink: '#/surveys', mainView, listView})
    @setView view
    # @Surveys.load()
    # model.getQuestions()
  
  showSurveyById: (id) =>
    console.log 'showSurveyById', id
    $.when(@Surveys.load()).then (collection) =>
      model = collection.get(id) or collection.getByCid(id)
      console.log 'showSurveyById', model
      if model?
        @showSurvey model
      else
        @navigate '/surveys', true
  
  index: ->
    @navigate '/notifications', true
    
  updateLinks: =>
    hash = window.location.hash
    console.log 'hash', hash
    unless hash.startsWith('#/')
      hash = '#/' + hash[1..]
    console.log 'hash', hash
    $("a[href].link").each ->
      href = $(@).attr('href')
      active = hash is href or hash.startsWith(href) and hash.charAt(href.length) is '/'
      $(@).parent().toggleClass 'active', active

$ ->
  
  auth = on
  
  if auth
    loginView = new LoginView()
    $('body').html loginView.render().el
    loginView.on 'login', (user) ->
      console.log 'login', user
      window.app = new App({user})
      Backbone.history?.start()
  else
    window.app = new App()
    Backbone.history?.start()
    