# TODO potential Editor section to edit text box

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



# Save Worflow button from original Selection Task

onClickSaveWorkflow: (e) ->
  if window.confirm('Are you sure that you would like to save these changes?')
    @props.workflow.save()

<button type="button" onClick={@onClickSaveWorkflow}><i className="fa fa-save" /> Save Workflow</button>}
<hr/>
