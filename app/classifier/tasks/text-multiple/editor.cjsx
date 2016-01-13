React = require 'react'
DragReorderable = require 'drag-reorderable'
TriggeredModalForm = require 'modal-form/triggered'
AutoSave = require '../../../components/auto-save'
handleInputChange = require '../../../lib/handle-input-change'
NextTaskSelector = require '../next-task-selector'
{MarkdownEditor} = require 'markdownz'
MarkdownHelp = require '../../../partials/markdown-help'

module?.exports = React.createClass
  displayName: 'TextMultipleEditor'

  getDefaultProps: ->
    workflow: {}
    task: {}

  getInitialState: ->
    textBox: ''

  compoenentWillMount: ->
    @setDefaultAnswersOrder() if not @props.task.answersOrder.length

  setDefaultAnswersOrder: ->
    @props.task.answersOrder = Object.keys(@props.task.answers)
    updateTasks()

  updateTasks: ->
    @props.workflow.update('tasks')
    @props.workflow.save()

  addAnswer: (answerKey, answer) ->
    if (not answer.title) or (not answerKey)
      return window.alert('Answers must have a Key and Title')

    if Object.keys(@props.task.answers).indexOf(answerKey) isnt -1
      return window.alert('Answer Key must be unique')

    @props.task.answers[answerKey] = answer
    @props.task.answersOrder = @props.task.answersOrder.concat(answerKey)
    @updateTasks()

  onClickAddAnswer: (e) ->
    @addAnswer(@refs.answerKey.value, {
      title: @refs.answerTitle.value
      description: @refs.answerDescription.value
      required: @refs.answerRequired.checked
      })

    console.log @props.task

    @refs.answerKey.value = ''
    @refs.answerTitle.value = ''
    @refs.answerDescription.value = ''
    @refs.answerRequired.checked = false

  # TODO delete onClickSaveWorkflow if unneccessary
  # onClickSaveWorkflow: (e) ->
  #   if window.confirm('Are you sure that you would like to save these changes?')
  #     @props.workflow.save()

  onChangeTextBox: (e) ->
    @setState({textBox: e.target.value})

  onClickDeleteTextBox: (name) ->
    if window.confirm('Are you sure you would like to delete the text box?')
      @props.task.answersOrder = @props.task.answersOrder.filter (answer) => answer isnt name
      delete @props.task.answers[name]
      @updateTasks()

  onChangeAnswersOrder: (answersOrder) ->
    @props.task.answersOrder = answersOrder
    @updateTasks()

  dragReorderableRender: (name) ->
    return <li key={name}><i className="fa fa-reorder" title="Drag to reorder" /> {name} <button onClick={@onClickDeleteTextBox.bind(@, name)}><i className="fa fa-close" /></button></li>

  render: ->
    handleChange = handleInputChange.bind @props.workflow

    {instruction, answers, answersOrder} = @props.task
    answerKeys = Object.keys(answers)

    # TODO add CSS?
    <div>
      <div>

        <section>
          <div>
            <AutoSave resource={@props.workflow}>
              <span className="form-label">Main text</span>
              <br />
              <textarea name="#{@props.taskPrefix}.instruction" value={@props.task.instruction} className="standard-input full" onChange={handleChange} />
            </AutoSave>
            <small className="form-help">Describe the task, or ask the question, in a way that is clear to a non-expert. You can use markdown to format this text.</small><br />
          </div>
          <hr/>
        </section>

        <section>
          <h2 className="form-label">Text Box Order</h2>
          <DragReorderable
            tag="ol"
            items={answersOrder}
            onChange={@onChangeAnswersOrder}
            render={@dragReorderableRender}
          />
          <hr/>
        </section>

        <section>
          <h2 className="form-label">Add a Text Box<TriggeredModalForm trigger={<i className="fa fa-question-circle"></i>}>
            <p><strong>Answer Keys</strong> are used as a unique indentifier to store data within the classification.</p>
            <p><strong>Titles</strong> are what will be displayed as the attribute that needs annotation.</p>
            <p><strong>Description</strong> will provide additional details about the attribute and how it should be annotated.</p>
            <p><strong>Required</strong> will require an annotation for the noted attribute to proceed.</p>
          </TriggeredModalForm></h2>
          <label>
            Answer Key <input ref="answerKey"></input>
          </label>
          <br/>
          <label>
            Title <input ref="answerTitle"></input>
          </label>
          <br/>
          <label>
            Description <input ref="answerDescription"></input>
          </label>
          <br/>
          <label key="required" className="pill-button">
            Required <input type="checkbox" ref="answerRequired"></input>
          </label>
          <br/>
          <button type="button" onClick={@onClickAddAnswer}>+ Add Text Box</button>
          <hr/>
        </section>

        <section>
          <h2 className="form-label">Edit a Text Box</h2>

          <span>Text Box </span>

          <select ref="textBox" defaultValue={@state.textBox} onChange={@onChangeTextBox}>
            <option value="" disabled>Text Box</option>

            {answerKeys.map (answerKey, i) =>
              <option key={answerKey + i} value={answerKey}>{answers[answerKey].title}</option>}
          </select>
          <br/>
          {if @state.textBox
            # TODO fix this!
            <AutoSave resource={@props.workflow}>
              <label>
                Title <input defaultValue={@props.task.answers[@state.textBox].title}></input>
              </label>
            </AutoSave>
          }
        </section>

      </div>

      <hr/>

      {#<button type="button" onClick={@onClickSaveWorkflow}><i className="fa fa-save" /> Save Workflow</button>}
      {#<hr/>}

      <AutoSave resource={@props.workflow}>
        <span className="form-label">Next task</span>
        <br/>
        <NextTaskSelector workflow={@props.workflow} name="#{@props.taskPrefix}.next" value={@props.task.next ? ''} onChange={handleInputChange.bind @props.workflow} />
      </AutoSave>

    </div>
