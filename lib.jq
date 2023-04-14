  def ampm:
    if .starttime[:2] | tonumber < 12
    then "morning"
    else "afternoon"
    end
  ;
