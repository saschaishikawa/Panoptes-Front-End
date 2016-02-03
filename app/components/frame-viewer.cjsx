React = require 'react'
LoadingIndicator = require '../components/loading-indicator'
getSubjectLocation = require '../lib/get-subject-location'

SUBJECT_STYLE = display: 'block'
NOOP = Function.prototype

# Generates a standard ref for a radio button, based on the subject and frame, to avoid conflicts with radios in other viewers on the page
generateRadioRef = (name, subject, frame) =>
  'subject'+subject.id+'_frame'+frame+'_'+name

module.exports = React.createClass
  displayName: 'FrameViewer'

  getDefaultProps: ->
    subject: null
    frame: 0
    onLoad: NOOP
    classification: null
    workflow: null
    frameWrapper: null
    onChange: ->

  getInitialState: ->
    loading: true
    playing: false
    playbackRate: 1
    frameDimensions: {}
    viewBoxDimensions: {
      x: 0,
      y: 0,
      width: 0
      height: 0
    }

  componentDidMount: ->
    @refs.videoScrubber?.value = 0

  componentDidUpdate: ->
    @refs.videoPlayer?.playbackRate = @state.playbackRate

  render: () ->
    subject = @props.subject
    frame = @props.frame
    {type, format, src} = getSubjectLocation @props.subject, @props.frame
    FrameWrapper = @props.frameWrapper
    frameDisplay = switch type
      when 'image'
        <div className="subject-image-frame">
          <img className="subject" src={src} style={SUBJECT_STYLE} onLoad={@handleLoad} />

          {if @state.loading
            <div className="loading-cover" style={@constructor.overlayStyle}>
              <LoadingIndicator />
            </div>}
          <span>
            <button className={ "fa fa-arrow-circle-left" + if @state.viewBoxDimensions.x == 0 then " disabled" else "" } onClick={ @panHorizontal.bind(this, .7) }> </button>
            <button className={ "fa fa-arrow-circle-up" + if @state.viewBoxDimensions.height == @state.frameDimensions.height then " disabled" else "" } onClick={@panVertical.bind(this, .7)}> </button>
            <button className={ "fa fa-arrow-circle-down" + if @state.viewBoxDimensions.width == @state.frameDimensions.width then " disabled" else ""} onClick={@panVertical.bind(this, 1.3)}> </button>
            <button className={ "fa fa-arrow-circle-right" + if @state.viewBoxDimensions.x == 0 then " disabled" else "" } onClick={@panHorizontal.bind(this, 1.3)}> </button>
            <button className="zoom-out fa fa-minus-circle" onClick={ @zoom.bind(this, 1.1 ) }></button>
            <button className="zoom-in fa fa-plus-circle" onClick={ @zoom.bind(this, .9) } ></button>
            <button className="reset" onClick={ this.zoomReset } >Reset</button>
          </span>
        </div>
      when 'video'
        <div className="subject-video-frame">
          <video ref="videoPlayer" src={src} type={"#{type}/#{format}"} preload="auto" onCanPlay={@handleLoad} onEnded={@endVideo} onTimeUpdate={@updateScrubber}>
            Your browser does not support the video format. Please upgrade your browser.
          </video>
          <span className="subject-video-controls">
            <span className="subject-frame-play-controls">
              {if @state.playing
                <button type="button" className="secret-button" aria-label="Pause" onClick={@playVideo.bind this, false}>
                  <i className="fa fa-pause fa-fw"></i>
                </button>
              else
                <button type="button" className="secret-button" aria-label="Play" onClick={@playVideo.bind this, true}>
                  <i className="fa fa-play fa-fw"></i>
                </button>}
            </span>
            <input type="range" className="video-scrubber" ref="videoScrubber" min="0" step="any" onChange={@seekVideo} />
            <span className="video-speed">
            Speed:
              {for rate, i in [0.25, 0.5, 1]
                ref = generateRadioRef 'rate', subject, frame
                <label key="rate-#{i}" className="secret-button">
                  <input type="radio" name={ref} ref={ref} value={rate} checked={rate == @state.playbackRate} onChange={@setPlayRate} />
                  <span>
                    {rate}&times;
                  </span>
                </label>
              }
            </span>
          </span>

          {if @state.loading
            <div className="loading-cover" style={@constructor.overlayStyle}>
              <LoadingIndicator />
            </div>}
        </div>

    if FrameWrapper
      <FrameWrapper frame={frame} naturalWidth={@state.frameDimensions?.width or 0} naturalHeight={@state.frameDimensions?.height or 0} viewBoxDimensions={@state.viewBoxDimensions or "0 0 0 0"} workflow={@props.workflow} subject={@props.subject} classification={@props.classification} annotation={@props.annotation} loading={@state.loading} onChange={@props.onChange}>
        {frameDisplay}
      </FrameWrapper>
    else
      frameDisplay

  setPlaying: ( playing) ->
    if playing
      @nextFrame()
      @_playingInterval = setInterval @nextFrame, @props.playFrameDuration

      autoStopDelay = @props.subject.locations.length * @props.playFrameDuration * @props.playIterations
      @_autoStop = setTimeout @setPlaying.bind(this, false), autoStopDelay
    else
      clearInterval @_playingInterval
      clearTimeout @_autoStop

  playVideo: (playing) ->
    player = @refs.videoPlayer
    return unless player?

    @setState
      playing: playing

    if playing
      player.play()
    else
      player.pause()

  setPlayRate: (e) ->
    @setState
      playbackRate: parseFloat e.target.value

  seekVideo: () ->
    player = @refs.videoPlayer
    scrubber = @refs.videoScrubber
    time = scrubber.value
    player.currentTime = time

  endVideo: () ->
    @setState
      playing: false

  updateScrubber: () ->
    player = @refs.videoPlayer
    scrubber = @refs.videoScrubber
    scrubber.setAttribute 'max', player.duration unless scrubber.getAttribute 'max'
    scrubber.value = player.currentTime

  handleLoad: (e) ->
    width = e.target.videoWidth ? e.target.naturalWidth
    height = e.target.videoHeight ? e.target.naturalHeight
    @setState
      loading: false
      frameDimensions:
        width: width ? 0
        height: height ? 0

      viewBoxDimensions:
        width: width ? 0
        height: height ? 0
        x: 0
        y: 0

    @props.onLoad? arguments...

  zoom: (change) ->
    newNaturalWidth = @state.viewBoxDimensions.width * change
    newNaturalHeight = @state.viewBoxDimensions.height * change
    
    newNaturalX = @state.viewBoxDimensions.x - (newNaturalWidth - @state.viewBoxDimensions.width)/2
    newNaturalY = @state.viewBoxDimensions.y - (newNaturalHeight - @state.viewBoxDimensions.height)/2
    
    @setState
      viewBoxDimensions:
        width: newNaturalWidth,
        height: newNaturalHeight,
        x: newNaturalX,
        y: newNaturalY

  zoomReset: ->
    @setState
      viewBoxDimensions:
        width: @state.frameDimensions.width, 
        height: @state.frameDimensions.height,
        x: 0,
        y: 0

  panHorizontal:(direction) ->
    @setState
      viewBoxDimensions:
        x: @state.viewBoxDimensions.x * direction
        y: @state.viewBoxDimensions.y
        width: @state.viewBoxDimensions.width
        height: @state.viewBoxDimensions.height

  panVertical:(direction)->
    @setState
      viewBoxDimensions:
        x: @state.viewBoxDimensions.x 
        y: @state.viewBoxDimensions.y * direction
        width: @state.viewBoxDimensions.width
        height: @state.viewBoxDimensions.height
