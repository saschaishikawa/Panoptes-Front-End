React = require 'react'
GenericTask = require '../generic'
TextMultipleTaskEditor = require './editor'
levenshtein = require 'fast-levenshtein'
# incorporate {Markdown}?

# is NOOP necessary? see module.export getDefaultProps
NOOP = Function.prototype

Summary = React.createClass
  displayName: 'TextMultipleSummary'

  getDefaultProps: ->
    task: {}
    annotation: {}
    # TODO incorporate expanded prop?

  render: ->
    {answers} = @props.task

    <div className="classification-task-summary">
      <div className="question">{@props.task.instruction}</div>
      <div className="answers">
        {if @props.annotation.value
          Object.keys(answers).map (key, i) =>
            <div key={i} className="answer">
              "<code>{answers[key].title} - {@props.annotation?.value[key]}</code>"
            </div>
          }
      </div>
    </div>

module?.exports = React.createClass
  displayName: 'TextMultipleTask'

  statics:
    Editor: TextMultipleTaskEditor
    Summary: Summary

    getDefaultTask: ->
      type: 'textMultiple'
      instruction: 'Annotate the following attributes.'
      help: 'Write your best guess to the noted attributes of the subject.'
      answers: {}
      answersOrder: []

    getTaskText: (task) ->
      task.instruction

    getDefaultAnnotation: ->
      value: {}

    isAnnotationComplete: (task, annotation) ->
      answer = (key) -> annotation.value[key]
      answersCompleted = Object.keys(annotation.value)
        .map(answer)
        .filter(Boolean)

      answersCompleted.length and (answersCompleted.length is Object.keys(task.answers).length)

    testAnnotationQuality: (unknown, knownGood) ->
      distance = levenshtein.get unknown.value.toLowerCase(), knownGood.value.toLowerCase()
      length = Math.max unknown.value.length, knownGood.value.length
      (length - distance) / length

  # TODO is it necessary to set the following DefaultProps?
  getDefaultProps: ->
    task: null
    annotation: null
    onChange: NOOP

  render: ->
    {answers, answersOrder} = @props.task
    textBoxes = if answersOrder.length then answersOrder else Object.keys(answers)

    # TODO add custom CSS for title and description <div>'s
    <GenericTask question={@props.task.instruction} help={@props.task.help} required={@props.task.required}>
      <div>

        {textBoxes.map (name, i) =>
          <div key={i}>
            <div>{answers[name].title}</div>
            <div>{answers[name].description}</div>
            <label className="answer">
              <textarea
                className="standard-input full"
                rows="1"
                ref="text-#{name}"
                value={answers[name].value}
                onChange={@handleChange.bind(@, textBoxes)}
                />
            </label>
          </div>
        }

      </div>
    </GenericTask>

  handleChange: (textBoxes, e) ->
    currentAnswers = textBoxes.reduce((obj, name) =>
      obj[name] = @refs["text-#{name}"].value
      obj
    , {})

    @props.annotation.value = currentAnswers
    @props.onChange()
