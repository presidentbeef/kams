#The Pronoun mixin provides the pronoun function, which gives the correct pronoun
#based on the sex of the object.
module Pronoun
  @@pronouns = { :normal =>
      { 'm' => 'he',
      'f' => 'she',
      'n' => 'it' },
    :possessive =>
      { 'm' => 'his',
      'f' => 'her',
      'n' => 'its' },
    :objective =>
      { 'm' => 'him',
      'f' => 'her',
      'n' => 'it' },
    :reflexive =>
      { 'm' => 'himself',
      'f' => 'herself',
      'n' => 'itself' },
    :obj_poss =>
      { 'm' => 'his',
      'f' => 'hers',
      'n' => 'its' }
    }

  #This is the only function of the Pronoun mixin. It returns the correct pronoun
  #based on the sex of the object.
  #Type is the type of pronoun desired.
  #
  # :normal for 'he', 'she', 'it'
  #
  # :possessive for 'his', 'her', 'its'
  #
  # :objective for 'him', 'her', 'it'
  #
  # :obj_poss for 'his', 'hers', 'its'
  #
  # :reflexive for 'himself', 'herself', 'itself'
  def pronoun(type = :normal)
    if @@pronouns[type]
      if @@pronouns[type][@sex].nil?
        log "What the heck."
      else
        return @@pronouns[type][@sex]
      end
    else
      log "No such thing: #{type}"
    end
    ''
  end
end
