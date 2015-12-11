React = require 'react'
{Markdown} = require 'markdownz'
GenericTask = require '../generic'
GenericTaskEditor = require '../generic-editor'
levenshtein = require 'fast-levenshtein'

NOOP = Function.prototype

Summary = React.createClass
  displayName: 'TextSummary'

  getDefaultProps: ->
    task: null
    annotation: null
    expanded: false

  render: ->
    <div className="classification-task-summary">
      <div className="question">
        {@props.task.instruction}
      </div>
      <div className="answers">
      {if @props.annotation.value?
        <div className="answer">
          “<code>{@props.annotation.value}</code>”
        </div>}
      </div>
    </div>

module.exports = React.createClass
  displayName: 'TextTask'

  statics:
    Editor: GenericTaskEditor
    Summary: Summary

    getDefaultTask: ->
      type: 'text'
      instruction: 'Enter an instruction.'
      help: ''

    getTaskText: (task) ->
      task.instruction

    getDefaultAnnotation: ->
      value: ''

    isAnnotationComplete: (task, annotation) ->
      annotation.value isnt '' or not task.required

    testAnnotationQuality: (unknown, knownGood) ->
      distance = levenshtein.get unknown.value.toLowerCase(), knownGood.value.toLowerCase()
      length = Math.max unknown.value.length, knownGood.value.length
      (length - distance) / length

  getDefaultProps: ->
    task: null
    annotation: null
    onChange: NOOP

  getInitialState: ->
    prevAnswerIndex: 0
    prevAnswerMode: false

  render: ->
    <GenericTask question={@props.task.instruction} help={@props.task.help} required={@props.task.required}>
      <label className="answer">
        <textarea
          className="standard-input full"
          rows="5"
          ref="textInput"
          value={@props.annotation.value}
          onChange={@handleChange}
          onBlur={@handleBlur.bind(@, @props.task.instruction)}
          onKeyDown={@handleKeyDown.bind(@, @props.task.instruction)} />
      </label>
    </GenericTask>

  handleChange: (index, e) ->
    @props.annotation.value = React.findDOMNode(@refs.textInput).value
    @props.onChange? e

  handleBlur: (question, e) ->
    answer = e.target.value.trim()
    prevAnswers = []
    if localStorage.getItem(question)
      prevAnswers = JSON.parse(localStorage.getItem(question))
    if answer and ((prevAnswers.indexOf answer) is -1)
      prevAnswers.unshift answer
      localStorage.setItem(question, JSON.stringify(prevAnswers))

  handleKeyDown: (question, e) ->
    if (e.ctrlKey and e.keyCode is 77) and (not e.target.value or @state.prevAnswerMode)
      prevAnswers = JSON.parse(localStorage.getItem(question))
      e.target.value = prevAnswers[@state.prevAnswerIndex]
      @state.prevAnswerIndex = (@state.prevAnswerIndex += 1) %% prevAnswers.length
      @state.prevAnswerMode = true
    if e.ctrlKey and e.keyCode is 75
      prevAnswers = JSON.parse(localStorage.getItem(question))
      answer = e.target.value.trim()
      answerIndex = prevAnswers.indexOf answer
      unless answerIndex is -1
        prevAnswers.splice(answerIndex, 1)
        localStorage.setItem(question, JSON.stringify(prevAnswers))
        e.target.value = ''
