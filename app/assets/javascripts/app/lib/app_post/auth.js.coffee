class App.Auth

  @login: (params) ->
    App.Log.notice 'Auth', 'login', params
    App.Ajax.request(
      id:     'login'
      type:   'POST'
      url:    App.Config.get('api_path') + '/signin'
      data:   JSON.stringify(params.data)
      success: (data, status, xhr) =>

        # set login (config, session, ...)
        @_login(data)

        # execute callback
        params.success(data, status, xhr)

      error: (xhr, statusText, error) =>
        @_loginError()
        params.error(xhr, statusText, error)
    )

  @loginCheck: ->
    App.Log.notice 'Auth', 'loginCheck'
    App.Ajax.request(
      id:    'login_check'
      async: false
      type:  'GET'
      url:   App.Config.get('api_path') + '/signshow'
      success: (data, status, xhr) =>

        # set login (config, session, ...)
        @_login(data, 'check')

      error: (xhr, statusText, error) =>
        @_loginError()
    )

  @logout: ->
    App.Log.notice 'Auth', 'logout'
    App.Ajax.request(
      id:   'logout'
      type: 'DELETE'
      url:  App.Config.get('api_path') + '/signout'
      success: =>

        # set logout (config, session, ...)
        @_logout()

      error: (xhr, statusText, error) =>
        @_loginError()
    )

  @_login: (data, type) ->
    App.Log.notice 'Auth', '_login:success', data

    # if session is not valid
    if data.error

      # update config
      for key, value of data.config
        App.Config.set( key, value )

      # empty session
      App.Session.init()

      # rebuild navbar with new navbar items
      App.Event.trigger( 'auth' )
      App.Event.trigger( 'auth:logout' )
      App.Event.trigger( 'ui:rerender' )

      return false;

    # clear local store
    if type isnt 'check'
      App.Event.trigger( 'clearStore' )

    # set avatar
    data.session.image = App.Config.get('api_path') + '/users/image/' + data.session.image

    # update config
    for key, value of data.config
      App.Config.set( key, value )

    # store user data
    for key, value of data.session
      App.Session.set( key, value )

    # refresh default collections
    if data.collections
      App.Event.trigger 'resetCollection', data.collections

    # trigger auth ok with new session data
    App.Event.trigger( 'auth', data.session )

    # init of i18n
    preferences = App.Session.get( 'preferences' )
    if preferences && preferences.locale
      locale = preferences.locale
    if !locale
      locale = window.navigator.userLanguage || window.navigator.language || 'en'
    App.i18n.set( locale )

    App.Event.trigger( 'auth:login', data.session )
    App.Event.trigger( 'ui:rerender' )


  @_logout: (data) ->
    App.Log.notice 'Auth', '_logout'

    # empty session
    App.Session.init()

    App.Event.trigger( 'auth' )
    App.Event.trigger( 'auth:logout' )
    App.Event.trigger( 'ui:rerender' )
    App.Event.trigger( 'clearStore' )

  @_loginError: (xhr, statusText, error) ->
    App.Log.notice 'Auth', '_loginError:error'

    # empty session
    App.Session.init()

    # rebuild navbar
    App.Event.trigger( 'auth' )
    App.Event.trigger( 'auth:logout' )
    App.Event.trigger( 'ui:rerender' )
    App.Event.trigger( 'clearStore' )

