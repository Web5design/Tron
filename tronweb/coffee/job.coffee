

# Jobs


class window.Job extends Backbone.Model

    initialize: (options) =>
        super options
        options = options || {}
        @refresh = options.refresh

    idAttribute: "name"

    urlRoot: "/jobs"


class window.JobCollection extends Backbone.Collection

    initialize: (options) =>
        super options
        options = options || {}
        @refresh = options.refresh
        @nameFilter = options.nameFilter

    model: Job

    url: "/jobs"

    parse: (resp, options) =>
        resp['jobs']


class window.JobRun extends Backbone.Model

    initialize: (options) =>
        super options
        options = options || {}
        @refresh = options.refresh

    idAttribute: "run_num"

    urlRoot: ->
        "/jobs/" + @get('name')


class ActionRun extends Backbone.Model

    idAttribute: "action_name"

    # TODO: urlRoot: ->


class window.JobListView extends Backbone.View

    initialize: (options) =>
        @listenTo(@model, "sync", @render)
        @refreshView = new RefreshToggleView(model: @model.refresh)
        @listenTo(@refreshView.model, 'refresh', => @model.fetch())

    tagName: "div"

    className: "span12"

    template: _.template '
        <h1>Jobs</h1>
        <div id="filter-bar" class="row"></div>
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>Name</td>
                    <th>Schedule</td>
                    <th>Node Pool</td>
                    <th>Last Success</td>
                    <th>Next Run</td>
                </tr>
            </thead>
            <tbody>
            </tbody>
        </table>'

    # TODO: sort by name/state/node
    render: ->
        @$el.html @template()
        @render_filter()
        # TODO: cleanup
        if @model.nameFilter then @filter(@model.nameFilter) else @render_list(@model.models)
        @

    render_list: (models) ->
        entry = (model) -> new JobListEntryView(model: model).render().el
        @$('h1').append(@refreshView.render().el)
        @$('tbody').html(entry(model) for model in models)

    render_filter: ->
        filter = new FilterView(default: @model.nameFilter)
        @listenTo(filter, "filter_change", @filter)
        @$('#filter-bar').html(filter.render().el)

    filter: (prefix) ->
        @render_list @model.filter((job) -> _.str.startsWith(job.get('name'), prefix))


class JobListEntryView extends Backbone.View

    initialize: (options) =>
        @listenTo(@model, "change", @render)

    tagName: "tr"

    className: =>
        switch @model.attributes.status
            when "disabled" then 'warning'
            when "enabled"  then 'enabled'
            when "running"  then 'info'

    template: _.template """
        <td><a href="#job/<%= name %>"><%= name %></a></td>
        <td><%= scheduler %></td>
        <td><%= node_pool %></td>
        <td><% print(dateFromNow(last_success, 'never')) %></td>
        <td><% print(dateFromNow(next_run, 'none')) %></td>
        """

    render: ->
        @$el.html @template(@model.attributes)
        makeTooltips(@$el)
        @


class window.JobView extends Backbone.View

    initialize: (options) =>
        @listenTo(@model, "change", @render)
        @refreshView = new RefreshToggleView(model: @model.refresh)
        @listenTo(@refreshView.model, 'refresh', => @model.fetch())

    tagName: "div"

    className: "span12"

    template: _.template """
        <div class="row">
            <div class="span12">
                <h1>Job <%= name %></h1>
            </div>
            <div class="span8">
                <h2>Details</h2>
                <table class="table">
                    <tr><td>status</td>         <td><%= status %></td></tr>
                    <tr><td>Node pool</td>      <td><%= node_pool %></td></tr>
                    <tr><td>Schedule</td>       <td><code><%= scheduler %></code></td></tr>
                    <tr><td>Allow overlap</td>  <td><%= allow_overlap %></td></tr>
                    <tr><td>Queueing</td>       <td><%= queueing %></td></tr>
                    <tr><td>All nodes</td>      <td><%= all_nodes %></td></tr>
                    <tr><td>Last success</td>   <td><%= last_success %></td></tr>
                    <tr><td>Next run</td>       <td><%= next_run %></td></tr>
                </table>
            </div>

            <div class="span12">
                <h2>Job Runs</h2>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Id</th>
                            <th>State</th>
                            <th>Node</th>
                            <th>Start</th>
                            <th>End</th>
                        </tr>
                    </thead>
                    <tbody class="jobruns">
                    </tbody>
                </table>
            </div>

        </div>
        """

    breadcrumb: -> [
            {url: "#jobs", name: "Jobs"},
            {url: "", name: @model.get('name')},
        ]

    render: ->
        @$el.html @template(@model.attributes)
        breadcrumbView.render @breadcrumb()
        entry = (jobrun) -> new JobRunListEntryView(model:new JobRun(jobrun)).render().el
        @$('tbody.jobruns').append(entry(model) for model in @model.get('runs'))
        @$('h1').append(@refreshView.render().el)
        @


class JobRunListEntryView extends Backbone.View

    initialize: (options) =>
        @listenTo(@model, "change", @render)

    tagName: "tr"

    className: ->
        switch @model.get('state')
            when "running"      then 'info'
            when "failed"       then 'error'
            when "succeeded"    then 'success'

    # TODO: add icon for manual run flag
    template: _.template """
        <td><a href="#job/<%= job_name %>/<%= run_num %>"><%= id %></a></td>
        <td><%= state %></td>
        <td><%= node %></td>
        <td><% print(dateFromNow(start_time || run_time, "Unknown")) %></td>
        <td><% print(dateFromNow(end_time, "")) %></td>
        """

    render: ->
        @$el.html @template(@model.attributes)
        makeTooltips(@$el)
        @


class window.JobRunView extends Backbone.View

    initialize: (options) =>
        @listenTo(@model, "change", @render)
        @refreshView = new RefreshToggleView(model: @model.refresh)
        @listenTo(@refreshView.model, 'refresh', => @model.fetch())

    tagName: "div"

    className: "span12"

    template: _.template """
         <div class="row">
            <div class="span12">
                <h1>Job Run <%= id %></h1>
            </div>
            <div class="span8">
                <h2>Details</h2>
                <table class="table">
                    <tr><td>state</td>          <td><%= state %></td></tr>
                    <tr><td>Node</td>           <td><%= node %></td></tr>
                    <tr><td>Manual</td>         <td><%= manual %></td></tr>
                    <tr><td>Scheduled</td>      <td><%= run_time %></td></tr>
                    <tr><td>Start</td>          <td><% print(dateFromNow(start_time, 'None')) %></td></tr>
                    <tr><td>End</td>            <td><% print(dateFromNow(end_time, 'None')) %></td></tr>
                </table>
            </div>

            <div class="span12">
                <h2>Action Runs</h2>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>State</th>
                            <th>Command</th>
                            <th>Exit</th>
                            <th>Node</th>
                            <th>Start</th>
                            <th>End</th>
                        </tr>
                    </thead>
                    <tbody class="actionruns">
                    </tbody>
                </table>
            </div>

        </div>
        """

    breadcrumb: -> [
            {url: "#jobs", name: "Jobs"},
            {url: "#job/" + @model.get('job_name'), name: @model.get('job_name')},
            {url: "", name: @model.get('run_num')},
        ]


    render: ->
        @$el.html @template(@model.attributes)
        breadcrumbView.render @breadcrumb()
        entry = (run) -> new ActionRunListEntryView(model:new ActionRun(run)).render().el
        @$('tbody.actionruns').append(entry(model) for model in @model.get('runs'))
        @$('h1').append(@refreshView.render().el)
        makeTooltips(@$el)
        @


class ActionRunListEntryView extends Backbone.View

    initialize: (options) =>
        @listenTo(@model, "change", @render)

    tagName: "tr"

    className: =>
         switch @model.get('state')
            when "running"      then 'info'
            when "failed"       then 'error'
            when "succeeded"    then 'success'


    template: _.template """
        <td><%= action_name %></td>
        <td><%= state %></td>
        <td><% print(command || raw_command) %></td>
        <td><%= exit_status %></td>
        <td><%= node %></td>
        <td><% print(dateFromNow(start_time, "None")) %></td>
        <td><% print(dateFromNow(end_time, "")) %></td>
        """

    render: ->
        @$el.html @template(@model.attributes)
        makeTooltips(@$el)
        @
