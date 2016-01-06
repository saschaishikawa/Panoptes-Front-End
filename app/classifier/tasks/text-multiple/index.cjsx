React = require 'react'
GenericTask = require '../generic'
TextMultipleTaskEditor = require './editor'
levenshtein = require 'fast-levenshtein'
# incorporate {Markdown}?

# is NOOP necessary? see module.export getDefaultProps
NOOP = Function.prototype

key =
  K: 75
  M: 77

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

  getInitialState: ->
    prevAnswerIndex: 0

  render: ->
    {answers, answersOrder} = @props.task
    textBoxes = if answersOrder.length then answersOrder else Object.keys(answers)

    # TODO add custom CSS for title and description <div>'s
    <GenericTask question={@props.task.instruction} help={@props.task.help} required={@props.task.required}>
      <div>

        {textBoxes.map (name, i) =>
          <div key={i}>
            <hr/>
            <div>{answers[name].title}</div>
            <label className="answer">
              <textarea
                className="standard-input full"
                rows="3"
                ref="text-#{name}"
                value={answers[name].value}
                onChange={@handleChange.bind(@, textBoxes)}
                onBlur={@handleBlur.bind(@, name)}
                onKeyDown={@handleKeyDown.bind(@, name)}
                />
            </label>
            <div>{answers[name].description}</div>
          </div>
        }

      </div>
    </GenericTask>

  handleChange: (textBoxes, e) ->
    currentAnswers = textBoxes.reduce((obj, name) =>
      obj[name] = @refs["text-#{name}"].value.trim()
      obj
    , {})

    @props.annotation.value = currentAnswers
    @props.onChange()

  handleBlur: (answerKey, e) ->
    answerValue = e.target.value.trim()
    prevAnswers = @getPreviousAnswers(answerKey) or []
    if answerValue and ((prevAnswers.indexOf answerValue) is -1)
      prevAnswers.unshift answerValue
      @setPreviousAnswers(prevAnswers, answerKey)
    @setState prevAnswerIndex: 0

  handleKeyDown: (answerKey, e) ->
    return unless e.ctrlKey and (e.keyCode is key.M or e.keyCode is key.K)
    prevAnswers = @getPreviousAnswers(answerKey)
    return unless prevAnswers.length
    # accesses previous answers from local storage
    if (e.keyCode is key.M) and (not e.target.value or (prevAnswers.indexOf e.target.value.trim()) isnt -1)
      e.target.value = prevAnswers[@state.prevAnswerIndex]
      @setState prevAnswerIndex: (@state.prevAnswerIndex + 1) %% prevAnswers.length
    # clears current answer from previous answers in local storage
    if e.keyCode is key.K
      answerValue = e.target.value.trim()
      unless (prevAnswers.indexOf answerValue) is -1
        e.target.value = ''
        @setState prevAnswerIndex: 0
        prevAnswers.splice (prevAnswers.indexOf answerValue), 1
        @setPreviousAnswers(prevAnswers, answerKey)
        @handleChange(e)

  getPreviousAnswers: (answerKey) ->
    JSON.parse localStorage.getItem "#{window.location.pathname}-#{answerKey}"

  setPreviousAnswers: (prevAnswers, answerKey) ->
    localStorage.setItem "#{window.location.pathname}-#{answerKey}", JSON.stringify prevAnswers
