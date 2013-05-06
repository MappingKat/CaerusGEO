@Wizard = 
  AddExistingQuestions: (questions) ->
    for question in questions
      newQuestion = new Question(question);
      Questions.add([newQuestion]);
      q_to_pass = newQuestion.toJSON()
      q_to_pass.cid = newQuestion.cid
      #template and append
      html = _.template($("#base_template").html(),{question:q_to_pass});
      $(html).appendTo("#questions");

      #make active and show
      $("#"+newQuestion.cid).show();

      #/tie new model instance to templated dom object.
      newQuestion.set({obj:$("#"+newQuestion.cid)});
      $("#"+newQuestion.cid).find('select').val(question.form)
  SwapQuestionToType: (domref) ->
      model = Questions.get($(domref).closest('li').attr('id'))
      model.set({form:domref.val()})
  RepaintIndexLabels: ->
    $('.num').each (index,obj) =>
      $(obj).find('span').text((index+1))
  AddQuestion: (form) ->
    #prep new model instance & add to collection
    newQuestion = new Question({'form':form});
    Questions.add([newQuestion])
    q_to_pass = newQuestion.toJSON()
    q_to_pass.cid = newQuestion.cid

    #template and append
    html = _.template($("#base_template").html(),{question:newQuestion});
    $(html).appendTo("#questions");

    #make active and show
    $("#"+newQuestion.cid).addClass('active_question').show();

    #tie new model instance to templated dom object.
    newQuestion.set({obj:$("#"+newQuestion.cid)})
    Questions.trigger('add') #we trigger again, since LI is now available.
    #$("#"+newQuestion.cid).ScrollTo {duration: 1000, easing: 'linear'}
