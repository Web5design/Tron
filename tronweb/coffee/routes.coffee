
# Routes

class TronRoutes extends Backbone.Router

    routes:
        "home":             "home"
        "jobs(;*params)":   "jobs"
        "job/:name":        "job"
        "job/:name/:run":   "jobrun"
        "services":         "services"
        "service/:name":    "service"
        "configs":          "configs"
        "config/:name":     "config"

    updateMainView: (model, view_type) ->
        view = new view_type(model: model)
        model.fetch()
        mainView.render(view)

    home: ->
        @updateMainView(new Dashboard(), DashboardView)

    configs: ->
        @updateMainView(new NamespaceList(), NamespaceListView)

    config: (name) ->
        @updateMainView(new Config(name: name), ConfigView)

    services: ->
        refreshModel = new RefreshModel()
        @updateMainView(new ServiceCollection(refresh: refreshModel), ServiceListView)

    service: (name) ->
        @updateMainView(new Service(name: name), ServiceView)

    jobs: (params) ->
        params = getParamsMap(params)
        refreshModel = new RefreshModel()
        collection = new JobCollection(refresh: refreshModel, nameFilter: params.nameFilter)
        @updateMainView(collection, JobListView)

    job: (name) ->
        refreshModel = new RefreshModel()
        @updateMainView(new Job(name: name, refresh: refreshModel), JobView)

    jobrun: (name, run) ->
        refreshModel = new RefreshModel()
        @updateMainView(new JobRun(name: name, run_num: run, refresh: refreshModel), JobRunView)


class MainView extends Backbone.View

    el: $("#main")

    render: (item) =>
        @trigger('closeView')
        breadcrumbView.clear()
        @$el.html(item.el)

    clear: =>
        breadcrumbView.clear()
        @$el.empty()


getParamsMap = (paramString) ->
    paramString = paramString || ""
    _.mash((param.split('=') for param in paramString.split(';')))


getLocationParams = ->
    parts = document.location.hash.split(';', 1)
    [parts[0], getParamsMap(parts[1])]


buildLocationString = (base, params) ->
    params = (pair.join('=') for pair in _.pairs(params)).join(';')
    "#{ base };#{ params }"


window.updateLocationParam = (name, value) ->
    [base, params] = getLocationParams()
    params[name] = value
    routes.navigate(buildLocationString(base, params))


$(document).ready ->

    window.routes = new TronRoutes()
    window.mainView = new MainView()
    window.breadcrumbView = new BreadcrumbView()
    Backbone.history.start(root: "/web/")
