React = require 'react'
FileButton = require '../../../components/file-button'
alert = require '../../../lib/alert'
Details = require '../../../components/details'
TriggeredModalForm = require 'modal-form/triggered'
surveyEditorHelp = require './editor-help'
AutoSave = require '../../../components/auto-save'
handleInputChange = require '../../../lib/handle-input-change'
NextTaskSelector = require '../next-task-selector'
MediaArea = require '../../../components/media-area'
PromiseRenderer = require '../../../components/promise-renderer'
{Markdown} = require 'markdownz'
Papa = require 'papaparse'
apiClient = require 'panoptes-client/lib/api-client'
putFile = require '../../../lib/put-file'
Utility = require './utility'

module.exports = React.createClass
  displayName: 'FlexibleSurveyTaskEditor'

  getInitialState: ->
    importErrors: []
    resettingMedia: false

  getDefaultProps: ->
    workflow: null
    task: null
    taskPrefix: ''

  render: ->
    window.editingSurveyTask = @props.task

    <div className="workflow-task-editor">
      <p><span className="form-label">Import task data</span></p>
      <div className="columns-container" style={marginBottom: '0.2em'}>
        <FileButton className="major-button column" accept=".csv, .tsv" multiple onSelect={@handleFiles.bind this, @addChoice}>Add choices CSV</FileButton>
        <TriggeredModalForm trigger={
          <span className="secret-button">
            <i className="fa fa-question-circle"></i>
          </span>
        }>
          {surveyEditorHelp.choices}
        </TriggeredModalForm>
      </div>
      <div className="columns-container" style={marginBottom: '0.2em'}>
        <FileButton className="major-button column" accept=".csv, .tsv" multiple onSelect={@handleFiles.bind this, @addCharacteristics}>Add characteristics CSV</FileButton>
        <TriggeredModalForm trigger={
          <span className="secret-button">
            <i className="fa fa-question-circle"></i>
          </span>
        }>
          {surveyEditorHelp.characteristics}
        </TriggeredModalForm>
      </div>
      <div className="columns-container" style={marginBottom: '0.2em'}>
        <FileButton className="major-button column" accept=".csv, .tsv" multiple onSelect={@handleFiles.bind this, @addConfusion}>Add confused pairs CSV</FileButton>
        <TriggeredModalForm trigger={
          <span className="secret-button">
            <i className="fa fa-question-circle"></i>
          </span>
        }>
          {surveyEditorHelp.confusions}
        </TriggeredModalForm>
      </div>
      <div className="columns-container" style={marginBottom: '0.2em'}>
        <FileButton className="major-button column" multiple onSelect={@handleFiles.bind this, @addQuestion}>Add questions CSV</FileButton>
        <TriggeredModalForm trigger={
          <span className="secret-button">
            <i className="fa fa-question-circle"></i>
          </span>
        }>
          {surveyEditorHelp.questions}
        </TriggeredModalForm>
      </div>

      <hr />

      {unless @state.importErrors.length is 0
        <div>
          <p className="form-label">Import errors</p>
          {for {error, file, row}, i in @state.importErrors
            <p key={i}>
              <strong>{error.message}</strong>
              <br />
              <span className="form-help">
                {if file?
                  <span>{file?.name} </span>}
                {if row? or error.row?
                  <span>Row {(row ? error.row) + 1} </span>}
              </span>
            </p>}
          <hr />
        </div>}

      <div>
        <span className="form-label">Survey images</span>{' '}
        <AutoSave resource={@props.workflow}>
          <button type="button" disabled={@state.resettingMedia} onClick={@resetMedia}>Delete all</button>
          {if @state.resettingMedia
            <i className="fa fa-spinner fa-spin"></i>}
        </AutoSave>
      </div>

      <MediaArea
        resource={@props.workflow}
        metadata={prefix: @props.taskPrefix}
        style={maxHeight: '90vh'}
        onAdd={@handleImageAdd}
        onDelete={@handleImageDelete}
      />

      <hr />

      <p>
        <AutoSave resource={@props.workflow}>
          <span className="form-label">Next task</span>
          <br />
          <NextTaskSelector workflow={@props.workflow} name="#{@props.taskPrefix}.next" value={@props.task.next ? ''} onChange={handleInputChange.bind @props.workflow} />
        </AutoSave>
      </p>

      <hr />

      <div>
        <span className="form-label">Survey data</span>{' '}
        <AutoSave resource={@props.workflow}>
          <button type="button" onClick={@resetTask}>Delete all</button>
        </AutoSave>
      </div>

      {for choiceID in @props.task.choicesOrder
        choice = @props.task.choices[choiceID]
        <Details key={choiceID} className="survey-task-editor-choice" summary={
          <strong>{choice.label}</strong>
        }>
          <Markdown content={choice.description} />
          <div>
            {for characteristicID in @props.task.characteristicsOrder when choice.characteristics[characteristicID]?.length isnt 0
              characteristic = @props.task.characteristics[characteristicID]
              <div key={characteristicID}>
                <small>
                  {characteristic.label}:{' '}
                  {valueLabels = for valueID in characteristic.valuesOrder when valueID in choice.characteristics[characteristicID]
                    value = characteristic.values[valueID]
                    value.label
                  valueLabels.join ', '}
                </small>
              </div>}
            {unless choice.confusionsOrder.length is 0
              <div>
                <small>
                  Confused with:{' '}
                  {twinLabels = for twinID in choice.confusionsOrder
                    twin = @props.task.choices[twinID]
                    twin?.label ? '(Unknown choice)'
                  twinLabels.join ', '}
                </small>
              </div>}
          </div>
        </Details>}

      <hr />

      {unless @props.task.questionsOrder.length is 0
        <div>
          <Details summary="Questions">
            {for questionID in @props.task.questionsOrder
              question = @props.task.questions[questionID]
              <p>
                <strong>{question.label}</strong>:{' '}
                {if question.multiple
                  'Any of'
                else
                  'One of'}{' '}
                {(question.answers[answerID].label for answerID in question.answersOrder).join ', '}{' '}
                {if question.required
                  '(Required)'}
                </p>}
          </Details>
          <hr />
        </div>}

      <Details summary={<small>Raw task data</small>}>
        <pre style={fontSize: '10px', whiteSpace: 'pre-wrap'}>{JSON.stringify @props.task, null, 2}</pre>
      </Details>
    </div>

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

    cleanRows = for row in data
      clean = {}
      for key, value of row
        cleanKey = key.trim()
        cleanValue = value.trim?()

        if key.indexOf('=') is -1
          cleanKey = cleanKey.toLowerCase().replace /\s+/g, '_'
        else
          cleanValue = @determineBoolean cleanValue

        clean[cleanKey] = cleanValue
      clean

    for error in errors
      @handleImportError error

    cleanRows

  determineBoolean: (value) ->
    # TODO: Iterate on this as we see more cases.
    value?.charAt(0).toUpperCase() in ['T', 'X', 'Y', '1']

  makeID: (string) ->
    string.replace(/[aeiouy\W]/gi, '').toUpperCase()

  ensureChoice: (name) ->
    choiceID = @makeID name
    unless choiceID in @props.task.choicesOrder
      @props.task.choicesOrder.push choiceID
    @props.task.choices[choiceID] ?=
      label: name
      description: ''
      noQuestions: false
      image: []
      characteristics: {}
      confusionsOrder: []
      confusions: {}
    @props.task.choices[choiceID]

  addChoice: ({name, description, no_questions, images, __parsedExtra}) ->
    unless name?
      throw new Error 'Choices require a "name" column.'
    choice = @ensureChoice name
    choice.label = name
    if description?
      choice.description = description
    if no_questions?
      choice.noQuestions = @determineBoolean no_questions
    if images?
      images = images.split(/\s*,\s*/).concat(__parsedExtra ? []).filter Boolean
      choice.images = images

  addCharacteristics: (row) ->
    unless row.name?
      throw new Error 'Characteristics require a "name" column.'
    @ensureChoice row.name
    for charKeyVal, isSet of row when charKeyVal isnt 'name'
      [characteristicLabel, valueLabelAndIcon] = charKeyVal.replace('=', '__SPLIT_ONCE__').split /\s*__SPLIT_ONCE__\s*/
      [valueLabel, valueIcon] = valueLabelAndIcon.split /\s*,\s*/
      if characteristicLabel is '' or valueLabel is ''
        throw new Error 'Characteristics column headers should be formatted like "Color=Blue","Color=Red".'
      characteristicID = @makeID characteristicLabel
      valueID = @makeID valueLabel
      unless characteristicID in @props.task.characteristicsOrder
        @props.task.characteristicsOrder.push characteristicID
        @props.task.characteristics[characteristicID] =
          label: ''
          valuesOrder: []
          values: {}
      @props.task.characteristics[characteristicID].label = characteristicLabel
      unless valueID in @props.task.characteristics[characteristicID].valuesOrder
        @props.task.characteristics[characteristicID].valuesOrder.push valueID
        @props.task.characteristics[characteristicID].values[valueID] =
          label: valueLabel
      @props.task.characteristics[characteristicID].values[valueID].image = valueIcon
      for choiceID, choice of @props.task.choices
        choice.characteristics[characteristicID] ?= []
      if isSet
        choiceID = @makeID row.name
        @props.task.choices[choiceID]?.characteristics[characteristicID].push valueID

  addConfusion: ({name, twin, details}) ->
    unless name?
      throw new Error 'Confused pairs require a "name" column.'
    unless twin?
      throw new Error 'Confused pairs require a "twin" column.'
    @ensureChoice name
    choiceID = @makeID name
    confusionID = @makeID twin
    @props.task.choices[choiceID]?.confusionsOrder.push confusionID
    @props.task.choices[choiceID]?.confusions[confusionID] = details

  addQuestion: ({question, multiple, required, answers, name, __parsedExtra}) ->
    unless question? or name?
      throw new Error 'Questions require a "question" column'
    unless answers?
      throw new Error 'Questions require a "answers" column'

    choices = null
    questionID = null
    if(!!name)
      choices = name.split(/\s*;s*/)
    if(!!question)
      questionID = @makeID question

    # don't put it in the default questionsOrder if we've specified choices it should map to
    unless choices? or questionID in @props.task.questionsOrder
      @props.task.questionsOrder.push questionID

    # if we specified mapped choices, create those entries instead
    if choices?
      @props.task.questionsMap ?= {}
      for choice in choices
        continue unless !!choice
        choiceID = @makeID choice
        @props.task.questionsMap[choiceID] ?= []
        @props.task.questionsMap[choiceID].push questionID if questionID?

    # we only can get here if the question stuff is empty and the names are not empty
    # that means there will be no questions for this choice, so we don't need to actually
    # store any questions or answers for this row of the csv
    return unless questionID?

    @props.task.questions[questionID] =
      label: question
      multiple: @determineBoolean multiple
      required: @determineBoolean required
      answersOrder: []
      answers: {}

    for answer in answers.split(/;/).concat(__parsedExtra ? []).filter Boolean
      answerID = @makeID answer
      @props.task.questions[questionID].answersOrder.push answerID
      @props.task.questions[questionID].answers[answerID] =
        label: answer

  handleImageAdd: (media) ->
    @props.task.images[media.metadata.filename] = media.src
    @props.workflow.update('tasks').save()

  handleImageDelete: (media) ->
    delete @props.task.images[media.metadata.filename]
    @props.workflow.update('tasks').save()

  resetTask: (e) ->
    if e.shiftKey or confirm 'Really delete all the data from this task?'
      Object.assign @props.task,
        characteristicsOrder: []
        characteristics: {}
        choicesOrder: []
        choices: {}
        questionsOrder: []
        questions: {}
      @props.workflow.update 'tasks'

  resetMedia: (e) ->
    if e.shiftKey or confirm 'Really delete all the images from this task? This might take a while...'
      @setState resettingMedia: true
      errors = 0
      massDelete = @props.workflow.get('attached_images', page_size: 200).then (workflowImages) =>
        taskImages = workflowImages.filter (image) =>
          image.metadata.prefix is @props.taskPrefix
        Promise.all taskImages.map (image) =>
          image.delete().catch =>
            errors += 1
      massDelete.then =>
        @setState resettingMedia: false
        if errors isnt 0
          alert "There were #{errors} errors deleting all those resources. Try again to get the rest."

  handleImportError: (error, file, row) ->
    @state.importErrors.push {error, file, row}
    @setState importErrors: @state.importErrors
