#Keeps track of a character's position.
#
#Should probably be refactored some day soon.
module Position

  def initialize(*args)
    @positions = {}
    super
  end

  #Sits down, or on something if a target is given.
  #
  #Target should be a GameObject
  def sit(target = nil)
    if @positions[:sitting_on].nil?
      @positions[:standing_on] = nil
      @positions[:lying_on] = nil
      if target.nil?
        @positions[:sitting_on] = 'ground'
        @pose = 'sitting on the ground'
      else
        @positions[:sitting_on] = target.goid
        @pose = "sitting on #{target.name}"
      end
      true
    else
      false
    end
  end

  #Stands up or on something if a target is given
  def stand(target = nil)
    if prone? and target.nil?
      @positions[:sitting_on] = nil
      @positions[:lying_on] = nil
      @pose = nil
      true
    elsif not target.nil?
      @positions[:sitting_on] = nil
      @positions[:lying_on] = nil
      @positions[:standing_on] = target.goid
      @pose = "standing on #{target.name}"
      true
    else
      false
    end
  end

  #Lies down or on something if a target is given.
  def lie(target = nil)
    if not lying?
      @positions[:sitting_on] = nil
      @positions[:standing_on] = nil

      if target.nil?
        @positions[:lying_on] = 'ground'
        @pose = 'lying on the ground'
      else
        @positions[:lying_on] = target.goid
        @pose = "lying on #{target.name}"
      end
      true
    else
      false
    end
  end

  #Checks if the object is on another object.
  def on? target = nil
    if target.is_a? GameObject
      target = target.goid
    end

    if target.nil?
      prone?
    else
      @positions[:sitting_on] == target or @positions[:lying_on] == target or @positions[:standing_on] == target
    end
  end

  #True if the object is in a sitting position.
  def sitting?
    !!@positions[:sitting_on]
  end

  #True if the object is lying down.
  def lying?
    !!@positions[:lying_on]
  end

  #True if the object is sitting or lying down.
  def prone?
    !!(@positions[:sitting_on] or @positions[:lying_on])
  end

  #True if not prone.
  def can_move?
    not(@positions[:sitting_on] or @positions[:lying_on])
  end

  def sitting_on
    @positions[:sitting_on]
  end

  def lying_on
    @positions[:lying_on]
  end

  def pose
    @pose
  end

  def pose=(val)
    @pose = val
  end
end
