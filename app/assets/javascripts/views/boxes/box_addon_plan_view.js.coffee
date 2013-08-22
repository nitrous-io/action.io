AIO.BoxAddonPlanView = Em.View.extend
  templateName: 'templates/boxes/box_addon_plan'
  tagName: 'div'
  classNameBindings: ['selected']

  controller: null
  addonPlan: null
  addon: null
  boxBinding: 'controller.content'
  selected: false

  state: (->
    if @get 'selected'
      'Unselect'
    else
      'Select'
  ).property 'selected'

  select: ->
    if @get('selected') == false
      plan_id = @get('addonPlan.id')
      unless @get 'box.addon_plans'
        @set 'box.addon_plans', []
      plan_ids = @get 'box.addon_plans'
      # get the first plan since we only consider addon with 1 sandbox plan now
      plan_ids.push plan_id
      @set 'selected', true

  unselect: (event) ->
    plan_id = @get('addonPlan.id')
    if @get('selected')
      plans = @get('box.addon_plans')
      plans.splice plans.indexOf(plan_id), 1
      @set 'selected', false
