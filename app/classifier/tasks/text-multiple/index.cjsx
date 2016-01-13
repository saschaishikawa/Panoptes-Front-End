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

  render: ->
    {answersOrder, answers} = @props.task

    <div className="classification-task-summary">
      <div className="question">{@props.task.instruction}</div>
      <div className="answers">
        {if @props.annotation.value
          answersOrder.map (key, i) =>
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
      requiredFilter = (taskAnswer) -> task.answers[taskAnswer].required
      requiredAnswers = Object.keys(task.answers).filter requiredFilter

      answer = (key) ->
        return key if annotation.value[key]? and annotation.value[key] isnt ''
      answersCompleted = requiredAnswers.map(answer)

      compareArrays = (requiredAnswers, answersCompleted) ->
        areEqual = true
        for i in [0..requiredAnswers.length]
          if requiredAnswers[i] isnt answersCompleted[i]
            areEqual = false
        return areEqual

      (not requiredAnswers.length) or compareArrays(requiredAnswers, answersCompleted)

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

    <GenericTask question={@props.task.instruction} help={@props.task.help} required={@props.task.required}>
      <div className="text-multiple-task">

        {textBoxes.map (name, i) =>
          <div key={i}>
            <hr/>
            <div className="title">{answers[name].title}</div>
            <div className="description">{answers[name].description}</div>
            <label className="answer">
              <textarea
                className="standard-input full"
                rows="2"
                ref="text-#{name}"
                defaultValue={@props.annotation.value[name] ? ""}
                value={answers[name].value}
                onChange={@handleChange.bind(@, textBoxes)}
                onBlur={@handleBlur.bind(@, name)}
                onKeyDown={@handleKeyDown.bind(@, name, textBoxes)}
                />
            </label>
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

  handleKeyDown: (answerKey, textBoxes, e) ->
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
        @handleChange(textBoxes)

  getPreviousAnswers: (answerKey) ->
    JSON.parse localStorage.getItem "#{window.location.pathname}-#{answerKey}"

  setPreviousAnswers: (prevAnswers, answerKey) ->
    localStorage.setItem "#{window.location.pathname}-#{answerKey}", JSON.stringify prevAnswers
