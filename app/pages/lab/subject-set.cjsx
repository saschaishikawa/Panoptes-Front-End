React = require 'react'
handleInputChange = require '../../lib/handle-input-change'
PromiseRenderer = require '../../components/promise-renderer'
apiClient = require '../../api/client'
ChangeListener = require '../../components/change-listener'
Papa = require 'papaparse'
{Navigation} = require 'react-router'
alert = require '../../lib/alert'
SubjectUploader = require '../../partials/subject-uploader'
BoundResourceMixin = require '../../lib/bound-resource-mixin'
RetirementRulesEditor = require '../../components/retirement-rules-editor'
UploadDropTarget = require '../../components/upload-drop-target'
ManifestView = require '../../components/manifest-view'

NOOP = Function.prototype

VALID_SUBJECT_EXTENSIONS = ['.jpg', '.png', '.gif', '.svg']
INVALID_FILENAME_CHARS = [';'] # TODO: Figure out a good general way to separate filenames.

EditSubjectSetPage = React.createClass
  displayName: 'EditSubjectSetPage'

  mixins: [BoundResourceMixin, Navigation]

  boundResource: 'subjectSet'

  getDefaultProps: ->
    subjectSet: null

  getInitialState: ->
    manifests: {}
    files: {}
    deletionError: null
    deletionInProgress: false

  render: ->
    <div>
      <form onSubmit={@handleSubmit}>
        <p>Name <input type="text" name="display_name" value={@props.subjectSet.display_name} className="standard-input" onChange={@handleChange} /></p>
        <p>Retirement <RetirementRulesEditor subjectSet={@props.subjectSet} /></p>

        <button type="submit" className="standard-button" disabled={not @props.subjectSet.hasUnsavedChanges()}>Save</button>
        {@renderSaveStatus()}
      </form>

      <hr />

      <p>Subjects: <strong>{@props.subjectSet.set_member_subjects_count}</strong></p>

      <hr />

      <p>
        <UploadDropTarget onSelect={@handleFileSelection}>
          Drop manifests and subject data here.<br />
          Manifests must be <code>.csv</code> or <code>.tsv</code>.<br />
          Subjects can be any of: {<span key={ext}><code>{ext}</code>{' '}</span> for ext in VALID_SUBJECT_EXTENSIONS}.
        </UploadDropTarget>
      </p>

      {if Object.keys(@state.manifests).length is 0
        <div>TODO: List subjects without a manifest</div>
      else
        subjectsToCreate = 0

        <div className="manifests-and-subjects">
          <ul>
            {for name, {errors, subjects} of @state.manifests
              {ready} = ManifestView.separateSubjects subjects, @state.files
              subjectsToCreate += ready.length

              <li key={name}>
                <ManifestView name={name} errors={errors} subjects={subjects} files={@state.files} onRemove={@handleRemoveManifest.bind this, name} />
              </li>}
          </ul>

          <button type="button" className="major-button" onClick={@createSubjects}>Upload {subjectsToCreate} new subjects</button>
        </div>}

      <hr />

      <p>
        <small><button type="button" className="minor-button" disabled={@state.deletionInProgress} onClick={@deleteSubjectSet}>Delete this subject set</button></small>
        {if @state.deletionError?
          <span className="form-help error">{@state.deletionError.message}</span>}
      </p>
    </div>

  handleSubmit: (e) ->
    e.preventDefault()
    @saveResource()

  handleFileSelection: (files) ->
    for file in files
      if file.type in ['text/csv', 'text/tab-separated-values']
        @_addManifest file
        gotManifest = true
      else if file.type.indexOf('image/') is 0
        @state.files[file.name] = file
        gotFile = true

      if gotFile and not gotManifest
        @forceUpdate()

  _addManifest: (file) ->
    reader = new FileReader
    reader.onload = (e) =>
      # TODO: Look into PapaParse features.
      # Maybe wan we parse the file object directly in a worker.
      {data, errors} = Papa.parse e.target.result, header: true, dynamicTyping: true

      metadatas = for rawData in data
        cleanData = {}
        for key, value of rawData
          cleanData[key.trim()] = value?.trim?() ? value
        cleanData

      subjects = []
      for metadata in metadatas
        locations = @_findFilesInMetadata metadata
        unless locations.length is 0
          subjects.push {locations, metadata}

      @state.manifests[file.name] = {errors, subjects}
      @forceUpdate()

    reader.readAsText file

  _findFilesInMetadata: (metadata) ->
    filesInMetadata = []
    for key, value of metadata
      filesInValue = value.match? ///([^#{INVALID_FILENAME_CHARS.join ''}]+(?:#{VALID_SUBJECT_EXTENSIONS.join '|'}))///gi
      if filesInValue?
        filesInMetadata.push filesInValue...
    filesInMetadata

  handleRemoveManifest: (name) ->
    delete @state.manifests[name]
    @forceUpdate();

  createSubjects: ->
    allSubjects = []
    for name, {subjects} of @state.manifests
      {ready} = ManifestView.separateSubjects subjects, @state.files
      allSubjects.push ready...

    uploadAlert = (resolve) =>
      <SubjectUploader subjects={allSubjects} files={@state.files} project={@props.project} subjectSet={@props.subjectSet} autoStart onComplete={resolve} />

    startUploading = alert uploadAlert
      .then =>
        @setState
          manifests: {}
          files: {}

  deleteSubjectSet: ->
    @setState deletionError: null

    confirmed = confirm 'Really delete this subject set and all its subjects?'

    if confirmed
      @setState deletionInProgress: true

      this.props.subjectSet.delete()
        .then =>
          @props.project.uncacheLink 'subject_sets'
          @transitionTo 'edit-project-details', projectID: @props.project.id
        .catch (error) =>
          @setState deletionError: error
        .then =>
          if @isMounted()
            @setState deletionInProgress: false

module.exports = React.createClass
  displayName: 'EditSubjectSetPageWrapper'

  getDefaultProps: ->
    params: null

  render: ->
    <PromiseRenderer promise={apiClient.type('subject_sets').get @props.params.subjectSetID}>{(subjectSet) =>
      <ChangeListener target={subjectSet}>{=>
        <EditSubjectSetPage {...@props} subjectSet={subjectSet} />
      }</ChangeListener>
    }</PromiseRenderer>
