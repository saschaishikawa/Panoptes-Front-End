React = require 'react'
FileButton = require '../../../components/file-button'
TriggeredModalForm = require 'modal-form/triggered'
dropdownEditorHelp = require './editor-help'
AutoSave = require '../../../components/auto-save'
handleInputChange = require '../../../lib/handle-input-change'
NextTaskSelector = require '../next-task-selector'
PromiseRenderer = require '../../../components/promise-renderer'
{MarkdownEditor} = require 'markdownz'
MarkdownHelp = require '../../../partials/markdown-help'
Papa = require 'papaparse'
DragReorderable = require 'drag-reorderable'

module?.exports = React.createClass
  displayName: 'DropdownEditor'

  getInitialState: ->
    dropdown: ''
    importErrors: []

  getDefaultProps: ->
    workflow: {}
    task: {}

  componentWillMount: ->
    @setDefaultAnswersOrder() if not @props.task.answersOrder.length

  setDefaultAnswersOrder: ->
    @props.task.answersOrder = Object.keys(@props.task.answers)
    @updateTasks()

  updateTasks: ->
    @props.workflow.update('tasks')
    @props.workflow.save()

  selectedOptions: ->
    @props.task.answers[@state.dropdown]?.options

  addAnswer: (i, answer) ->
    if not answer.title
      return window.alert('Dropdowns must have a Title')

    answerTitles = @props.task.answers.map (answer) -> answer.title

    if answerTitles.indexOf(answer.title) isnt -1
      return window.alert('Dropdowns must have a unique Title')

    @props.task.answers[i] = answer
    @props.task.answersOrder.push(i)
    @updateTasks()

  addAnswerOption: (i, option) ->
    if not option
      return window.alert('Please provide an option')

    if @selectedOptions().indexOf(option) isnt -1
      return window.alert('Options must be unique to each dropdown')

    @props.task.answers[i].options?.push(option)
    @updateTasks()

  onClickAddAnswer: (e) ->
    @addAnswer(@props.task.answers.length, {
      title: @refs.answerTitle.value,
      options: []
    })
    @updateTasks()

    @refs.answerTitle.value = ''

  onClickAddAnswerOption: (e) ->
    @addAnswerOption(@state.dropdown, @refs.answerOption.value)
    @refs.answerOption.value = ''

  onChangeDropdown: (e) ->
    @setState({dropdown: e.target.value})

  onClickDeleteDropdown: (i) ->
    if window.confirm('Are you sure that you would like to delete this dropdown?')
      @props.task.answersOrder = @props.task.answersOrder
        .filter (prevIndex) => prevIndex isnt i
        .map (prevIndex) =>
          if prevIndex < i
            prevIndex
          else if prevIndex > i
            prevIndex - 1

      @props.task.answers.splice(i, 1)

      @setState {dropdown: ''}, =>
        @updateTasks()
        @props.workflow.save()

  onChangeAnswersOrder: (answersOrder) ->
    @props.task.answersOrder = answersOrder
    @updateTasks()

  onClickDeleteDropdownOption: (dropdownItem) ->
    {answers} = @props.task

    if window.confirm('Are you sure that you would like to delete this option?')
      answers[@state.dropdown]?.options = @selectedOptions().filter (option) -> option isnt dropdownItem
      @updateTasks()

  dragReorderableRender: (i) ->
    return <li key={i}><i className="fa fa-reorder" title="Drag to reorder" /> {@props.task.answers[i].title} <button onClick={@onClickDeleteDropdown.bind(@, i)}><i className="fa fa-close" /></button></li>

  handleFiles: (forEachRow, e) ->
    @setState
      importErrors: []
    Array::slice.call(e.target.files).forEach (file) =>
      @readFile file
        .then @parseFileContent
        .then (rows) =>
          Promise.all rows.map (row, i) =>
            try
              forEachRow row
            catch error
              @handleImportError error, file, i
        .catch (error) =>
          throw error
          @handleImportError error, file
        .then =>
          @props.workflow.update('tasks').save()

  readFile: (file) ->
    new Promise (resolve) ->
      reader = new FileReader
      reader.onload = (e) =>
        resolve e.target.result
      reader.onerror = (error) =>
        @handleImportError error, file
      reader.readAsText file

  parseFileContent: (content) ->
    {errors, data} = Papa?.parse content.trim(), header: true

    cleanRows = []

    for row in data
      for key, value of row
        cleanValue = value.trim?()
        cleanRows.push cleanValue

    for error in errors
      @handleImportError error

    cleanRows

  determineBoolean: (value) ->
    # TODO: Iterate on this as we see more cases.
    value?.charAt(0).toUpperCase() in ['T', 'X', 'Y', '1']

  addCSVAnswerOption: (name) ->
    unless name?
      throw new Error 'Options require an "option" column.'
    @addAnswerOption @state.dropdown, name

  handleImportError: (error, file, row) ->
    @state.importErrors.push {error, file, row}
    @setState importErrors: @state.importErrors

  render: ->
    handleChange = handleInputChange.bind @props.workflow

    {answers, answersOrder} = @props.task
    answerKeys = Object.keys(answers)

    <div className="dropdown-editor">
      <div className="dropdown">

        <section>

          <div>
            <AutoSave resource={@props.workflow}>
              <span className="form-label">Main text</span>
              <br />
              <textarea name="#{@props.taskPrefix}.instruction" value={@props.task.instruction} className="standard-input full" onChange={handleChange} />
            </AutoSave>
            <small className="form-help">Describe the task, or ask the question, in a way that is clear to a non-expert. You can use markdown to format this text.</small><br />
          </div>
          <br />

          <div>
            <AutoSave resource={@props.workflow}>
              <span className="form-label">Help text</span>
              <br />
              <MarkdownEditor name="#{@props.taskPrefix}.help" onHelp={-> alert <MarkdownHelp/>} value={@props.task.help ? ""} rows="4" className="full" onChange={handleChange} />
            </AutoSave>
            <small className="form-help">Add text and images for a help window.</small>
          </div>

          <hr />

        </section>

        <section>

              <h2 className="form-label">Dropdown Order</h2>

              <DragReorderable
                tag='ol'
                items={answersOrder}
                onChange={@onChangeAnswersOrder}
                render={@dragReorderableRender}
              />

        </section>

        <hr />

        <section>
          <h2 className="form-label">Add a dropdown
          <TriggeredModalForm trigger={<i className="fa fa-question-circle"></i>}>
            <p><strong>Title</strong> is what will be displayed as the dropdown title</p>
          </TriggeredModalForm></h2>

          <br/>
          <label>
            Title <input ref="answerTitle"></input>
          </label>
          <br/>
          <button type="button" onClick={@onClickAddAnswer}><i className="fa fa-plus" /> Add Dropdown Box</button>
        </section>

        <hr/>

        <section>
          <h2 className="form-label">Edit dropdown options<TriggeredModalForm trigger={<i className="fa fa-question-circle"></i>}>
            <p><strong>Options</strong> are what will be displayed to users as options within the dropdown</p>
          </TriggeredModalForm></h2>

          <span>Dropdown </span>

          <select ref="dropdown" defaultValue={@state.dropdown} onChange={@onChangeDropdown}>
            <option value="" disabled>none selected</option>

            {answerKeys.map (answerKey) =>
              <option key={answerKey} value={answerKey}>{answers[answerKey].title}</option>}
          </select>

          {if @state.dropdown
            <div>
              <ul>
                {@selectedOptions().map (option, i) =>
                  <li key={i}>
                    {option}{' '}

                    <button onClick={@onClickDeleteDropdownOption.bind(this, option)} title="Delete">
                      <i className="fa fa-close" />
                    </button>
                  </li>}
              </ul>

              <div className="dropdown-option">
                <label>
                  Option <input ref="answerOption"></input>
                </label>{' '}

              </div>

              <button type="button" onClick={@onClickAddAnswerOption}><i className="fa fa-plus" /> Add Dropdown Option</button>

              <br/>

              <div className="workflow-task-editor">
                <p><span className="form-label">Import task data</span></p>
                <div className="columns-container" style={marginBottom: '0.2em'}>
                  <FileButton className="major-button column" accept=".csv, .tsv" multiple onSelect={@handleFiles.bind this, @addCSVAnswerOption}>Add options CSV</FileButton>
                  <TriggeredModalForm trigger={
                    <span className="secret-button">
                      <i className="fa fa-question-circle"></i>
                    </span>
                  }>
                    {dropdownEditorHelp.options}
                  </TriggeredModalForm>
                </div>
              </div>

            </div>
          }

        </section>

      </div>

      <hr/>

      <AutoSave resource={@props.workflow}>
        <span className="form-label">Next task</span>
        <br />
        <NextTaskSelector workflow={@props.workflow} name="#{@props.taskPrefix}.next" value={@props.task.next ? ''} onChange={handleInputChange.bind @props.workflow} />
      </AutoSave>
    </div>
