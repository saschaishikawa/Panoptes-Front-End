React = require 'react'
GenericTask = require '../generic'
DropdownTaskEditor = require './editor'

Summary = React.createClass
  displayName: 'DropdownSummary'

  getDefaultProps: ->
    task: {}
    annotation: {}

  render: ->
    {answersOrder, answers} = @props.task
    answersOrder = if answersOrder.length then answersOrder else Object.keys(answers)

    <div className="classification-task-summary">
      <div className="question">{@props.task.instruction}</div>
      <div className="answers">
        {if @props.annotation.value
          answersOrder.map (i) =>
            <div key={i} className="answer">
              <i className="fa fa-arrow-circle-o-right" /> {answers[i].title} - {@props.annotation?.value[i]}
            </div>
        }
      </div>
    </div>

module?.exports = React.createClass
  displayName: 'DropdownTask'

  statics:
    Editor: DropdownTaskEditor
    Summary: Summary

    getDefaultTask: ->
      type: 'dropdown'
      instruction: 'Select an option from the dropdown(s)'
      help: 'Click on the dropdown and choose an option'
      answers: []
      answersOrder: []

    getTaskText: (task) ->
      task.instruction

    getDefaultAnnotation: ->
      value: []

    isAnnotationComplete: (task, annotation) ->
      answersCompleted = annotation.value.filter(Boolean)

      answersCompleted.length is task.answers.length

  render: ->
    {answers, answersOrder} = @props.task
    dropdowns = if answersOrder.length then answersOrder else (answers.map (i) -> answers.indexOf i)

    <GenericTask question={@props.task.instruction} help={@props.task.help} required={@props.task.required}>
      <div className="dropdown-task">

        {dropdowns.map (i) =>
          <div key={i}>
            <div>{answers[i].title}</div>
            <select defaultValue={@props.annotation.value[i] ? ""} ref="dropdown-#{answers[i].title}" onChange={@onChangeDropdown.bind(@, dropdowns)}>
              <option key="_title" value="" disabled>--</option>

              {answers[i].options.map (option, i) =>
                <option key={i} value={option}>
                  {option}
                </option>}
            </select>
          </div>
          }

      </div>
    </GenericTask>

  onChangeDropdown: (dropdowns, e) ->
    currentAnswers = dropdowns.reduce((obj, i) =>
      obj[i] = @refs["dropdown-#{@props.task.answers[i].title}"].value
      obj
    , [])

    @props.annotation.value = currentAnswers
    @props.onChange()
